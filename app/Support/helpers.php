<?php

/**
 * Global helper functions.
 *
 * Template helpers and convenience functions.
 *
 * @package MyPlugin
 */

declare(strict_types=1);

// =========================================================================
// Template Escape Helpers (required for all templates)
// =========================================================================

if (! function_exists('zylos_e')) {
    /**
     * Escape for HTML output.
     *
     * @param string $text Text to escape
     *
     * @return string Escaped text
     */
    function zylos_e(string $text): string
    {
        return esc_html($text);
    }
}

if (! function_exists('zylos_ea')) {
    /**
     * Escape for HTML attribute.
     *
     * @param string $text Text to escape
     *
     * @return string Escaped text
     */
    function zylos_ea(string $text): string
    {
        return esc_attr($text);
    }
}

if (! function_exists('zylos_eu')) {
    /**
     * Escape URL.
     *
     * @param string $url URL to escape
     *
     * @return string Escaped URL
     */
    function zylos_eu(string $url): string
    {
        return esc_url($url);
    }
}

if (! function_exists('zylos_ej')) {
    /**
     * Escape for JavaScript.
     *
     * @param string $text Text to escape
     *
     * @return string Escaped text
     */
    function zylos_ej(string $text): string
    {
        return esc_js($text);
    }
}

if (! function_exists('zylos_kses')) {
    /**
     * Filter HTML to allowed tags.
     *
     * @param string $html HTML to filter
     * @param string $context 'post', 'data', or 'strip'
     *
     * @return string Filtered HTML
     */
    function zylos_kses(string $html, string $context = 'post'): string
    {
        return match ($context) {
            'data' => wp_kses_data($html),
            'strip' => wp_kses($html, []),
            default => wp_kses_post($html),
        };
    }
}

// =========================================================================
// App Helpers (use after bootstrap)
// =========================================================================

if (! function_exists('zylos_app')) {
    /**
     * Get the application instance or resolve a service.
     *
     * @param string|null $abstract Service to resolve
     *
     * @return mixed
     */
    function zylos_app(?string $abstract = null): mixed
    {
        global $my_plugin_app;

        if ($abstract === null) {
            return $my_plugin_app;
        }

        return $my_plugin_app?->make($abstract);
    }
}

if (! function_exists('context')) {
    /**
     * Get the plugin context.
     *
     * @return \MyPlugin\Core\PluginContext|null
     */
    function context(): ?\MyPlugin\Core\PluginContext
    {
        global $my_plugin_context;

        return $my_plugin_context;
    }
}

if (! function_exists('zylos_m')) {
    /**
     * Translate with plugin text domain.
     *
     * @param string $text Text to translate
     *
     * @return string Translated text
     */
    function zylos_m(string $text): string
    {
        $context = context();

        return $context ? __($text, $context->textDomain()) : $text;
    }
}

if (! function_exists('zylos_em')) {
    /**
     * Echo translated text with the plugin text domain.
     *
     * @param string $text Text to translate
     *
     * @return void
     */
    function zylos_em(string $text): void
    {
        echo zylos_m($text);
    }
}
