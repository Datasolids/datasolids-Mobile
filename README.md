# Datasolids Mobile

Flutter mobile app for the Datasolids patient-controlled health data platform. Talks to the Django backend at `datasolids-backend` and shares the same JWT + refresh-rotation auth flow.

## Stack

- **Flutter** 3.24+ / Dart 3.5+
- **State management:** Riverpod 2 (`flutter_riverpod` + `riverpod_generator`)
- **Routing:** GoRouter 14 with auth-aware redirects
- **HTTP:** Dio with auth + refresh + logging interceptors; Retrofit-ready
- **Models:** Freezed + json_serializable (codegen)
- **Local storage:** flutter_secure_storage (tokens), Drift (cache), shared_preferences (prefs)
- **Auth:** JWT access + rotating refresh tokens, biometric prompt (local_auth)
- **Crash reporting:** Sentry (staging + production only)
- **Push:** Firebase Messaging + flutter_local_notifications
- **Linting:** very_good_analysis + riverpod_lint via custom_lint
- **Testing:** flutter_test, mocktail, patrol for integration

## First-time setup

```bash
# 1. Install Flutter if you don't have it
#    https://docs.flutter.dev/get-started/install — use the stable channel.

# 2. Clone + bootstrap
git clone <repo-url> datasolids-mobile
cd datasolids-mobile
make bootstrap

# 3. Create the native shell. Run ONCE — this generates android/ and ios/.
flutter create . --platforms=ios,android \
  --org com.datasolids --project-name datasolids_mobile

# 4. Copy env templates and fill in your values
cp .env.example .env.development
cp .env.example .env.staging
cp .env.example .env.production
# Edit each with the right API_BASE_URL and SENTRY_DSN.

# 5. Run against the local backend (start the backend first per
#    datasolids-backend/README.md — it must be reachable at API_BASE_URL).
make dev
```

## Project layout

```
datasolids-mobile/
├── android/                       # Native Android shell (gen via `flutter create`)
├── ios/                           # Native iOS shell
├── assets/
│   ├── fonts/                     # Inter + JetBrains Mono
│   ├── images/
│   └── icons/                     # App icon, splash
├── lib/
│   ├── main.dart                  # Production entrypoint
│   ├── main_development.dart      # Dev entrypoint
│   ├── main_staging.dart          # Staging entrypoint
│   ├── bootstrap.dart             # Shared boot: Sentry, dotenv, ProviderScope
│   ├── app/
│   │   ├── app.dart               # MaterialApp.router root
│   │   ├── router.dart            # GoRouter config + auth redirect
│   │   └── observers.dart         # ProviderObserver
│   ├── core/
│   │   ├── auth/                  # TokenManager, auth_state
│   │   ├── config/                # Env, Flavor
│   │   ├── errors/                # AppFailure hierarchy + Dio-to-failure mapper
│   │   ├── logging/               # appLogger
│   │   ├── network/               # Dio client + interceptors
│   │   ├── storage/               # SecureStorage wrapper
│   │   └── theme/                 # AppColors, AppPalette, AppTheme
│   ├── features/                  # Feature-first — copy `auth/` as the template
│   │   ├── auth/
│   │   │   ├── data/              # AuthApi, DTOs
│   │   │   ├── domain/            # AuthRepository (returns Either<AppFailure, T>)
│   │   │   └── presentation/      # Screens + Riverpod controllers
│   │   ├── home/                  # Placeholder dashboard
│   │   └── splash/                # Auth-warmup screen
│   └── shared/
├── test/                          # Unit + widget tests
├── integration_test/              # Patrol-driven e2e
├── analysis_options.yaml          # Strict analyzer + Riverpod custom_lint
├── pubspec.yaml
└── Makefile                       # `make help` for the list
```

## Architecture conventions (please read before contributing)

**Feature-first.** Every feature lives in `lib/features/<feature>/` with three folders: `data/` (API clients, DTOs), `domain/` (repository, entities), `presentation/` (screens, controllers). Don't dump unrelated logic into `core/`.

**No raw `try`/`catch` in screens.** Repositories return `Either<AppFailure, T>` via `fpdart`. Screens read the `Left` branch and render an error state. The interceptors map every `DioException` into a typed `AppFailure` before it ever reaches a screen.

**Tokens never leave `TokenManager`.** Feature code reads `tokenManagerProvider.getAccessToken()` and that's the only public surface. If you find yourself calling `FlutterSecureStorage` directly outside `core/storage/`, you're doing it wrong.

**Theme tokens, not literals.** Use `Theme.of(context).colorScheme` or `Theme.of(context).extension<AppPalette>()`. Direct `Color(0xFF...)` in feature code is a lint smell.

**Codegen runs in CI.** Don't commit generated files (`.g.dart`, `.freezed.dart`) — they're gitignored. Run `make codegen` after changing a model with `@freezed` or `@JsonSerializable`. While developing, run `make watch` in a second terminal.

**Auth state drives routing.** Don't `Navigator.push` from a controller. Flip `authStateProvider` (via `tokenManager.signOut()` or `saveTokens()`) and the router redirects.

## Commands

```bash
make help          # show every target
make bootstrap     # first-time setup
make dev           # run against the local backend
make staging       # run against staging
make test          # tests + coverage
make analyze       # static analysis
make lint          # Riverpod custom lints
make fix           # auto-format + dart fix
make codegen       # build_runner one-shot
make watch         # build_runner watcher (run while developing)
make build-ios     # release iOS build (no codesign)
make build-android # release Android app bundle
```

## Build flavors

Three flavors are wired:

| Flavor      | Entrypoint                  | Default backend                               |
|-------------|-----------------------------|-----------------------------------------------|
| development | `lib/main_development.dart` | `http://localhost:8000`                       |
| staging     | `lib/main_staging.dart`     | `https://staging.api.datasolids.com`          |
| production  | `lib/main.dart`             | `https://api.datasolids.com`                  |

Override `API_BASE_URL` at run/build time with `--dart-define`:

```bash
flutter run \
  --flavor development \
  --target lib/main_development.dart \
  --dart-define=API_BASE_URL=http://192.168.1.42:8000
```

The Sentry DSN is only attached for staging + production. Dev crashes go to the console.

## Auth flow

The mobile app speaks the same JWT + rotating refresh flow as the web app:

1. **Login** — `POST /api/v1/auth/login/` with email + password. Response carries `access` + `refresh`. We store both in the platform keychain.
2. **Every request** — `AuthInterceptor` attaches `Authorization: Bearer <access>`.
3. **401 happens** — `AuthInterceptor` calls `POST /api/v1/auth/token/refresh/` once, atomically (parallel 401s wait on a shared `Completer`), then retries the original request with the fresh token.
4. **Refresh fails** — `TokenManager.signOut()` clears the keychain and flips `authStateProvider` to unauthenticated. GoRouter redirects to `/login` on the next frame.
5. **MFA required** — login response sets `mfa_required=true` and returns an `mfa_challenge_token`. The login controller navigates to the MFA challenge screen (not yet wired).
6. **Biometric prompt on cold start** — `TokenManager.warmFromStorage()` checks the local cache + optionally fires a `local_auth` prompt before exposing the cached token.

## Testing

Unit + widget tests live in `test/`. Integration tests live in `integration_test/` and run via Patrol.

```bash
make test                                  # unit + widget
flutter test --coverage --reporter expanded
patrol test                                # integration
```

CI runs the full matrix on every PR: format check, analyzer, custom_lint, tests with coverage, debug Android build, debug iOS build (no codesign). Coverage goal: ≥ 80 % per merge, climbing to 85 % by v1.

## Useful links

- Backend API spec: `../datasolids-backend/docs/milestone-2-health-pod.md`
- Security model: `../datasolids-backend/docs/security.md`
- Brand tokens (web): same color hex values, source of truth for the mobile palette
- Postman collection: `../datasolids-backend/docs/postman/*.json`
