<?php

declare( strict_types=1 );

namespace MyPlugin\Includes;

use MyPlugin\Core\PluginContext;

/**
 * Plugin deactivator.
 *
 * Handles cleanup when plugin is deactivated.
 *
 * @package MyPlugin\Includes
 */
class Deactivator {
	/**
	 * Run deactivation logic.
	 *
	 * @param PluginContext $context Plugin context
	 *
	 * @return void
	 */
	public static function deactivate( PluginContext $context ): void {
		// Clear scheduled hooks
		self::clearScheduledHooks( $context );

		// Flush rewrite rules
		flush_rewrite_rules();
	}

	/**
	 * Clear all scheduled cron hooks.
	 *
	 * @param PluginContext $context Plugin context
	 *
	 * @return void
	 */
	private static function clearScheduledHooks( PluginContext $context ): void {
		// List of scheduled hook names (without prefix)
		$scheduledHooks = [
			'daily_cleanup',
			'weekly_report',
		];

		foreach ( $scheduledHooks as $hook ) {
			$prefixedHook = $context->cronHook( $hook );
			wp_clear_scheduled_hook( $prefixedHook );
		}
	}
}
