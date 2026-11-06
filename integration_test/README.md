# E2E Tests (integration_test)

On-device end-to-end tests that drive the **real app** against the **staging
backend**. Built on Flutter's official `integration_test` framework — the
Flutter equivalent of Selenium (Selenium itself cannot automate Flutter: it
drives browser DOM, while Flutter paints its own widgets).

**Status:** a, b, c, d, e, g verified green on an Android emulator against
staging (device 76, contribuyente 28). `f` needs a **retail** device token
(the verified token is a restaurant device); `h` is opt-in (slow).

## Test matrix

| File | Scenario | Needs token | Writes to staging | Verified |
|---|---|---|---|---|
| `a_unauthenticated_login_test.dart` | Boot without token → QR login screen | No | No | ✅ |
| `b_authenticated_home_test.dart` | Seeded JWT → home screen | Yes | No | ✅ |
| `c_home_navigation_test.dart` | Home tap → order screen (restaurant or retail) | Yes | No | ✅ |
| `d_restaurant_order_flow_test.dart` | Browse catalog → cart → confirm → payment methods | Yes (restaurant) | **Yes** (order) | ✅ |
| `e_payment_demo_test.dart` | Full order + demo QR payment → success → home | Yes (restaurant, `demo=true`) | **Yes** (demo order) | ✅ |
| `f_retail_scan_test.dart` | Simulated barcode scans → cart; full purchase behind `E2E_RETAIL_FULL` | Yes (**retail**) | Only with `E2E_RETAIL_FULL` | needs retail device |
| `g_admin_pin_error_payments_test.dart` | Hidden long-press + PIN → admin error page | Yes | No | ✅ |
| `h_inactivity_timer_test.dart` | 30s idle → inactivity overlay (slow; behind `E2E_SLOW`) | Yes | No | opt-in |

One `testWidgets` per file, on purpose: `main()` initializes Firebase and the
app builds its router/blocs as fields, so the app can only boot once per
process. `flutter test integration_test` runs each file as a fresh install.

## Prerequisites

1. **Staging kiosk devices** (backend-provisioned):
   - Restaurant device: `isRetail=false`, `demo=true`, `video=null`.
   - Retail device: `isRetail=true`, `isRetailBarcode=true`, `demo=true`.
   - `demo=true` is what routes payments to the demo endpoints — **no real
     charges**. There is no client-side override.
2. **Staging JWTs** for those devices (long-lived, must contain the
   `contribuyente` claim). The QR login cannot be automated (an external admin
   session must authorize it), so tests seed the JWT into SharedPreferences.
3. **Curated catalog data**: one option-free restaurant item
   (`E2E_ITEM_NAME`), one retail barcode `[a-z0-9]` (`E2E_BARCODE`).
4. SSH access to the private `izi_design_system` repo (needed for any build).

## Running

### Local emulator or physical device (incl. Sunmi kiosks via adb)

```bash
# No credentials needed (harness smoke test):
fvm flutter test integration_test/a_unauthenticated_login_test.dart \
  -d <device-id> --dart-define=FLAVOR=stg

# Verified green set (restaurant device):
fvm flutter test \
  integration_test/b_authenticated_home_test.dart \
  integration_test/c_home_navigation_test.dart \
  integration_test/d_restaurant_order_flow_test.dart \
  integration_test/e_payment_demo_test.dart \
  integration_test/g_admin_pin_error_payments_test.dart \
  -d <device-id> \
  --dart-define=FLAVOR=stg \
  --dart-define=E2E_TARGET=emulator \               # emulator | device | ftl
  --dart-define=E2E_TOKEN="<staging kiosk JWT>" \
  --dart-define=E2E_ITEM_NAME="Coca Cola 500 ml" \  # an OPTION-FREE catalog item
  --dart-define=E2E_ITEM_CATEGORY="Bebidas" \       # its category chip (order screen shows one category at a time)
  --dart-define=E2E_PIN=4321

# Retail device (test f):
fvm flutter test integration_test/f_retail_scan_test.dart \
  -d <device-id> --dart-define=FLAVOR=stg \
  --dart-define=E2E_TOKEN="<retail kiosk JWT>" \
  --dart-define=E2E_BARCODE=7791234567890 \
  --dart-define=E2E_BARCODE_NAME="Coca Cola 600ml"
```

Optional gates: `--dart-define=E2E_RETAIL_FULL=true` (retail purchase half),
`--dart-define=E2E_SLOW=true` (inactivity test). `E2E_ITEM_CATEGORY` is
optional — omit it if the item is in the first category shown.

On a **Sunmi kiosk** (`E2E_TARGET=device`): enable developer options + USB
debugging, connect adb, same command. Completed orders WILL physically print.

### Firebase Test Lab (`E2E_TARGET=ftl`)

The androidTest wrapper (`android/app/src/androidTest/.../MainActivityTest.java`)
and gradle instrumentation config are already in place.

```bash
cd android
./gradlew app:assembleDebug app:assembleDebugAndroidTest \
  -Ptarget=$(pwd)/../integration_test/b_authenticated_home_test.dart \
  -Pdart-defines="$(for k in FLAVOR=stg E2E_TARGET=ftl E2E_TOKEN=$E2E_TOKEN; do printf '%s' "$k" | base64; printf ','; done | sed 's/,$//')"
cd ..
gcloud firebase test android run --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=panther,version=33 --timeout 10m
```

Note: `-Pdart-defines` takes base64-encoded, comma-separated `KEY=VALUE`
pairs. Run one gcloud invocation per test file (each is one app session).

## Writing new tests — house rules

- **Never `pumpAndSettle()`** — looping animations (Lottie, shimmer, video,
  countdowns) mean the app never settles. Use `pumpUntilFound`/`pumpUntilGone`
  from `helpers/e2e_helpers.dart`.
- **Never `find.text()` for app UI text** — the design system interleaves
  zero-width spaces (U+200B) into every string (`useCorrectEllipsis()`), so
  plain text finders silently match nothing. Use `findAppText` /
  `findAppTextContaining` / `findAppTextAny` (ZWSP-normalized) or Widget Keys.
- Spanish UI strings live in `helpers/e2e_strings.dart`, mirrored verbatim
  from `assets/translations/es.json` (single-locale app).
- Stable Widget Keys available: `home_start_area`, `home_admin_corner`,
  `order_confirm_btn`, `confirm_and_pay_btn`, `demo_proceed_btn`,
  `retail_finish_btn`.
- Barcode scanning is simulated with raw key events (`enterBarcode`) — the
  retail pages use a KeyboardListener, not a TextField.
- Any test that creates backend data must call `assertStagingFlavor()` first.
- Every file must pass standalone and in any order; no cross-file state.

## Known environment quirks

- Emulator images occasionally break activity resolution right after an
  install (`Error type 3: Activity class does not exist` despite a correct
  APK): **reboot the emulator** (`adb reboot`) and it resolves.
- Emulators need ≥ ~500MB free on `/data` to install the debug APK.
- On emulators/FTL there is no POS on the LAN and no printer: the home screen
  may show the yellow "POS no conectado" banner (tests tolerate it) and print
  calls no-op.
