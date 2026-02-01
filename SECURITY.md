# Security Policy

## Reporting Security Vulnerabilities

**Do NOT open a public GitHub issue for security vulnerabilities.**

Please report security issues by emailing: **diggerwp@gmail.com**

Include as much detail as possible:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- **Acknowledgment**: Within 72 hours of receiving your report
- **Status Update**: Within 7 days with our assessment and planned timeline
- **Resolution**: We aim to release a fix within 30 days for critical issues

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

We support the latest tagged release and the current `main` branch.

## Scope

Security issues we are interested in include, but are not limited to:

- **Command Injection**: Unsafe execution of shell commands
- **Path Traversal**: Unauthorized file system access
- **Unsafe File Writes**: Writing to unintended locations
- **SQL Injection**: Improper database query handling
- **Cross-Site Scripting (XSS)**: Unescaped output in WordPress admin
- **Authentication/Authorization Bypass**: Privilege escalation
- **Dependency Vulnerabilities**: Known CVEs in dependencies

## Coordinated Disclosure

We follow a coordinated disclosure process:

1. You report the vulnerability privately to us
2. We acknowledge receipt and begin investigation
3. We work on a fix and coordinate a release timeline with you
4. Once a fix is released, you may disclose the vulnerability publicly
5. We will credit you in the release notes (unless you prefer anonymity)

We kindly ask that you:

- Give us reasonable time to address the issue before public disclosure
- Avoid exploiting the vulnerability beyond what is necessary to demonstrate it
- Not access or modify other users' data

## Security Best Practices

When using WPZylos packages:

1. Always validate and sanitize user input
2. Use prepared statements for all database operations
3. Verify nonces for form submissions and AJAX requests
4. Check user capabilities before privileged operations
5. Keep all packages updated to the latest versions

## Recognition

We appreciate security researchers who help keep WPZylos secure. Contributors who report valid security issues will be acknowledged in our release notes.
