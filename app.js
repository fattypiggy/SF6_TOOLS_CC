const REQUIRED_EXE = "StreetFighter6.exe";
const REFRAMEWORK_DIR = "reframework";
const WTT_FILE = ["reframework", "autorun", "Training_ScriptManager.lua"];
const CUSTOM_COMBOS_PATH = [
  "reframework",
  "data",
  "TrainingComboTrials_data",
  "CustomCombos"
];

const state = {
  rootHandle: null,
  manifest: [],
  localTrials: []
};

const els = {
  selectRootBtn: document.getElementById("selectRootBtn"),
  reloadManifestBtn: document.getElementById("reloadManifestBtn"),
  rescanBtn: document.getElementById("rescanBtn"),
  sf6Status: document.getElementById("sf6Status"),
  reframeworkStatus: document.getElementById("reframeworkStatus"),
  wttStatus: document.getElementById("wttStatus"),
  manifestError: document.getElementById("manifestError"),
  manifestTableBody: document.getElementById("manifestTableBody"),
  localTableBody: document.getElementById("localTableBody")
};

els.selectRootBtn.addEventListener("click", selectSf6Root);
els.reloadManifestBtn.addEventListener("click", loadManifest);
els.rescanBtn.addEventListener("click", scanLocalTrials);

loadManifest();

async function selectSf6Root() {
  if (!window.showDirectoryPicker) {
    setStatus(els.sf6Status, "当前浏览器不支持 File System Access API");
    return;
  }

  try {
    state.rootHandle = await window.showDirectoryPicker({ mode: "readwrite" });
    await detectInstall();
  } catch (error) {
    if (error.name !== "AbortError") {
      setStatus(els.sf6Status, `选择目录失败：${error.message}`);
    }
  }
}

async function detectInstall() {
  const sf6Detected = await fileExists(state.rootHandle, [REQUIRED_EXE]);
  setStatus(els.sf6Status, sf6Detected ? "已检测到 Street Fighter 6" : "未检测到街霸6目录");

  const reframeworkDetected = await directoryExists(state.rootHandle, [REFRAMEWORK_DIR]);
  setStatus(els.reframeworkStatus, reframeworkDetected ? "REFramework 已安装" : "REFramework 未安装");

  const wttDetected = await fileExists(state.rootHandle, WTT_FILE);
  setStatus(els.wttStatus, wttDetected ? "WTT 已安装" : "WTT 未安装");

  els.rescanBtn.disabled = !sf6Detected;
  if (sf6Detected) {
    await scanLocalTrials();
  } else {
    state.localTrials = [];
    renderLocalTrials();
    renderManifest();
  }
}

async function loadManifest() {
  els.manifestError.hidden = true;
  setTableLoading(els.manifestTableBody, 5, "正在加载 manifest.json");

  try {
    const response = await fetch("manifest.json", { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    state.manifest = await response.json();
    renderManifest();
  } catch (error) {
    state.manifest = [];
    els.manifestError.textContent = `Manifest 加载失败：${error.message}`;
    els.manifestError.hidden = false;
    setTableLoading(els.manifestTableBody, 5, "Manifest 未加载");
  }
}

async function scanLocalTrials() {
  if (!state.rootHandle) {
    return;
  }

  try {
    const customCombosHandle = await getDirectoryHandleByPath(state.rootHandle, CUSTOM_COMBOS_PATH, false);
    if (!customCombosHandle) {
      state.localTrials = [];
      renderLocalTrials();
      renderManifest();
      return;
    }

    state.localTrials = [];
    await collectJsonFiles(customCombosHandle, [], state.localTrials);
    state.localTrials.sort((a, b) => a.character.localeCompare(b.character) || a.fileName.localeCompare(b.fileName));
    renderLocalTrials();
    renderManifest();
  } catch (error) {
    setTableLoading(els.localTableBody, 3, `扫描失败：${error.message}`);
  }
}

async function installTrial(item) {
  if (!state.rootHandle) {
    alert("请先选择 Street Fighter 6 根目录");
    return;
  }

  try {
    const response = await fetch(item.file, { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`下载失败 HTTP ${response.status}`);
    }
    const trialText = await response.text();
    JSON.parse(trialText);

    const characterDir = await getDirectoryHandleByPath(
      state.rootHandle,
      [...CUSTOM_COMBOS_PATH, item.character],
      true
    );
    const fileName = fileNameFromPath(item.file);
    const fileHandle = await characterDir.getFileHandle(fileName, { create: true });
    const writable = await fileHandle.createWritable();
    await writable.write(trialText);
    await writable.close();
    await scanLocalTrials();
  } catch (error) {
    alert(`安装失败：${error.message}`);
  }
}

async function uninstallTrial(item) {
  if (!state.rootHandle) {
    alert("请先选择 Street Fighter 6 根目录");
    return;
  }

  try {
    const fileName = fileNameFromPath(item.file);
    const local = state.localTrials.find((trial) => {
      return trial.character === item.character && trial.fileName === fileName;
    }) || state.localTrials.find((trial) => trial.fileName === fileName);
    if (!local) {
      await scanLocalTrials();
      return;
    }

    const parentPath = [...CUSTOM_COMBOS_PATH, ...local.relativeParts.slice(0, -1)];
    const parentHandle = await getDirectoryHandleByPath(state.rootHandle, parentPath, false);
    if (parentHandle) {
      await parentHandle.removeEntry(fileName);
    }
    await scanLocalTrials();
  } catch (error) {
    alert(`删除失败：${error.message}`);
  }
}

async function collectJsonFiles(directoryHandle, relativeParts, output) {
  for await (const [name, handle] of directoryHandle.entries()) {
    if (handle.kind === "directory") {
      await collectJsonFiles(handle, [...relativeParts, name], output);
      continue;
    }

    if (handle.kind === "file" && name.toLowerCase().endsWith(".json")) {
      const parts = [...relativeParts, name];
      output.push({
        character: relativeParts[0] || "Unknown",
        fileName: name,
        relativePath: ["CustomCombos", ...parts].join("/"),
        relativeParts: parts
      });
    }
  }
}

function renderManifest() {
  if (!state.manifest.length) {
    setTableLoading(els.manifestTableBody, 5, "Manifest 为空");
    return;
  }

  els.manifestTableBody.replaceChildren(...state.manifest.map((item) => {
    const fileName = fileNameFromPath(item.file);
    const installed = state.localTrials.some((trial) => trial.fileName === fileName);
    const row = document.createElement("tr");
    row.append(
      cell(item.character),
      cell(item.name),
      cell(fileName),
      statusCell(installed ? "已安装" : "未安装", installed ? "ok" : "missing"),
      actionCell(item, installed)
    );
    return row;
  }));
}

function renderLocalTrials() {
  if (!state.localTrials.length) {
    setTableLoading(els.localTableBody, 3, "未发现本地 Trial JSON");
    return;
  }

  els.localTableBody.replaceChildren(...state.localTrials.map((trial) => {
    const row = document.createElement("tr");
    row.append(
      cell(trial.character),
      cell(trial.fileName),
      statusCell("本地存在", "ok")
    );
    row.title = trial.relativePath;
    return row;
  }));
}

function actionCell(item, installed) {
  const td = document.createElement("td");
  const wrap = document.createElement("div");
  wrap.className = "row-actions";
  const button = document.createElement("button");
  button.type = "button";
  button.textContent = installed ? "删除" : "安装";
  if (installed) {
    button.className = "danger";
    button.addEventListener("click", () => uninstallTrial(item));
  } else {
    button.addEventListener("click", () => installTrial(item));
  }
  wrap.append(button);
  td.append(wrap);
  return td;
}

function statusCell(text, type) {
  const td = document.createElement("td");
  const badge = document.createElement("span");
  badge.className = `badge ${type}`;
  badge.textContent = text;
  td.append(badge);
  return td;
}

function cell(text) {
  const td = document.createElement("td");
  td.textContent = text;
  return td;
}

function setStatus(element, text) {
  element.textContent = text;
}

function setTableLoading(tbody, colspan, text) {
  const row = document.createElement("tr");
  const td = document.createElement("td");
  td.colSpan = colspan;
  td.className = "empty";
  td.textContent = text;
  row.append(td);
  tbody.replaceChildren(row);
}

async function fileExists(rootHandle, pathParts) {
  const fileName = pathParts[pathParts.length - 1];
  const parent = await getDirectoryHandleByPath(rootHandle, pathParts.slice(0, -1), false);
  if (!parent) {
    return false;
  }

  try {
    await parent.getFileHandle(fileName);
    return true;
  } catch (error) {
    return false;
  }
}

async function directoryExists(rootHandle, pathParts) {
  return Boolean(await getDirectoryHandleByPath(rootHandle, pathParts, false));
}

async function getDirectoryHandleByPath(rootHandle, pathParts, create) {
  let current = rootHandle;
  for (const part of pathParts) {
    try {
      current = await current.getDirectoryHandle(part, { create });
    } catch (error) {
      return null;
    }
  }
  return current;
}

function fileNameFromPath(path) {
  return path.split("/").pop();
}
