<?php
/**
 * Bootstrap the application.
 *
 * Boot sequence:
 * 1. RequirementsGate → Context → Autoload (in main plugin file)
 * 2. Activation hooks closures (in main plugin file)
 * 3. Bootstrap container/providers (this file)
 * 4. Load config/.env
 * 5. Load i18n
 * 6. Register WP hooks
 * 7. Register routes
 * 8. Dispatch
 *
 * @package MyPlugin
 */

declare( strict_types=1 );

use MyPlugin\Core\PluginContext;
use WPZylos\Framework\Config\ConfigServiceProvider;
use WPZylos\Framework\Core\Application;
use WPZylos\Framework\Database\DatabaseServiceProvider;
use WPZylos\Framework\Hooks\HookServiceProvider;
use WPZylos\Framework\Http\HttpServiceProvider;
use WPZylos\Framework\I18n\I18nServiceProvider;
use WPZylos\Framework\Migrations\MigrationsServiceProvider;
use WPZylos\Framework\Routing\RoutingServiceProvider;
use WPZylos\Framework\Security\SecurityServiceProvider;
use WPZylos\Framework\Validation\ValidationServiceProvider;
use WPZylos\Framework\Views\ViewsServiceProvider;
use WPZylos\Framework\WpCli\WpCliServiceProvider;

/**
 * Bootstrap the application.
 *
 * @param PluginContext $context Plugin context
 *
 * @return Application
 */
return static function ( PluginContext $context ): Application {
	// Create application with default container
	$app = new Application( $context );

	// -------------------------------------------------------------------------
	// Register Core Providers
	// Order matters: dependencies must be registered before dependents
	// -------------------------------------------------------------------------

	// Phase 1: Foundation (no dependencies)
	$app->register( new ConfigServiceProvider() );       // Config + .env
	$app->register( new I18nServiceProvider() );         // i18n + translator
	$app->register( new HookServiceProvider() );         // Hook manager

	// Phase 2: Security (depends on i18n for messages)
	$app->register( new SecurityServiceProvider() );     // Nonce, Gate, Sanitizer

	// Phase 3: HTTP (depends on security)
	$app->register( new HttpServiceProvider() );         // Request, Response, Pipeline

	// Phase 4: Validation + Views (depend on i18n)
	$app->register( new ValidationServiceProvider() );   // Validator, FormRequest
	$app->register( new ViewsServiceProvider() );        // ViewFactory

	// Phase 5: Database + Migrations
	$app->register( new DatabaseServiceProvider() );     // Connection, QueryBuilder
	$app->register( new MigrationsServiceProvider() );   // Migrator

	// Phase 6: Routing (depends on HTTP, container)
	$app->register( new RoutingServiceProvider() );      // Router, Dispatcher

	// Phase 7: CLI (only when WP_CLI)
	if ( defined( 'WP_CLI' ) && WP_CLI ) {
		$app->register( new WpCliServiceProvider() );    // WP-CLI commands
	}

	// -------------------------------------------------------------------------
	// Boot the application
	// -------------------------------------------------------------------------
	$app->boot();

	return $app;
};
