<?php

/**
 * Uninstall handler.
 *
 * Runs when the plugin is deleted from WordPress.
 * Respects user preference for keeping data.
 *
 * @package MyPlugin
 */

// Exit if not called by WordPress uninstallation
defined('WP_UNINSTALL_PLUGIN') || exit;

// Load autoloader
require_once __DIR__ . '/vendor/autoload.php';

use MyPlugin\Core\PluginContext;
use MyPlugin\Includes\Uninstaller;

// Create context
$context = PluginContext::create([
    'file' => __DIR__ . '/my-plugin.php',
    'slug' => 'my-plugin',
    'prefix' => 'myplugin_',
    'textDomain' => 'my-plugin',
    'version' => '1.0.0',
]);

// Check user preference
$keepData = get_option($context->optionKey('keep_data_on_uninstall'), true);

if (!$keepData) {
    Uninstaller::uninstall($context);
}
