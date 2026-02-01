<?php

declare(strict_types=1);

/**
 * PHP-Scoper configuration.
 *
 * Prefixes all vendor namespaces for multi-plugin isolation.
 *
 * @see https://github.com/humbug/php-scoper
 */

use Isolated\Symfony\Component\Finder\Finder;

// Generate a unique prefix: slug + short hash
// Falls back to timestamp if not in git repo
$pluginSlug = 'my_plugin';
$buildHash = trim(shell_exec('git rev-parse --short HEAD 2>/dev/null') ?? '');

if (empty($buildHash)) {
    $buildHash = substr(md5((string) time()), 0, 8);
}

$prefix = "WPZylosScoped\\{$pluginSlug}_{$buildHash}";

return [
    'prefix' => $prefix,

    // Finders for files to scope
    'finders' => [
        Finder::create()
            ->files()
            ->ignoreVCS(true)
            ->notName('/LICENSE|.*\\.md|.*\\.dist|Makefile/')
            ->exclude([
                'doc',
                'test',
                'test_old',
                'tests',
                'Tests',
                'vendor-bin',
            ])
            ->in('vendor'),
    ],

    // Files to exclude from scoping
    'exclude-files' => [
        'my-plugin.php',
        'uninstall.php',
    ],

    // Namespaces to exclude from scoping
    'exclude-namespaces' => [
        'MyPlugin',           // Plugin namespace (keep stable)
        'WP_CLI',             // WP-CLI namespace
        'Composer',           // Composer autoloader
    ],

    // Classes to exclude (WordPress core)
    'exclude-classes' => [
        'WP_Error',
        'WP_Query',
        'WP_User',
        'WP_Post',
        'WP_Term',
        'WP_REST_Request',
        'WP_REST_Response',
        'wpdb',
        'Walker',
        'WP_Widget',
    ],

    // Functions to exclude (WordPress core)
    'exclude-functions' => [
        // Hooks
        'add_action',
        'add_filter',
        'do_action',
        'apply_filters',
        'remove_action',
        'remove_filter',
        'has_action',
        'has_filter',

        // Options
        'get_option',
        'update_option',
        'delete_option',
        'add_option',

        // Transients
        'get_transient',
        'set_transient',
        'delete_transient',

        // i18n
        '__',
        '_e',
        '_n',
        '_x',
        'esc_html__',
        'esc_html_e',
        'esc_attr__',
        'esc_attr_e',

        // Escaping
        'esc_html',
        'esc_attr',
        'esc_url',
        'esc_js',
        'wp_kses',
        'wp_kses_post',
        'wp_kses_data',

        // Sanitization
        'sanitize_text_field',
        'sanitize_textarea_field',
        'sanitize_email',
        'sanitize_title',
        'sanitize_key',
        'sanitize_file_name',
        'absint',

        // Nonces
        'wp_create_nonce',
        'wp_verify_nonce',
        'wp_nonce_field',
        'wp_nonce_url',
        'check_admin_referer',
        'check_ajax_referer',

        // User/capability
        'current_user_can',
        'user_can',
        'get_current_user_id',
        'is_user_logged_in',

        // Activation
        'register_activation_hook',
        'register_deactivation_hook',
        'register_uninstall_hook',

        // Misc
        'plugin_dir_path',
        'plugin_dir_url',
        'plugin_basename',
        'wp_upload_dir',
        'wp_mkdir_p',
        'flush_rewrite_rules',
        'add_rewrite_rule',
        'wp_die',
        'is_admin',
        'is_multisite',
        'wp_doing_ajax',
        'wp_doing_cron',
    ],

    // Constants to exclude
    'exclude-constants' => [
        'ABSPATH',
        'WPINC',
        'WP_CONTENT_DIR',
        'WP_CONTENT_URL',
        'WP_PLUGIN_DIR',
        'WP_PLUGIN_URL',
        'WP_DEBUG',
        'WP_DEBUG_LOG',
        'DOING_AJAX',
        'DOING_CRON',
        'REST_REQUEST',
        'XMLRPC_REQUEST',
        'WP_CLI',
    ],

    // Patchers for edge cases
    'patchers' => [
        // Fix string class references if needed
    ],
];
