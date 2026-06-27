# AGENTS.md

Language: [简体中文](AGENTS.zh-CN.md)

## Documentation

* [README](README.en.md)
* [Vision](VISION.md)
* [Roadmap](ROADMAP.md)
* [Architecture](ARCHITECTURE.md)
* **AI Development Guide**
* [Contributing](CONTRIBUTING.md)

---

# SF6CC AI Development Guide

This document defines how AI coding assistants should work in this repository.

It applies to Codex, Claude Code, Gemini CLI, Cursor, Windsurf and any future AI development tools.

---

# Project Overview

SF6CC is a community-enhanced fork of WTT (SF6 Tools).

The project focuses on improving the Street Fighter 6 training experience while remaining compatible with the upstream project whenever practical.

The long-term goals are:

* Better UI/UX
* Better localization
* Better combo training
* Better learning experience
* Better community integration
* Clean architecture
* Long-term maintainability

This repository contains the Lua framework only.

SF6CM (Community Manager) is a separate project.

The Lua project and SF6CM communicate only through JSON data.

There must be no direct dependency between them.

---

# Repository Philosophy

This repository represents the REFramework folder contents.

Everything inside this repository should be installable into the game's REFramework directory.

Release packages are generated from this repository.

Do not treat this repository as an application project.

It is a framework + data project.

---

# Working Rules

Always work inside this repository.

Do not assume sibling directories exist.

Do not modify external projects unless explicitly requested.

Temporary Git worktrees may exist.

Only use temporary worktrees when specifically instructed.

Normal development always happens on the main development branch.

---

# Git Workflow

Default development branch:

master

Temporary branches:

feature/*
bugfix/*
refactor/*
release/*
review/*
import/*

origin = personal fork

upstream = Wael3rd/SF6_Tools

Never push directly to upstream.

---

# Development Priorities

When making decisions, follow this priority order:

1. Maintainability
2. Clean architecture
3. User experience
4. Localization
5. Upstream compatibility
6. Performance
7. New features

Never sacrifice maintainability for short-term convenience.

---

# Architecture Principles

Prefer modular design.

Avoid duplicated code.

Prefer reusable utility functions.

Prefer data-driven logic over hardcoded behavior.

Separate:

* UI
* Logic
* Data
* Runtime state

Avoid coupling unrelated systems.

---

# Configuration Philosophy

Not every Config file is user configuration.

Many Config files define product defaults.

Examples include:

* default fonts
* default UI
* default layouts
* default colors
* default enabled modules
* default training behavior

These files are part of the product.

Do not remove or ignore Config files simply because they contain "Config".

Evaluate their purpose first.

---

# Runtime Files

Runtime-generated files must never be committed.

Examples:

* WebState
* WebBridge
* TrayState
* heartbeat
* LastFail.json
* sync_signal.json
* replay slot data
* temporary cache
* generated logs

These should be generated locally.

---

# Release Artifacts

Do not commit:

* release packages
* runtime folders
* ZIP files
* temporary build output

Publish releases using GitHub Releases or external storage.

---

# Research Data

Large research dumps are not source code.

Do not commit:

* dump files
* extracted game data
* temporary analysis files

If required, store them outside the repository.

---

# Combo Data

Combo JSON files are product assets.

Exception databases are product assets.

Character data is product data.

These should be version controlled.

---

# Localization

Localization should always support multiple languages.

Avoid hardcoded text.

Prefer language resources whenever practical.

UI changes for different regions are acceptable if they improve usability.

---

# Community

SF6CM is an independent project.

This repository should not directly depend on:

* website
* database
* backend services

Only shared JSON specifications should be considered common interfaces.

---

# AI Expectations

Before making large changes:

Explain the architecture impact.

Before deleting files:

Determine whether they are:

* source
* product defaults
* runtime
* generated
* release artifacts

Never assume deletion is correct.

Before committing:

Verify that runtime files are excluded.

Verify that release artifacts are excluded.

Verify that product defaults remain intact.

---

# Long-Term Vision

The ecosystem consists of three independent layers:

WTT Core

↓

SF6CC

↓

SF6CM

WTT provides the shared training framework.

SF6CC enhances the user experience and localization.

SF6CM provides community features and online content.

Each layer should remain as independent as possible while sharing common data formats.

The goal is to build a sustainable, maintainable, community-driven project that can continue evolving for many years.
