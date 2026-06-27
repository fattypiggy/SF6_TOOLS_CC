# CONTRIBUTING.md

Language: [简体中文](CONTRIBUTING.zh-CN.md)

## Documentation

* [README](README.en.md)
* [Vision](VISION.md)
* [Roadmap](ROADMAP.md)
* [Architecture](ARCHITECTURE.md)
* [AI Development Guide](AGENTS.md)
* **Contributing**

---

# Contributing to SF6CC

Thank you for your interest in contributing to SF6CC.

SF6CC is a community-driven enhancement of WTT (SF6 Tools). Our goal is to improve the Street Fighter 6 training experience while maintaining a clean architecture and remaining compatible with upstream whenever practical.

---

# Before You Start

Please read the following documents first:

* [README](README.en.md)
* [AI Development Guide](AGENTS.md)
* [Architecture](ARCHITECTURE.md)

These documents describe the project's philosophy, architecture, and development guidelines.

---

# Development Philosophy

When contributing, please follow these principles:

* Prefer maintainable solutions.
* Prefer modular designs.
* Avoid unnecessary complexity.
* Keep unrelated changes in separate commits.
* Preserve compatibility with upstream whenever practical.

Not every improvement needs to be merged into WTT, but changes that benefit all users should remain mergeable.

---

# Repository Structure

Typical project areas include:

* Lua modules
* Training logic
* UI
* Localization
* Combo data
* Documentation

Please keep changes focused on a single area whenever possible.

---

# Branch Naming

Recommended branch names:

feature/<name>

bugfix/<name>

refactor/<name>

docs/<name>

review/<name>

---

# Commit Messages

Use concise, descriptive commit messages.

Examples:

Add localization framework

Improve combo parser

Refactor TrainingComboTrials

Update Akuma combo database

Fix UI scaling issue

---

# Pull Requests

Before opening a Pull Request:

* Explain why the change is needed.
* Describe the implementation.
* Mention compatibility impacts.
* Include screenshots for UI changes when appropriate.

Large architectural changes should be discussed before implementation.

---

# Configuration Files

Please do not assume every Config file is user configuration.

Many Config files define product defaults such as:

* fonts
* layouts
* colors
* enabled modules

Only runtime-generated files should be excluded from version control.

---

# Runtime Files

Never commit runtime-generated files.

Examples include:

* WebState
* WebBridge
* LastFail.json
* sync_signal.json
* Replay data
* Cache
* Logs

---

# Release Files

Do not commit:

* ZIP packages
* release output
* runtime folders
* temporary build artifacts

Use GitHub Releases for distribution.

---

# Community Contributions

Contributions are welcome in many forms:

* Lua improvements
* UI/UX
* Localization
* Combo data
* Documentation
* Bug reports
* Performance improvements

Constructive discussions are always appreciated.

---

# Thank You

Thank you for helping make SF6CC better for the Street Fighter community.


AI-generated contributions are welcome, but contributors are responsible for reviewing and testing all generated code before submission.
