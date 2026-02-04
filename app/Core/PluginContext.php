<?php

declare(strict_types=1);

namespace MyPlugin\Core;

use WPZylos\Framework\Core\Contracts\ContextInterface;

/**
 * Plugin Context - Core configuration and utility class.
 *
 * This class is owned by the plugin (not the framework) and survives
 * PHP-Scoper namespace rewriting. Framework packages use ContextInterface.
 *
 * Provides centralized access to plugin configuration, paths, URLs, and
 * namespaced identifiers for hooks, options, transients, and database tables.
 *
 * @package MyPlugin\Core
 * @since   1.0.0
 */
class PluginContext implements ContextInterface
{
    /**
     * Absolute path to the main plugin file.
     *
     * @var string
     */
    private string $file;

    /**
     * Plugin slug (e.g., 'my-plugin').
     *
     * @var string
     */
    private string $slug;

    /**
     * Plugin prefix for database tables, options, etc. (e.g., 'mp_').
     *
     * @var string
     */
    private string $prefix;

    /**
     * Text domain for translations.
     *
     * @var string
     */
    private string $textDomain;

    /**
     * Plugin version string.
     *
     * @var string
     */
    private string $version;

    /**
     * Cached base path to the plugin directory.
     *
     * @var string|null
     */
    private ?string $basePath = null;

    /**
     * Cached base URL to the plugin directory.
     *
     * @var string|null
     */
    private ?string $baseUrl = null;

    /**
     * Create a new PluginContext instance.
     *
     * @param array{
     *     file: string,
     *     slug: string,
     *     prefix: string,
     *     textDomain: string,
     *     version: string
     * } $config Configuration array with required keys.
     */
    private function __construct(array $config)
    {
        $this->file = $config['file'];
        $this->slug = $config['slug'];
        $this->prefix = $config['prefix'];
        $this->textDomain = $config['textDomain'];
        $this->version = $config['version'];
    }

    /**
     * Create a new PluginContext instance with validation.
     *
     * @param array{
     *     file: string,
     *     slug: string,
     *     prefix: string,
     *     textDomain: string,
     *     version: string
     * } $config Configuration array with required keys.
     *
     * @return static The created PluginContext instance.
     *
     * @throws \InvalidArgumentException If required config keys are missing.
     */
    public static function create(array $config): static
    {
        $required = ['file', 'slug', 'prefix', 'textDomain', 'version'];
        $missing = array_diff($required, array_keys($config));

        if (!empty($missing)) {
            throw new \InvalidArgumentException(
                sprintf('Missing required config keys: %s', implode(', ', $missing))
            );
        }

        return new static($config);
    }

    /**
     * Get the plugin slug.
     *
     * @return string The plugin slug (e.g., 'my-plugin').
     */
    public function slug(): string
    {
        return $this->slug;
    }

    /**
     * Get the plugin prefix.
     *
     * @return string The plugin prefix (e.g., 'mp_').
     */
    public function prefix(): string
    {
        return $this->prefix;
    }

    /**
     * Get the text domain for translations.
     *
     * @return string The text domain.
     */
    public function textDomain(): string
    {
        return $this->textDomain;
    }

    /**
     * Get the plugin version.
     *
     * @return string The plugin version (e.g., '1.0.0').
     */
    public function version(): string
    {
        return $this->version;
    }

    /**
     * Get the absolute path to the main plugin file.
     *
     * @return string The absolute file path.
     */
    public function file(): string
    {
        return $this->file;
    }

    /**
     * Get the absolute path to the plugin directory or a file within it.
     *
     * @param string $relativePath Optional relative path to append.
     *
     * @return string The absolute path.
     */
    public function path(string $relativePath = ''): string
    {
        if ($this->basePath === null) {
            $this->basePath = plugin_dir_path($this->file);
        }

        return $relativePath === ''
            ? $this->basePath
            : $this->basePath . ltrim($relativePath, '/\\');
    }

    /**
     * Get the URL to the plugin directory or a file within it.
     *
     * @param string $relativePath Optional relative path to append.
     *
     * @return string The URL.
     */
    public function url(string $relativePath = ''): string
    {
        if ($this->baseUrl === null) {
            $this->baseUrl = plugin_dir_url($this->file);
        }

        return $relativePath === ''
            ? $this->baseUrl
            : $this->baseUrl . ltrim($relativePath, '/');
    }

    /**
     * Create a prefixed hook name.
     *
     * @param string $name The hook name without prefix.
     *
     * @return string The prefixed hook name (e.g., 'mp_my_hook').
     */
    public function hook(string $name): string
    {
        return $this->prefix . $name;
    }

    /**
     * Create a prefixed option key.
     *
     * @param string $key The option key without prefix.
     *
     * @return string The prefixed option key (e.g., 'mp_settings').
     */
    public function optionKey(string $key): string
    {
        return $this->prefix . $key;
    }

    /**
     * Create a prefixed transient key.
     *
     * @param string $key The transient key without prefix.
     *
     * @return string The prefixed transient key (e.g., 'mp_cache').
     */
    public function transientKey(string $key): string
    {
        return $this->prefix . $key;
    }

    /**
     * Create a prefixed cron hook name.
     *
     * @param string $name The cron hook name without prefix.
     *
     * @return string The prefixed cron hook name (e.g., 'mp_daily_task').
     */
    public function cronHook(string $name): string
    {
        return $this->prefix . $name;
    }

    /**
     * Create a fully prefixed database table name.
     *
     * Combines WordPress table prefix + plugin prefix + table name.
     *
     * @param string $name  The table name without prefixes.
     * @param string $scope Either 'site' (default) or 'network' for multisite.
     *
     * @return string The full table name (e.g., 'wp_mp_products').
     */
    public function tableName(string $name, string $scope = 'site'): string
    {
        global $wpdb;

        $wpPrefix = ($scope === 'network' && isset($wpdb->base_prefix))
            ? $wpdb->base_prefix
            : $wpdb->prefix;

        return $wpPrefix . $this->prefix . $name;
    }

    /**
     * Create a prefixed meta key.
     *
     * Meta keys are prefixed with underscore to hide from custom fields UI.
     *
     * @param string $key The meta key without prefix.
     *
     * @return string The prefixed meta key (e.g., '_mp_data').
     */
    public function metaKey(string $key): string
    {
        return '_' . $this->prefix . $key;
    }

    /**
     * Create a prefixed asset handle for scripts and styles.
     *
     * @param string $handle The asset handle without prefix.
     *
     * @return string The prefixed handle (e.g., 'my-plugin-admin').
     */
    public function assetHandle(string $handle): string
    {
        return $this->slug . '-' . $handle;
    }
}
