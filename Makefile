# Common commands. Run `make help` to see the list.

.PHONY: help bootstrap clean get codegen watch dev staging prod test analyze fix lint format icons splash build-ios build-android

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

bootstrap: ## First-time setup: install Flutter deps + generate code
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs

clean: ## Nuke caches and reinstall
	flutter clean
	flutter pub get

get: ## flutter pub get
	flutter pub get

codegen: ## One-shot codegen
	dart run build_runner build --delete-conflicting-outputs

watch: ## Codegen watcher (run in a separate terminal during dev)
	dart run build_runner watch --delete-conflicting-outputs

dev: ## Run the dev flavor against the local backend
	flutter run \
	  --flavor development \
	  --target lib/main_development.dart \
	  --dart-define=FLAVOR=development \
	  --dart-define=API_BASE_URL=http://localhost:8000

staging: ## Run the staging flavor
	flutter run \
	  --flavor staging \
	  --target lib/main_staging.dart \
	  --dart-define=FLAVOR=staging \
	  --dart-define=API_BASE_URL=https://staging.api.datasolids.com

prod: ## Run the production flavor (do NOT use against real users from a dev machine)
	flutter run \
	  --target lib/main.dart \
	  --dart-define=FLAVOR=production \
	  --dart-define=API_BASE_URL=https://api.datasolids.com

test: ## Run unit + widget tests with coverage
	flutter test --coverage

analyze: ## Static analysis
	flutter analyze

fix: ## Auto-fix what dart_format and dart_fix can
	dart format lib test
	dart fix --apply

lint: ## Riverpod-aware custom lints
	dart run custom_lint

format: ## Format only
	dart format lib test

icons: ## Regenerate launcher icons (after replacing assets/icons/app_icon.png)
	dart run flutter_launcher_icons

splash: ## Regenerate native splash
	dart run flutter_native_splash:create

build-ios: ## Production iOS build (no codesign)
	flutter build ios --release \
	  --dart-define=FLAVOR=production \
	  --dart-define=API_BASE_URL=https://api.datasolids.com \
	  --no-codesign

build-android: ## Production Android app bundle
	flutter build appbundle --release \
	  --dart-define=FLAVOR=production \
	  --dart-define=API_BASE_URL=https://api.datasolids.com
