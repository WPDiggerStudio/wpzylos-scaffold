# Contributing to WPZylos

Thank you for considering contributing to WPZylos! This document outlines the process for contributing to this package.

## Prerequisites

- **PHP** >= 8.0
- **Composer** >= 2.0

## Development Setup

```bash
git clone https://github.com/WPDiggerStudio/{package-name}.git
cd {package-name}
composer install
```

## Running Checks

This package uses the following quality tools:

```bash
# Run all quality checks
composer qa

# Run tests
composer test

# Run static analysis (PHPStan)
composer analyze

# Check coding standards (PSR-12)
composer cs

# Fix coding standards automatically
composer cs-fix
```

## Testing Requirements

- All new features must include tests
- All bug fixes should include a regression test
- **Tests must pass on PHP 8.0** (baseline)
- Tests should also pass on PHP 8.1, 8.2, and 8.3 when possible

## Coding Standards

- Follow PSR-12 coding style
- Use strict types: `declare(strict_types=1);`
- Add PHPDoc blocks to all public methods
- Keep methods focused and small

## Pull Request Guidelines

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes with clear, atomic commits
4. Add or update tests for your changes
5. Ensure all checks pass: `composer qa`
6. Push and open a Pull Request

### PR Best Practices

- Keep PRs small and focused on a single change
- Write a clear description explaining what and why
- Reference any related issues
- Update documentation if behavior changes

## Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, open a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - PHP and WordPress versions

## Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the feature and its use case
3. Explain why it would benefit the package

## Security Vulnerabilities

**Do NOT report security vulnerabilities via GitHub issues.**

Please see [SECURITY.md](SECURITY.md) for responsible disclosure instructions.

## Code of Conduct

Please be respectful and constructive in all interactions. We welcome contributors of all backgrounds and experience levels.

## Questions?

Open an issue with the `question` label.
