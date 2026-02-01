<?php

declare( strict_types=1 );

/**
 * Web routes.
 *
 * Define frontend routes here. Returns a callable that receives
 * the Router instance.
 *
 * @package MyPlugin
 */

use WPZylos\Framework\Routing\Router;

return static function ( Router $router ): void {
	// Example routes
	// $router->get('/products', [ProductController::class, 'index'])->name('products.index');
	// $router->get('/products/{id}', [ProductController::class, 'show'])->name('products.show');
	// $router->post('/cart/add', [CartController::class, 'add'])->name('cart.add');

	// Route groups with middleware
	// $router->group(['prefix' => '/account', 'middleware' => AuthMiddleware::class], function (Router $router) {
	//     $router->get('/dashboard', [AccountController::class, 'dashboard']);
	//     $router->post('/update', [AccountController::class, 'update']);
	// });
};
