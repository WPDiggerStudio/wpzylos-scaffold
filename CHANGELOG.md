# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.1.0 - 2026-02-04

### 🚀 WPZylos Scaffold v1.1.0

Introducing a unified **Scaffold CLI** that streamlines plugin initialization and production builds.

### ✨ New Features

#### Unified Scaffold CLI

- New `scaffold.ps1` (Windows) and `scaffold` (Linux/Mac) entry point
- Interactive menu to choose between init and build actions
- Direct commands: `./scaffold init` or `./scaffold build`

#### Integrated QA Pipeline

- Automatic **phpcbf** (PSR-12) code style fixes before build
- Automatic **phpstan** static analysis before build
- Skip with `--skip-qa` flag when needed

#### Shared Configuration

- New `.plugin-config.json` stores plugin settings after initialization
- Build script reads config for versioned ZIP creation
- No more manual configuration between init and build

### ✨ Intelligent Init Script

- **Smart state detection**: Handles fresh install, re-configuration, and deleted config scenarios
- **Namespace normalization**: Accepts single, double, or triple backslashes - all work correctly
- **Partial updates**: Only replaces changed values, shows "Skipped" for unchanged fields
- **Proper backslash handling**: Fixed sed escape issues for namespaces like `KYNetCode\WPBraCalculator`
- **Smart Plugin URI**: Auto-derives Plugin URI from Author URI + plugin slug

### 📖 Documentation Improvements

- Added **Command Prompt** instructions for Windows users
- Improved CLI documentation with clear Option 1/2/3 format
- Added Git Bash alternative syntax: `bash scaffold`
- Link to Git for Windows download

### 🔧 Build Improvements

- `phpstan.neon` now tracked directly (not .dist) for streamlined builds
- PHPStan configuration includes WordPress stubs out of the box

### 🔄 CI/CD

- Packagist auto-update workflow with dynamic repository URL
- Fixed workflow triggers and authentication

### 🐛 Bug Fixes

- Fixed `unterminated 's' command` error when namespace contains backslash
- Fixed terminal escape codes corrupting namespace input
- Fixed namespace not saving correctly to `.plugin-config.json`
- Fixed JSON namespace escaping: Namespaces now use double backslash in `composer.json`

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
