<?php

declare(strict_types=1);

namespace MyPlugin\Lifecycle;

use MyPlugin\Core\PluginContext;

/**
 * Plugin uninstaller.
 *
 * Handles complete data removal when plugin is deleted
 * and user has opted to remove data.
 *
 * @package MyPlugin\Lifecycle
 */
class Uninstaller
{
    /**
     * Run uninstall logic.
     *
     * @param PluginContext $context Plugin context
     *
     * @return void
     */
    public static function uninstall(PluginContext $context): void
    {
        // Remove options
        self::removeOptions($context);

        // Remove transients
        self::removeTransients($context);

        // Drop custom tables
        self::dropTables($context);

        // Clean up user meta
        self::removeUserMeta($context);

        // Clean up post meta
        self::removePostMeta($context);
    }

    /**
     * Remove all plugin options.
     *
     * @param PluginContext $context Plugin context
     *
     * @return void
     */
    private static function removeOptions(PluginContext $context): void
    {
        global $wpdb;

        $prefix = $context->prefix();

        // Delete from options table
        $wpdb->query($wpdb->prepare(
            "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s",
            $wpdb->esc_like($prefix) . '%'
        ));

        // Multisite: delete from sitemeta
        if (is_multisite()) {
            $wpdb->query($wpdb->prepare(
                "DELETE FROM {$wpdb->sitemeta} WHERE meta_key LIKE %s",
                $wpdb->esc_like($prefix) . '%'
            ));
        }
    }

    /**
     * Remove all transients.
     *
     * @param PluginContext $context Plugin context
     *
     * @return void
     */
    private static function removeTransients(PluginContext $context): void
    {
        global $wpdb;

        $prefix = $context->prefix();

        // Delete transients
        $wpdb->query($wpdb->prepare(
            "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s OR option_name LIKE %s",
            '_transient_' . $wpdb->esc_like($prefix) . '%',
            '_transient_timeout_' . $wpdb->esc_like($prefix) . '%'
        ));
    }

    /**
     * Drop custom database tables.
     *
     * @param PluginContext $context Plugin context
     *
     * @return void
     */
    private static function dropTables(PluginContext $context): void
    {
        global $wpdb;

        // List custom tables (without prefix)
        $tables = [
            // 'orders',
            // 'items',
        ];

        foreach ($tables as $table) {
            $tableName = $context->tableName($table);
            // phpcs:ignore WordPress.DB.PreparedSQL.InterpolatedNotPrepared
            $wpdb->query("DROP TABLE IF EXISTS {$tableName}");
        }
    }

    /**
     * Remove user meta.
     *
     * @param PluginContext $context Plugin context
     *
     * @return void
     */
    private static function removeUserMeta(PluginContext $context): void
    {
        global $wpdb;

        $metaPrefix = '_' . $context->prefix();

        $wpdb->query($wpdb->prepare(
            "DELETE FROM {$wpdb->usermeta} WHERE meta_key LIKE %s",
            $wpdb->esc_like($metaPrefix) . '%'
        ));
    }

    /**
     * Remove post meta.
     *
     * @param PluginContext $context Plugin context
     *
     * @return void
     */
    private static function removePostMeta(PluginContext $context): void
    {
        global $wpdb;

        $metaPrefix = '_' . $context->prefix();

        $wpdb->query($wpdb->prepare(
            "DELETE FROM {$wpdb->postmeta} WHERE meta_key LIKE %s",
            $wpdb->esc_like($metaPrefix) . '%'
        ));
    }
}
