# WPZylos Scaffold

[![PHP Version](https://img.shields.io/badge/php-%5E8.0-blue)](https://php.net)
[![WordPress](https://img.shields.io/badge/wordpress-6.0%2B-blue)](https://wordpress.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-WPDiggerStudio-181717?logo=github)](https://github.com/WPDiggerStudio/wpzylos-scaffold)

Template repository for creating **production-ready WordPress plugins** with MVC architecture and PHP-Scoper namespace isolation.

📖 **[Full Documentation](https://wpzylos.com)** | 🐛 **[Report Issues](https://github.com/WPDiggerStudio/wpzylos-scaffold/issues)**

---

## ✨ Features

- **Complete MVC Structure** — Controllers, Services, Views, Routes
- **PSR-4 Autoloading** — Modern PHP namespace organization
- **PHP-Scoper Ready** — Pre-configured namespace isolation for multi-plugin compatibility
- **Service Providers** — Modular dependency injection
- **Database Migrations** — Version-controlled schema changes
- **WordPress Compliant** — Proper headers, MIT license, readme.txt
- **Build Pipeline** — Scaffold CLI with QA checks and ZIP creation
- **Security First** — Nonce verification, capability checks, input sanitization

---

## 📋 Requirements

| Requirement | Version  |
| ----------- | -------- |
| PHP         | ^8.0     |
| WordPress   | 6.0+     |
| Composer    | 2.0+     |
| WP-CLI      | Optional |

---

## 🚀 Quick Start

### Option 1: Use as GitHub Template

Click **"Use this template"** on GitHub to create a new repository.

### Option 2: Composer Create Project

```bash
cd /path/to/wordpress/wp-content/plugins
composer create-project wpdiggerstudio/wpzylos-scaffold your-plugin-name
cd your-plugin-name
```

### Option 3: Clone and Customize

```bash
git clone https://github.com/WPDiggerStudio/wpzylos-scaffold.git your-plugin-name
cd your-plugin-name
rm -rf .git
composer install
```

### Initialize Your Plugin (Recommended)

After creating your project, run the **Scaffold CLI** to customize and manage your plugin.

#### Option 1: PowerShell (Windows 10/11)

Open **Windows PowerShell** (search "PowerShell" in Start menu):

```powershell
.\scaffold.ps1           # Interactive menu
.\scaffold.ps1 init      # Initialize plugin directly
.\scaffold.ps1 build     # Build for production directly
```

#### Option 2: Command Prompt (Windows)

Open **Command Prompt** (cmd.exe). Since `.ps1` files don't run directly in cmd, use:

```cmd
powershell -ExecutionPolicy Bypass -File scaffold.ps1
powershell -ExecutionPolicy Bypass -File scaffold.ps1 init
powershell -ExecutionPolicy Bypass -File scaffold.ps1 build
```

#### Option 3: Bash (Linux/Mac/Git Bash)

For **Linux**, **macOS**, or **Git Bash on Windows** (install [Git for Windows](https://git-scm.com/download/win)):

```bash
chmod +x scaffold.sh     # Make executable (first time only)
./scaffold.sh            # Interactive menu
./scaffold.sh init       # Initialize plugin directly
./scaffold.sh build      # Build for production directly
```

> **Git Bash alternative:** If `./scaffold.sh` doesn't work, try `bash scaffold.sh`

---

The **intelligent init script** handles all scenarios:

| Scenario           | Behavior                                                      |
| ------------------ | ------------------------------------------------------------- |
| **Fresh install**  | Detects `my-plugin.php`, uses scaffold defaults               |
| **Re-configure**   | Loads `.plugin-config.json`, shows current values as defaults |
| **Config deleted** | Auto-detects plugin from `*.php` with "Plugin Name:" header   |
| **Partial update** | Only changes modified values, shows "Skipped" for unchanged   |

**Namespace support:** Supports nested namespaces like `WPDigger\WPBraCalculator` or `KYNetCode\WP\Bra\Calculator`.

---

## 📁 Project Structure

```
your-plugin/
├── app/                        # Application code (PSR-4: YourPlugin\)
│   ├── Core/
│   │   └── PluginContext.php   # Plugin identity (slug, prefix, text domain)
│   ├── Lifecycle/
│   │   ├── Activator.php       # Activation logic
│   │   ├── Deactivator.php     # Deactivation logic
│   │   └── Uninstaller.php     # Uninstall cleanup
│   └── Support/
│       └── helpers.php         # Global helper functions
├── bootstrap/
│   └── app.php                 # Application bootstrap & service providers
├── config/
│   └── app.php                 # Application configuration
├── database/
│   └── migrations/             # Database migrations
├── resources/
│   ├── lang/                   # Translation files
│   └── views/                  # PHP view templates
├── routes/
│   └── web.php                 # Route definitions
├── tests/
│   └── Unit/                   # PHPUnit tests
├── scaffold.ps1                # Scaffold CLI (Windows)
├── scaffold.sh                 # Scaffold CLI (Linux/Mac)
├── .scripts/                   # CLI scripts
│   ├── init-plugin.ps1/.sh     # Initialization logic
│   └── build.ps1/.sh           # Build pipeline logic
├── your-plugin.php             # Main plugin entry point
├── uninstall.php               # WordPress uninstall handler
├── scoper.inc.php              # PHP-Scoper configuration
├── composer.json               # Dependencies
└── readme.txt                  # WordPress.org readme
```

---

## 🔧 Customization

### Automated (Recommended)

Run the Scaffold CLI for automated setup:

**PowerShell:**

```powershell
.\scaffold.ps1 init
```

**Command Prompt:**

```cmd
powershell -ExecutionPolicy Bypass -File scaffold.ps1 init
```

**Linux/Mac/Git Bash:**

```bash
./scaffold.sh init
```

### Manual

If you prefer manual customization, perform search and replace:

| Find        | Replace With  | Description                            |
| ----------- | ------------- | -------------------------------------- |
| `my-plugin` | `your-plugin` | Plugin slug (lowercase, hyphenated)    |
| `my_plugin` | `your_plugin` | Scoper prefix (lowercase, underscored) |
| `MyPlugin`  | `YourPlugin`  | PHP namespace (PascalCase)             |
| `myplugin_` | `yourplugin_` | Database/option prefix                 |
| `My Plugin` | `Your Plugin` | Display name                           |

#### Files to Update

1. **`your-plugin.php`** — Plugin headers, PluginContext configuration
2. **`composer.json`** — Package name, namespace in autoload
3. **`scoper.inc.php`** — Scoper prefix variable
4. **`.plugin-config.json`** — Created by init, used by build
5. **`uninstall.php`** — Context configuration

---

## 🏗️ Core Components

### PluginContext

The `PluginContext` class (`app/Core/PluginContext.php`) is the **single source of truth** for plugin identity. All framework components use this for prefixing.

```php
$context = PluginContext::create([
    'file'       => __FILE__,
    'slug'       => 'your-plugin',
    'prefix'     => 'yourplugin_',
    'textDomain' => 'your-plugin',
    'version'    => '1.0.0',
]);
```

**Available Methods:**

| Method                 | Returns                | Example                                            |
| ---------------------- | ---------------------- | -------------------------------------------------- |
| `slug()`               | Plugin slug            | `your-plugin`                                      |
| `prefix()`             | Database prefix        | `yourplugin_`                                      |
| `textDomain()`         | Translation domain     | `your-plugin`                                      |
| `version()`            | Plugin version         | `1.0.0`                                            |
| `file()`               | Main plugin file path  | `/path/to/your-plugin.php`                         |
| `path($relative)`      | Absolute path          | `/path/to/your-plugin/config/`                     |
| `url($relative)`       | Plugin URL             | `https://site.com/wp-content/plugins/your-plugin/` |
| `hook($name)`          | Prefixed hook name     | `yourplugin_custom_hook`                           |
| `optionKey($key)`      | Prefixed option key    | `yourplugin_settings`                              |
| `transientKey($key)`   | Prefixed transient key | `yourplugin_cache`                                 |
| `cronHook($name)`      | Prefixed cron hook     | `yourplugin_daily_task`                            |
| `tableName($name)`     | Full table name        | `wp_yourplugin_orders`                             |
| `metaKey($key)`        | Prefixed meta key      | `_yourplugin_data`                                 |
| `assetHandle($handle)` | Asset handle           | `your-plugin-main`                                 |

### Helper Functions

Global helpers available after bootstrap (`app/Support/helpers.php`):

```php
// Escaping
zylos_e($text);       // esc_html()
zylos_ea($text);      // esc_attr()
zylos_eu($url);       // esc_url()
zylos_ej($text);      // esc_js()
zylos_kses($html);    // wp_kses_post()

// Application
zylos_app();          // Get application instance
zylos_app('service'); // Resolve service from container
context();            // Get PluginContext

// Translation
zylos_m($text);       // __($text, $textDomain)
zylos_em($text);      // echo translated text
```

---

## ⚙️ Configuration

### config/app.php

```php
return [
    'name'       => 'Your Plugin',
    'debug'      => defined('WP_DEBUG') && WP_DEBUG,
    'providers'  => [
        // \YourPlugin\Providers\CustomServiceProvider::class,
    ],
    'capability' => 'manage_options',
];
```

### Service Providers

The bootstrap (`bootstrap/app.php`) registers framework service providers in dependency order:

1. **ConfigServiceProvider** — Configuration and .env loading
2. **I18nServiceProvider** — Internationalization
3. **HookServiceProvider** — WordPress hook management
4. **SecurityServiceProvider** — Nonce, Gate, Sanitizer
5. **HttpServiceProvider** — Request, Response, Pipeline
6. **ValidationServiceProvider** — Input validation
7. **ViewsServiceProvider** — Template rendering
8. **DatabaseServiceProvider** — Database connection
9. **MigrationsServiceProvider** — Schema migrations
10. **RoutingServiceProvider** — URL routing
11. **WpCliServiceProvider** — WP-CLI commands (when available)

---

## 🛤️ Routing

Define routes in `routes/web.php`:

```php
use WPZylos\Framework\Routing\Router;

return static function (Router $router): void {
    // Frontend routes
    $router->get('/products', [ProductController::class, 'index'])->name('products.index');
    $router->get('/products/{id}', [ProductController::class, 'show'])->name('products.show');
    $router->post('/cart/add', [CartController::class, 'add'])->name('cart.add');

    // Route groups with middleware
    $router->group(['prefix' => '/account', 'middleware' => AuthMiddleware::class], function (Router $router) {
        $router->get('/dashboard', [AccountController::class, 'dashboard']);
        $router->post('/update', [AccountController::class, 'update']);
    });
};
```

---

## 🔨 Build & Release

### Development

```bash
composer install          # Install all dependencies
composer test             # Run PHPUnit tests
composer analyze          # Run PHPStan analysis
```

### Production Build

Use the Scaffold CLI for production builds:

**Windows (PowerShell):**

```powershell
.\scaffold.ps1 build              # Full build (QA + Scoper + ZIP)
.\scaffold.ps1 build -SkipQA      # Skip code style/analysis checks
.\scaffold.ps1 build -SkipScoper  # Dev build (skip PHP-Scoper)
```

**Windows (Command Prompt):**

```cmd
powershell -ExecutionPolicy Bypass -File scaffold.ps1 build
powershell -ExecutionPolicy Bypass -File scaffold.ps1 build -SkipQA
powershell -ExecutionPolicy Bypass -File scaffold.ps1 build -SkipScoper
```

**Linux/Mac (or Git Bash):**

```bash
./scaffold.sh build              # Full build (QA + Scoper + ZIP)
./scaffold.sh build --skip-qa    # Skip code style/analysis checks
./scaffold.sh build --skip-scoper  # Dev build (skip PHP-Scoper)
```

The build script will:

1. Clean previous build artifacts
2. Run `phpcbf --standard=PSR12` (code style fix)
3. Run `phpstan analyze` (static analysis)
4. Install production dependencies
5. Run PHP-Scoper for namespace isolation
6. Copy required files & rebuild autoloader
7. Remove development files
8. Create versioned ZIP in `dist/`

> **Note:** The build script reads configuration from `.plugin-config.json` (created by `scaffold init`).

The production build creates a zip file at `dist/your-plugin-1.0.0.zip` ready for deployment.

### PHP-Scoper

The scaffold includes pre-configured PHP-Scoper (`scoper.inc.php`) that:

- Prefixes all vendor namespaces for multi-plugin isolation
- Excludes WordPress core functions, classes, and constants
- Excludes your plugin's namespace
- Generates unique build prefixes using git hash

---

## 🧪 Testing

```bash
# Run all tests
composer test
# Or
./vendor/bin/phpunit

# Run specific test
./vendor/bin/phpunit --filter TestClassName
```

Tests are located in `tests/Unit/`. The test bootstrap is at `tests/bootstrap.php`.

---

## 🔒 Security

The scaffold implements WordPress security best practices:

- **Nonce verification** in form submissions
- **Capability checks** for user permissions
- **Prepared statements** for database queries
- **Output escaping** with proper functions
- **Input sanitization** before processing

See the [Security Package](https://github.com/WPDiggerStudio/wpzylos-security) for detailed security utilities.

---

## 🐛 Troubleshooting

### Composer create-project fails

```bash
php -v              # Verify PHP 8.0+
php -m | grep json  # Verify json extension
```

### Namespace/autoloader issues

```bash
composer dump-autoload
```

Verify `composer.json` PSR-4 namespace matches your class namespace.

### PHP-Scoper errors

Check `scoper.inc.php` and ensure WordPress functions are excluded.

### Built plugin crashes

Verify WordPress symbols are excluded in scoper configuration.

---

## 📦 Related Packages

| Package                                                                    | Description                           |
| -------------------------------------------------------------------------- | ------------------------------------- |
| [wpzylos-core](https://github.com/WPDiggerStudio/wpzylos-core)             | Application foundation                |
| [wpzylos-container](https://github.com/WPDiggerStudio/wpzylos-container)   | PSR-11 dependency injection container |
| [wpzylos-config](https://github.com/WPDiggerStudio/wpzylos-config)         | Configuration management              |
| [wpzylos-routing](https://github.com/WPDiggerStudio/wpzylos-routing)       | URL routing system                    |
| [wpzylos-database](https://github.com/WPDiggerStudio/wpzylos-database)     | Database abstraction                  |
| [wpzylos-migrations](https://github.com/WPDiggerStudio/wpzylos-migrations) | Database migrations                   |
| [wpzylos-hooks](https://github.com/WPDiggerStudio/wpzylos-hooks)           | WordPress hook management             |
| [wpzylos-security](https://github.com/WPDiggerStudio/wpzylos-security)     | Security utilities                    |
| [wpzylos-validation](https://github.com/WPDiggerStudio/wpzylos-validation) | Input validation                      |
| [wpzylos-views](https://github.com/WPDiggerStudio/wpzylos-views)           | Template rendering                    |
| [wpzylos-http](https://github.com/WPDiggerStudio/wpzylos-http)             | HTTP request/response                 |
| [wpzylos-i18n](https://github.com/WPDiggerStudio/wpzylos-i18n)             | Internationalization                  |
| [wpzylos-wp-cli](https://github.com/WPDiggerStudio/wpzylos-wp-cli)         | WP-CLI integration                    |

---

## 📖 Documentation

For comprehensive documentation, tutorials, and API reference, visit **[wpzylos.com](https://wpzylos.com)**.

---

## ☕ Support the Project

If you find this scaffold helpful, consider buying me a coffee! Your support helps maintain and improve the WPZylos ecosystem.

<a href="https://www.paypal.com/donate/?hosted_button_id=66U4L3HG4TLCC" target="_blank">
  <img src="https://img.shields.io/badge/Donate-PayPal-blue.svg?style=for-the-badge&logo=paypal" alt="Donate with PayPal" />
</a>

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

**Made with ❤️ by [WPDiggerStudio](https://github.com/WPDiggerStudio)**
