<?php

declare( strict_types=1 );

namespace MyPlugin\Includes;

use MyPlugin\Core\PluginContext;
use WPZylos\Framework\Routing\MinimalRouter;
use WPZylos\Framework\Routing\WPAdapter;

/**
 * Plugin activator.
 *
 * Handles plugin activation tasks like registering rewrite rules
 * and checking requirements.
 *
 * @package MyPlugin\Includes
 */
class Activator {
	/**
	 * Run activation logic.
	 *
	 * @param PluginContext $context Plugin context
	 *
	 * @return void
	 */
	public static function activate( PluginContext $context ): void {
		// Check requirements
		if ( ! self::checkRequirements() ) {
			deactivate_plugins( plugin_basename( $context->file() ) );
			wp_die(
				esc_html__( 'This plugin requires PHP 8.0+ and WordPress 6.0+', $context->textDomain() ),
				esc_html__( 'Plugin Activation Error', $context->textDomain() ),
				[ 'back_link' => true ]
			);
		}

		// Register rewrite rules
		self::registerRewriteRules( $context );

		// Run migrations if needed
		// self::runMigrations($context);

		// Set initial options
		self::setDefaults( $context );

		// Flush rewrite rules
		flush_rewrite_rules();
	}

	/**
	 * Check minimum requirements.
	 *
	 * @return bool True if requirements met
	 */
	private static function checkRequirements(): bool {
		$phpVersion = '8.0';
		$wpVersion  = '6.0';

		if ( version_compare( PHP_VERSION, $phpVersion, '<' ) ) {
			return false;
		}

		if ( version_compare( get_bloginfo( 'version' ), $wpVersion, '<' ) ) {
			return false;
		}

		return true;
	}

	/**
	 * Register rewrite rules from the routes file.
	 *
	 * @param PluginContext $context Plugin context
	 *
	 * @return void
	 */
	private static function registerRewriteRules( PluginContext $context ): void {
		$routesPath = $context->path( 'routes/web.php' );

		if ( ! file_exists( $routesPath ) ) {
			return;
		}

		// Load routes using minimal router (no container boot)
		$callback = require $routesPath;

		if ( ! is_callable( $callback ) ) {
			return;
		}

		$router = new MinimalRouter();
		$callback( $router );

		// Register with WordPress
		$adapter = new WPAdapter( $context );
		$adapter->registerRewriteRules( $router->getRoutes() );
	}

	/**
	 * Set default options.
	 *
	 * @param PluginContext $context Plugin context
	 *
	 * @return void
	 */
	private static function setDefaults( PluginContext $context ): void {
		// Set version for migrations
		if ( get_option( $context->optionKey( 'version' ) ) === false ) {
			update_option( $context->optionKey( 'version' ), $context->version() );
		}

		// Default "keep data on uninstall" to true
		if ( get_option( $context->optionKey( 'keep_data_on_uninstall' ) ) === false ) {
			update_option( $context->optionKey( 'keep_data_on_uninstall' ), true );
		}
	}
}
