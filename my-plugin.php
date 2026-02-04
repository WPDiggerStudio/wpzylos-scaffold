<?php

/**
 * Plugin Name: My Plugin
 * Plugin URI: https://example.com/my-plugin
 * Description: A plugin built with WPZylos framework.
 * Version: 1.0.0
 * Author: Your Name
 * Author URI: https://example.com
 * License: GPL-2.0-or-later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: my-plugin
 * Domain Path: /resources/lang
 * Requires at least: 6.0
 * Requires PHP: 8.1
 *
 * @package MyPlugin
 */

declare(strict_types=1);

// Exit if accessed directly
defined('ABSPATH') || exit;

// Autoloader
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
	require_once __DIR__ . '/vendor/autoload.php';
}

use MyPlugin\Core\PluginContext;
use MyPlugin\Lifecycle\Activator;
use MyPlugin\Lifecycle\Deactivator;

/**
 * Create plugin context.
 *
 * This is the single source of truth for plugin identity.
 * All framework components use this context for prefixing.
 */
$context = PluginContext::create([
	'file' => __FILE__,
	'slug' => 'my-plugin',
	'prefix' => 'myplugin_',
	'textDomain' => 'my-plugin',
	'version' => '1.0.0',
]);

// Store context globally for bootstrap
global $my_plugin_context;
$my_plugin_context = $context;

/**
 * Activation hook.
 *
 * Uses closure to pass context (WP calls with no args).
 */
register_activation_hook(__FILE__, static function () use ($context) {
	Activator::activate($context);
});

/**
 * Deactivation hook.
 */
register_deactivation_hook(__FILE__, static function () use ($context) {
	Deactivator::deactivate($context);
});

/**
 * Requirements check.
 *
 * Show an admin notice and deactivate if requirements are not met.
 */
add_action('admin_init', static function () use ($context) {
	if (PHP_VERSION_ID < 80100) {
		add_action('admin_notices', static function () use ($context) {
			echo '<div class="notice notice-error"><p>';
			echo esc_html(
				sprintf(
					/* translators: %s: Required PHP version */
					__('My Plugin requires PHP version %s or higher.', $context->textDomain()),
					'8.1'
				)
			);
			echo '</p></div>';
		});
		deactivate_plugins(plugin_basename(__FILE__));

		return;
	}

	if (version_compare(get_bloginfo('version'), '6.0', '<')) {
		add_action('admin_notices', static function () use ($context) {
			echo '<div class="notice notice-error"><p>';
			echo esc_html(
				sprintf(
					/* translators: %s: Required WordPress version */
					__('My Plugin requires WordPress version %s or higher.', $context->textDomain()),
					'6.0'
				)
			);
			echo '</p></div>';
		});
		deactivate_plugins(plugin_basename(__FILE__));

		return;
	}
});

/**
 * Bootstrap the application.
 *
 * The bootstrap file returns a callable that takes the context.
 */
add_action('plugins_loaded', static function () use ($context) {
	$bootstrap = require __DIR__ . '/bootstrap/app.php';
	if (is_callable($bootstrap)) {
		$bootstrap($context);
	}
});
