# WPZylos Plugin Build

PLUGIN_SLUG := my-plugin
VERSION := 1.0.0

# Directories
BUILD_DIR := build
DIST_DIR := dist

.PHONY: all clean install scope build dist test

## all: Run full build pipeline
all: clean install scope build dist

## clean: Remove build artifacts
clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	rm -f $(PLUGIN_SLUG).zip

## install: Install dependencies
install:
	composer install --no-dev --optimize-autoloader

## scope: Run PHP-Scoper to prefix namespaces
scope:
	@echo "Running PHP-Scoper..."
	vendor/bin/php-scoper add-prefix --output-dir=$(BUILD_DIR) --force
	@echo "Rebuilding autoloader..."
	composer dump-autoload --working-dir=$(BUILD_DIR) --classmap-authoritative

## build: Prepare build directory
build:
	@echo "Preparing build..."
	# Copy non-PHP files that scoper skips
	cp -r resources $(BUILD_DIR)/
	cp -r config $(BUILD_DIR)/
	cp -r routes $(BUILD_DIR)/
	cp uninstall.php $(BUILD_DIR)/
	cp my-plugin.php $(BUILD_DIR)/

## dist: Create distributable zip
dist:
	@echo "Creating distribution..."
	mkdir -p $(DIST_DIR)
	cd $(BUILD_DIR) && zip -r ../$(DIST_DIR)/$(PLUGIN_SLUG)-$(VERSION).zip .
	@echo "Created: $(DIST_DIR)/$(PLUGIN_SLUG)-$(VERSION).zip"

## test: Run tests
test:
	./vendor/bin/phpunit

## dev: Install dev dependencies
dev:
	composer install

## lint: Run code style checks
lint:
	./vendor/bin/phpcs --standard=WordPress app/ includes/

## analyze: Run static analysis
analyze:
	./vendor/bin/phpstan analyse --level=5 app/ includes/

## help: Show this help
help:
	@echo "Available targets:"
	@grep -E '^##' Makefile | sed 's/##/  /'
