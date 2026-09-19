# Automated Tests — izi_kiosco

This document describes the automated test suite added on branch
`feature/eb/#86e263zuf-pruebas-automatizadas`, what it covers, how to run it,
and what remains as follow-up work.

## Running the tests

The project uses FVM (Flutter `3.38.2`, pinned in `.fvmrc`).

```bash
fvm flutter pub get
fvm flutter test                       # run everything
fvm flutter test test/domain/models    # run one folder
fvm flutter test --coverage            # generate coverage/lcov.info
```

Current status: **220 tests, all green**, across 26 test files.

## Test dependencies added

`pubspec.yaml` `dev_dependencies`:

- `bloc_test` — deterministic BLoC/Cubit state-sequence assertions.
- `mocktail` — mocking repositories (no code generation).

## Layout

Tests mirror `lib/`:

```
test/
  helpers/mocks.dart                 # shared mocktail repo mocks + fixtures
  data/local/                        # SharedPreferences-backed storage
  data/utils/                        # token/business/user utils
  domain/blocs/                      # Cubit/BLoC behavior
  domain/dto/                        # DTO toJson
  domain/models/                     # model fromJson/toJson/getters
  domain/strategies/                 # tax strategies + factory
  domain/utils/                      # pure helpers (calc, dates, print parsing)
  ui/utils/                          # money formatter
```

## Coverage by area

| Area | File(s) | What is verified |
|------|---------|------------------|
| Money math | `domain/utils/calc_utils_test.dart` | `Calc` decimal-safe add/sub/mul/div, `roundConservador` banker-style rounding, `roundCeil` |
| Tax strategies | `domain/strategies/taxes_strategy_test.dart` | Factory selection (BO/CO/Default), CO per-item tax math (percentage + fixed), BO economic-activity guard, strategy metadata |
| Dates | `domain/utils/date_formatter_test.dart` | All `dateFormat` variants, `changeFormatter`, `getDateFactorChart` |
| Money format | `ui/utils/money_formatter_test.dart` | Bolivian dot/comma formatting, fixed-decimal path, `reduce`, `symbioticFormat` |
| Form inputs | `domain/utils/input_obj_test.dart` | `InputObj` change/validate/copyWith + equality |
| Print parsing | `domain/utils/print_utils_test.dart` | `IziPrintItem.fromJson`/`listFromJson` for every element type + defaults, `String.capitalize` |
| Models | `domain/models/*_test.dart` | `CardPayment` retry classification, `PosPaymentResult`, `Modulos`, `Currency`, `Payment`, `Customer`, `User`, `Login*`, `Item` (price-list filtering, `nombreMostrar`, `toJson`), `Charge` (qr url vs base64, nested token), `Room` (`$numberDecimal`), `SaleLink` |
| DTOs | `domain/dto/dto_test.dart` | `AddKioskDto`, `PaidChargeDto`, `NewSaleLinkDto`, `FiltersComanda`, `InternalMovementDto` |
| Storage | `data/utils/**`, `data/local/**` | `TokenUtils`, `BusinessUtils`, `UserUtils`, `LocalStorage*` round trips (mocked `SharedPreferences`); AES credential encryption |
| HTTP repositories | `data/repositories/*_http_test.dart` | `PosRepositoryHttp`, `AuthRepositoryHttp`, `BusinessRepositoryHttp`, `ComandaRepositoryHttp` (Dio-based methods): endpoint paths, query/body payloads, response parsing, non-200 error propagation — via a mocked `DioClient` |
| BLoCs | `domain/blocs/*_test.dart` | `PosConfigurationBloc`, `AddKioskBloc`, `MakeOrderRetailBloc` (full happy + error paths), `MakeOrderBloc` cart logic, `PageUtilsBloc` UI state |

## Repository testability seam

The `*RepositoryHttp` classes used to construct `DioClient()` inline, which made
the network layer impossible to mock. Each now takes an **optional** injected
client:

```dart
AuthRepositoryHttp({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();
```

All production call sites use the no-arg form, so behavior is unchanged; tests
pass a `MockDioClient` (see `test/helpers/mocks.dart`) and stub
`get`/`post`/`put`. This is the only production change made for testing.

## Bugs / observations surfaced while writing tests

These are pinned by tests that document current behavior (see the referenced
tests) — they are candidates for a follow-up fix, not fixed here:

1. **`LocalStorageRoom.deleteRoom()` removes the wrong key** — it calls
   `prefs.remove("lsc")` (the credentials key) instead of `"room"`, so it never
   deletes the stored room and instead wipes saved credentials. Pinned by
   `test/data/local/local_storage_test.dart`.
2. **`Item.fromJson` id fallback** — `id: json["id"] ?? 0` assigns an `int` to a
   `String` field when `id` is absent, which throws at runtime. Tests always
   provide an `id`; a missing-id payload would crash.
3. **`ResponsiveUtils.isLg()`** uses `width > md` where it likely means
   `width > mdLg` (overlaps `isMd`/`isMdLg`).
4. **`String.capitalize()`** throws `RangeError` on an empty string (no bounds
   check).
5. **`LocalStorageCardErrors`** has no purge/clear method; the list grows
   unbounded.
6. **`Comanda.fromJson` crashes on missing dates** — `fecha`/`creado` are read
   via `DateTime.tryParse(json["..."])` with no null guard, so a payload
   missing either key throws `type 'Null' is not a subtype of type 'String'`
   instead of falling back to `DateTime.now()`. Surfaced by the comanda
   repository tests (which supply the dates to work around it).

## Not yet covered (follow-up work)

- **HTTP repositories — raw `http` paths**: the card-payment/Izify methods in
  `ComandaRepositoryHttp` (`callCardPaymentIzify`, `pollIzifyPaymentStatus`) use
  the `http` package directly rather than `DioClient`, so they are not covered
  by the `MockDioClient` seam. They would need an injected `http.Client`.
- **`SocketRepository`**: uses `socket_io_client` directly; needs a socket
  abstraction or integration test harness.
- **Side-effect-heavy BLoCs**: `PaymentBloc`, `AuthBloc`, `HomeBloc`,
  `LoginBloc`, `PosConfigBloc`. These drive real `Timer`s / periodic streams,
  card-terminal HTTP, WebSockets, printing (platform channels) and static
  `TokenUtils`/printing calls. They need seams (injected clock/timers, an
  injected printer, an HTTP client) before they can be unit-tested reliably.
  Their pure/synchronous handlers are the tractable first targets.
- **Widget/UI tests** (`lib/ui/pages`, `modals`, `general`): none yet. Most
  screens depend on `easy_localization`, `izi_design_system`, env/dotenv and
  provided BLoCs; they would need a test harness that pumps a localized,
  BLoC-provided `MaterialApp`.
- **`lib/data/repositories/auth/auth_repository_test.dart`**: this is a stub
  `AuthRepository` implementation living under `lib/` (not a real test). It is
  not executed by `flutter test`. Consider moving it under `test/` as a fake or
  removing it, as the `_test.dart` name is misleading.
