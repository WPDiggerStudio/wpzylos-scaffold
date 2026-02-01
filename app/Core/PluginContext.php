<?php

declare(strict_types=1);

namespace MyPlugin\Core;

use WPZylos\Framework\Core\Contracts\ContextInterface;

/**
 * Plugin context.
 *
 * This class is owned by the plugin (not the framework) and survives
 * PHP-Scoper namespace rewriting. Framework packages use ContextInterface.
 *
 * @package MyPlugin\Core
 */
class PluginContext implements ContextInterface
{
    private string $file;
    private string $slug;
    private string $prefix;
    private string $textDomain;
    private string $version;
    private ?string $basePath = null;
    private ?string $baseUrl = null;

    /**
     * @param array{
     *     file: string,
     *     slug: string,
     *     prefix: string,
     *     textDomain: string,
     *     version: string
     * } $config
     */
    private function __construct(array $config)
    {
        $this->file       = $config['file'];
        $this->slug       = $config['slug'];
        $this->prefix     = $config['prefix'];
        $this->textDomain = $config['textDomain'];
        $this->version    = $config['version'];
    }

    /**
     * @param array{
     *     file: string,
     *     slug: string,
     *     prefix: string,
     *     textDomain: string,
     *     version: string
     * } $config
     */
    public static function create(array $config): static
    {
        $required = [ 'file', 'slug', 'prefix', 'textDomain', 'version' ];
        $missing  = array_diff($required, array_keys($config));

        if (! empty($missing)) {
            throw new \InvalidArgumentException(
                sprintf('Missing required config keys: %s', implode(', ', $missing))
            );
        }

        return new static($config);
    }

    public function slug(): string
    {
        return $this->slug;
    }

    public function prefix(): string
    {
        return $this->prefix;
    }

    public function textDomain(): string
    {
        return $this->textDomain;
    }

    public function version(): string
    {
        return $this->version;
    }

    public function file(): string
    {
        return $this->file;
    }

    public function path(string $relativePath = ''): string
    {
        if ($this->basePath === null) {
            $this->basePath = plugin_dir_path($this->file);
        }

        return $relativePath === ''
            ? $this->basePath
            : $this->basePath . ltrim($relativePath, '/\\');
    }

    public function url(string $relativePath = ''): string
    {
        if ($this->baseUrl === null) {
            $this->baseUrl = plugin_dir_url($this->file);
        }

        return $relativePath === ''
            ? $this->baseUrl
            : $this->baseUrl . ltrim($relativePath, '/');
    }

    public function hook(string $name): string
    {
        return $this->prefix . $name;
    }

    public function optionKey(string $key): string
    {
        return $this->prefix . $key;
    }

    public function transientKey(string $key): string
    {
        return $this->prefix . $key;
    }

    public function cronHook(string $name): string
    {
        return $this->prefix . $name;
    }

    public function tableName(string $name, string $scope = 'site'): string
    {
        global $wpdb;

        $wpPrefix = ( $scope === 'network' && isset($wpdb->base_prefix) )
            ? $wpdb->base_prefix
            : $wpdb->prefix;

        return $wpPrefix . $this->prefix . $name;
    }

    public function metaKey(string $key): string
    {
        return '_' . $this->prefix . $key;
    }

    public function assetHandle(string $handle): string
    {
        return $this->slug . '-' . $handle;
    }
}
