# ARCHITECTURE.md

Language: [简体中文](ARCHITECTURE.zh-CN.md)

## Documentation

* [README](README.en.md)
* [Vision](VISION.md)
* [Roadmap](ROADMAP.md)
* **Architecture**
* [AI Development Guide](AGENTS.md)
* [Contributing](CONTRIBUTING.md)

---

# SF6CC Architecture

## Purpose

This document explains the architecture of SF6CC.

It describes why the project is structured this way and how new features should be integrated.

This document is intended for both human contributors and AI coding assistants.

---

# High Level Overview

The ecosystem consists of three independent layers:

```
Street Fighter 6
        │
        ▼
 REFramework
        │
        ▼
     SF6CC
        │
        ▼
     SF6CM
```

Each layer has a different responsibility.

---

# WTT Core

WTT provides the base training framework.

Examples include:

* Drawing
* Game hooks
* Basic UI
* Script loading

Whenever possible, improvements that benefit every user should remain compatible with WTT.

---

# SF6CC

SF6CC extends WTT with improvements designed for a better training experience.

Typical additions include:

* UI improvements
* Localization
* Better layouts
* Better fonts
* Better combo training
* Better user experience
* Community-oriented workflow

SF6CC should remain modular.

Avoid coupling unrelated systems.

---

# SF6CM

SF6CM is NOT part of this repository.

Responsibilities include:

* Combo sharing
* Community
* Metadata
* Ratings
* Search
* Downloads
* User content

Communication between SF6CC and SF6CM happens only through JSON.

No Lua code should directly depend on the website.

---

# Repository Layout

```
autorun/
    Lua entry scripts

autorun/func/
    Shared modules

data/
    Product data
    Config
    Combo database
    Exception database

fonts/
    UI fonts

images/
    Icons
    UI assets

plugins/
    REFramework plugins

docs/
    Documentation
```

---

# Architectural Layers

## 1. UI Layer

Responsible for:

* windows
* menus
* drawing
* interaction

UI should never contain gameplay logic.

---

## 2. Logic Layer

Responsible for:

* combo parsing
* training logic
* validation
* calculations

Logic should remain reusable.

---

## 3. Data Layer

Contains:

* Combo JSON
* Character data
* Exception rules
* Product default configuration

No runtime state belongs here.

---

## 4. Runtime Layer

Generated locally.

Examples:

* WebState
* WebBridge
* Replay Data
* LastFail
* sync_signal

Runtime files must never be committed.

---

# Config Philosophy

There are two kinds of Config.

## Product Config

Defines:

* default UI
* default colors
* default fonts
* default layout
* default enabled modules

These are version controlled.

---

## Runtime Config

Generated automatically.

Examples:

* window positions
* session state
* temporary cache

These should not be committed.

---

# Data Driven Design

Whenever possible:

Lua should describe behaviour.

JSON should describe content.

Avoid hardcoding character-specific logic.

Prefer configuration over branching.

---

# Modularity

Every module should have a single responsibility.

Examples:

TrainingComboTrials

↓

Only combo training.

DistanceViewer

↓

Only distance analysis.

TrainingHitConfirm

↓

Only hit confirm training.

Avoid hidden dependencies.

---

# Upstream Compatibility

Whenever practical:

Improvements should remain mergeable into WTT.

Large architectural changes should be documented before implementation.

Compatibility is preferred over unnecessary divergence.

---

# Long-Term Vision

```
          WTT
           │
           ▼
         SF6CC
           │
           ▼
         SF6CM
```

WTT provides the core framework.

SF6CC provides a better user experience.

SF6CM provides the community ecosystem.

Each project should remain independent while sharing common data formats.

This architecture enables long-term maintenance, collaboration, and future expansion.
