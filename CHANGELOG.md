# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.1.0 - 2026-02-04

### 🚀 WPZylos Scaffold v1.1.0

Introducing a unified **Scaffold CLI** that streamlines plugin initialization and production builds.

#### ✨ New Features

##### Unified Scaffold CLI

- New [scaffold.ps1](cci:7://file:///d:/laragon/www/wpzylos/wpzylos-scaffold/scaffold.ps1:0:0-0:0) (Windows) and [scaffold](cci:7://file:///d:/laragon/www/wpzylos/wpzylos-scaffold/scaffold:0:0-0:0) (Linux/Mac) entry point
- Interactive menu to choose between [init](cci:1://file:///d:/laragon/www/wpzylos/wpzylos-scaffold/scaffold:74:0-82:1) and [build](cci:1://file:///d:/laragon/www/wpzylos/wpzylos-scaffold/scaffold:84:0-92:1) actions
- Direct commands: `./scaffold init` or `./scaffold build`

##### Integrated QA Pipeline

- Automatic **phpcbf** (PSR-12) code style fixes before build
- Automatic **phpstan** static analysis before build
- Skip with `--skip-qa` flag when needed

##### Shared Configuration

- New `.plugin-config.json` stores plugin settings after initialization
- Build script reads config for versioned ZIP creation
- No more manual configuration between init and build

#### 📁 New Project Structure

**Full Changelog**: https://github.com/WPDiggerStudio/wpzylos-scaffold/compare/v1.0.0...v1.1.0

## v1.0.0 - 2026-02-01

First stable release of wpzylos-scaffold

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security
