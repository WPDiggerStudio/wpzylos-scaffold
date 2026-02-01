<?php

/**
 * Application configuration.
 *
 * @package MyPlugin
 */

return [
	/**
	 * Application name.
	 */
	'name'       => 'My Plugin',

	/**
	 * Debug mode.
	 */
	'debug'      => defined( 'WP_DEBUG' ) && WP_DEBUG,

	/**
	 * Service providers to register.
	 */
	'providers'  => [
		// \MyPlugin\Providers\AppServiceProvider::class,
	],

	/**
	 * Settings page capability.
	 */
	'capability' => 'manage_options',
];
