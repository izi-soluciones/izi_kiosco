/// Shared helpers for the on-device E2E suite (integration_test/).
///
/// RULES FOR THIS SUITE
/// - NEVER use `tester.pumpAndSettle()`: the app never settles (looping Lottie
///   animations, Shimmer loaders, the home attract video and countdown timers
///   keep frames scheduled forever). Use [pumpUntilFound] / [pumpUntilGone].
/// - One `app.main()` per test PROCESS: main() initializes Firebase and MyApp
///   builds its router/blocs as fields, so booting twice in one process leaks
///   state. Keep ONE testWidgets per file; `flutter test integration_test`
///   launches each file as a fresh app install.
/// - Tests run against the REAL staging backend (FLAVOR=stg). Order-creating
///   tests must call [assertStagingFlavor] first so they can never run against
///   production by accident.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_kiosco/main.dart' as app;
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_category.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_method_btn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'e2e_strings.dart';

// ---------------------------------------------------------------------------
// Run configuration (passed with --dart-define at `flutter test` time)
// ---------------------------------------------------------------------------

/// Staging kiosk JWT (must contain a `contribuyente` claim). Required by every
/// authenticated test. Provision the device with demo=true so payment flows
/// never charge real money.
const e2eToken = String.fromEnvironment('E2E_TOKEN');

/// Barcode of a curated staging retail product ([a-z0-9] only — the simulated
/// scanner does not press Shift).
const e2eBarcode = String.fromEnvironment('E2E_BARCODE');

/// Display name of the product [e2eBarcode] resolves to.
const e2eBarcodeName = String.fromEnvironment('E2E_BARCODE_NAME');

/// Name of a curated option-free restaurant catalog item.
const e2eItemName = String.fromEnvironment('E2E_ITEM_NAME');

/// Catalog category holding [e2eItemName]. The order screen renders one
/// category at a time, so the category chip is tapped before searching the
/// item. Leave empty if the item is in the first (default) category.
const e2eItemCategory = String.fromEnvironment('E2E_ITEM_CATEGORY');

/// Admin PIN for the hidden home long-press. '4321' is the app's emergency
/// fallback when the device has no backend-provisioned pin.
const e2ePin = String.fromEnvironment('E2E_PIN', defaultValue: '4321');

/// Where the suite is running: 'emulator' (default), 'device' (real hardware,
/// e.g. a Sunmi kiosk) or 'ftl' (Firebase Test Lab). Hardware-dependent
/// expectations (POS banner, physical printing) are keyed off this.
const e2eTarget = String.fromEnvironment('E2E_TARGET', defaultValue: 'emulator');

/// Gate for the purchase-creating second half of the retail test.
const e2eRetailFull = bool.fromEnvironment('E2E_RETAIL_FULL');

/// Gate for wall-clock-slow tests (inactivity timer).
const e2eSlow = bool.fromEnvironment('E2E_SLOW');

const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'local');

/// Real hardware may physically print receipts when an order completes.
bool get runningOnRealHardware => e2eTarget == 'device';

/// Order-creating tests write to the backend: refuse to run outside staging.
void assertStagingFlavor() {
  expect(_flavor, 'stg',
      reason: 'This test creates real backend data. Run it ONLY against '
          'staging: --dart-define=FLAVOR=stg');
}

void assertHasToken() {
  expect(e2eToken, isNotEmpty,
      reason: 'Authenticated E2E tests need a staging kiosk JWT: '
          '--dart-define=E2E_TOKEN=<jwt>');
}

// ---------------------------------------------------------------------------
// Waiting primitives (pumpAndSettle replacements)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// ZWSP-aware text finders
//
// The izi_design_system typography (IziText.*, used by IziBtn etc.) passes all
// strings through useCorrectEllipsis(), which interleaves a ZERO-WIDTH SPACE
// (U+200B) between every character. find.text() therefore never matches
// design-system text — always use these finders instead.
// ---------------------------------------------------------------------------

/// Removes the zero-width spaces the design system injects into all text.
String stripZwsp(String s) => s.replaceAll('\u200B', '');
String _stripZwsp(String s) => stripZwsp(s);

/// Matches Text widgets whose zero-width-space-stripped content equals [text].
Finder findAppText(String text) => find.byWidgetPredicate(
    (w) => w is Text && _stripZwsp(w.data ?? '') == text,
    description: 'Text (ZWSP-normalized) == "$text"');

/// Matches Text widgets whose normalized content contains [fragment].
Finder findAppTextContaining(String fragment) => find.byWidgetPredicate(
    (w) => w is Text && _stripZwsp(w.data ?? '').contains(fragment),
    description: 'Text (ZWSP-normalized) contains "$fragment"');

/// Matches Text widgets whose normalized content equals any of [options].
Finder findAppTextAny(List<String> options) => find.byWidgetPredicate(
    (w) => w is Text && options.contains(_stripZwsp(w.data ?? '')),
    description: 'Text (ZWSP-normalized) in $options');

/// Poll-pumps until [finder] matches at least one widget. On timeout, dumps
/// the visible Text contents so the failure shows which screen was rendered.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for $finder\n'
      'Visible texts at timeout: ${_visibleTexts()}');
}

String _visibleTexts() {
  try {
    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .map(_stripZwsp)
        .where((s) => s.trim().isNotEmpty)
        .take(25)
        .toList();
    return texts.isEmpty ? '(none — is the app tree empty?)' : '$texts';
  } catch (e) {
    return '(failed to collect: $e)';
  }
}

/// Poll-pumps until ANY of [finders] matches. Returns the index of the first
/// finder that matched (useful for branching flows).
Future<int> pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 45),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    for (var i = 0; i < finders.length; i++) {
      if (finders[i].evaluate().isNotEmpty) return i;
    }
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for any of $finders\n'
      'Visible texts at timeout: ${_visibleTexts()}');
}

/// Poll-pumps until [finder] matches nothing.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for $finder to go away');
}

/// Pumps real wall-clock time without asserting anything (timers in the app
/// run in real time — integration tests cannot fast-forward them).
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------

/// Clears auth/POS prefs, optionally seeds the kiosk JWT, then launches the
/// real app. The login screen is QR-only (requires an external admin to
/// authorize the session), so seeding the token IS the automation entry path.
Future<void> bootApp(WidgetTester tester, {required bool authenticated}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('rt');
  await prefs.remove('tokenCard');
  await prefs.remove('posIp');
  await prefs.remove('posToken');
  if (authenticated) {
    assertHasToken();
    await prefs.setString('token', e2eToken); // key read by TokenUtils.getToken
  }
  // main() is `void main() async` — fire it and let the pump loops below
  // absorb the async boot (dotenv, Firebase, runApp).
  app.main();
  await tester.pump();
  // main() installs its own FlutterError.onError (Crashlytics); wrap it AFTER
  // boot to swallow errors that are environmental on a test device and would
  // otherwise fail an otherwise-passing test (image assets/network images that
  // don't decode on the emulator, and layout overflow warnings).
  _ignoreBenignErrors();
}

void _ignoreBenignErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.exceptionAsString();
    const benign = [
      'Invalid image data',
      'image codec',
      'Failed to load network image',
      'HttpException',
      'RenderFlex overflowed',
      'A RenderFlex overflowed',
      'overflowed by',
    ];
    if (benign.any(text.contains)) return;
    previous?.call(details);
  };
}

/// Boots authenticated and waits for the home screen. AuthBloc.verify() has
/// ~4s of built-in artificial delays plus five sequential API calls, hence the
/// generous timeout.
Future<void> bootToHome(WidgetTester tester) async {
  await bootApp(tester, authenticated: true);
  await pumpUntilFound(tester, find.byKey(const Key('home_start_area')),
      timeout: const Duration(seconds: 90));
}

// ---------------------------------------------------------------------------
// Interaction helpers
// ---------------------------------------------------------------------------

/// Matches Text whose normalized content equals [text] case-insensitively.
/// IziBtn renders its label via `buttonText.toUpperCase()`, so button finders
/// must ignore case.
Finder findAppTextCI(String text) => find.byWidgetPredicate(
    (w) =>
        w is Text &&
        _stripZwsp(w.data ?? '').toLowerCase() == text.toLowerCase(),
    description: 'Text (ZWSP-normalized, case-insensitive) == "$text"');

/// Taps an [IziBtn] (design-system button — tappable text, not a Material
/// button) by its visible text, optionally scoped to [within]. Case-insensitive
/// because IziBtn uppercases its label.
Future<void> tapBtn(WidgetTester tester, String text, {Finder? within}) async {
  Finder f =
      find.ancestor(of: findAppTextCI(text), matching: find.byType(IziBtn));
  if (within != null) f = find.descendant(of: within, matching: f);
  await pumpUntilFound(tester, f);
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump();
}

/// Taps the first widget matching [key] once it exists.
Future<void> tapKey(WidgetTester tester, Key key,
    {Duration timeout = const Duration(seconds: 45)}) async {
  final f = find.byKey(key);
  await pumpUntilFound(tester, f, timeout: timeout);
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump();
}

/// Enters [value] into the TextField whose hint (ZWSP-normalized) equals
/// [hint]. Returns false if no such field is on screen.
Future<bool> enterTextByHint(
    WidgetTester tester, String hint, String value) async {
  final field = find.byWidgetPredicate((w) =>
      w is TextField && stripZwsp(w.decoration?.hintText ?? '') == hint);
  if (field.evaluate().isEmpty) return false;
  await tester.enterText(field.first, value);
  await tester.pump();
  return true;
}

/// Handles the invoice-data form: fills the phone number when that field is
/// required/present (some contribuyentes reject an empty phone), then taps
/// "Proceder al pago". A no-op guard is fine when the form has no phone.
Future<void> proceedThroughInvoice(WidgetTester tester) async {
  await pumpUntilFound(tester, findAppText(S.invoiceData));
  await enterTextByHint(tester, S.phonePlaceholder, '71234567');
  await tapTappable(tester, S.proceedPayment);
}

/// Taps the nearest tappable ancestor (IziBtn / InkWell / GestureDetector) of
/// the Text [label]. Use for buttons that aren't IziBtn (e.g. the invoice
/// page's "Proceder al pago", which is a Text inside an InkWell).
Future<void> tapTappable(WidgetTester tester, String label) async {
  await pumpUntilFound(tester, findAppText(label));
  for (final type in [IziBtn, InkWell, GestureDetector]) {
    final f = find.ancestor(
        of: findAppText(label), matching: find.byType(type));
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first, warnIfMissed: false);
      await tester.pump();
      return;
    }
  }
  fail('No tappable ancestor found for "$label"');
}

/// Taps the payment-method tile ([PaymentMethodBtn]) labeled [label] on the
/// "Métodos de pago" screen (QR / Pagar en caja / Tarjeta / BreB).
Future<void> tapPaymentMethod(WidgetTester tester, String label) async {
  final tile = find.ancestor(
      of: findAppText(label), matching: find.byType(PaymentMethodBtn));
  await pumpUntilFound(tester, tile);
  await tester.tap(tile.first, warnIfMissed: false);
  await tester.pump();
}

/// Taps the [IziCard] that shares a Column with [label]. Used for the
/// eat-here/take-away chooser, where the tappable card holds only an icon and
/// the label is a non-interactive sibling BELOW the card.
Future<void> tapCardByLabel(WidgetTester tester, String label) async {
  await pumpUntilFound(tester, findAppText(label));
  final column =
      find.ancestor(of: findAppText(label), matching: find.byType(Column));
  final card =
      find.descendant(of: column.first, matching: find.byType(IziCard));
  await pumpUntilFound(tester, card, timeout: const Duration(seconds: 10));
  await tester.tap(card.first, warnIfMissed: false);
  await tester.pump();
}

/// Waits for [finder]; if it doesn't appear, drags the first [Scrollable]
/// upwards between polls (catalog lists can be longer than the screen).
Future<void> pumpUntilFoundScrolling(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) return;
    // Drag the LAST scrollable: the first is typically the horizontal
    // category chip row; the item grid comes later in the tree.
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.last, const Offset(0, -200),
          warnIfMissed: false);
    }
  }
  fail('Timed out after ${timeout.inSeconds}s waiting (with scrolling) '
      'for $finder\nVisible texts at timeout: ${_visibleTexts()}');
}

// ---------------------------------------------------------------------------
// Barcode scanner simulation
// ---------------------------------------------------------------------------

const Map<String, LogicalKeyboardKey> _charKeys = {
  '0': LogicalKeyboardKey.digit0,
  '1': LogicalKeyboardKey.digit1,
  '2': LogicalKeyboardKey.digit2,
  '3': LogicalKeyboardKey.digit3,
  '4': LogicalKeyboardKey.digit4,
  '5': LogicalKeyboardKey.digit5,
  '6': LogicalKeyboardKey.digit6,
  '7': LogicalKeyboardKey.digit7,
  '8': LogicalKeyboardKey.digit8,
  '9': LogicalKeyboardKey.digit9,
  'a': LogicalKeyboardKey.keyA,
  'b': LogicalKeyboardKey.keyB,
  'c': LogicalKeyboardKey.keyC,
  'd': LogicalKeyboardKey.keyD,
  'e': LogicalKeyboardKey.keyE,
  'f': LogicalKeyboardKey.keyF,
  'g': LogicalKeyboardKey.keyG,
  'h': LogicalKeyboardKey.keyH,
  'i': LogicalKeyboardKey.keyI,
  'j': LogicalKeyboardKey.keyJ,
  'k': LogicalKeyboardKey.keyK,
  'l': LogicalKeyboardKey.keyL,
  'm': LogicalKeyboardKey.keyM,
  'n': LogicalKeyboardKey.keyN,
  'o': LogicalKeyboardKey.keyO,
  'p': LogicalKeyboardKey.keyP,
  'q': LogicalKeyboardKey.keyQ,
  'r': LogicalKeyboardKey.keyR,
  's': LogicalKeyboardKey.keyS,
  't': LogicalKeyboardKey.keyT,
  'u': LogicalKeyboardKey.keyU,
  'v': LogicalKeyboardKey.keyV,
  'w': LogicalKeyboardKey.keyW,
  'x': LogicalKeyboardKey.keyX,
  'y': LogicalKeyboardKey.keyY,
  'z': LogicalKeyboardKey.keyZ,
};

/// Types [code] the way a USB barcode scanner does: raw key events ending in
/// Enter. The retail pages capture scans with a KeyboardListener (there is no
/// TextField, so tester.enterText cannot be used). Lowercase letters and
/// digits only — the simulator does not press Shift.
Future<void> enterBarcode(WidgetTester tester, String code) async {
  expect(code, isNotEmpty,
      reason: 'Pass --dart-define=E2E_BARCODE=<staging product barcode>');
  for (final ch in code.toLowerCase().split('')) {
    final key = _charKeys[ch];
    expect(key, isNotNull,
        reason: 'Barcode char "$ch" not simulatable; use [a-z0-9] only');
    await tester.sendKeyEvent(key!);
    await tester.pump(const Duration(milliseconds: 30));
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Composite flows shared by several tests
// ---------------------------------------------------------------------------

/// From a cold start: boots to home, opens the restaurant order flow, adds the
/// curated item and confirms the order, stopping when the payment-methods view
/// is visible. CREATES A REAL ORDER in staging — callers must have invoked
/// [assertStagingFlavor].
Future<void> placeRestaurantOrder(WidgetTester tester) async {
  expect(e2eItemName, isNotEmpty,
      reason: 'Pass --dart-define=E2E_ITEM_NAME=<option-free catalog item>');

  await bootToHome(tester);
  await tapKey(tester, const Key('home_start_area'));

  // Eat-here / take-away chooser (the tappable card holds only the icon —
  // the label is a sibling, hence tapCardByLabel).
  await pumpUntilFound(tester, findAppTextContaining(S.selectWhere),
      timeout: const Duration(seconds: 30));
  await tapCardByLabel(tester, S.eatHere);

  // The order screen renders ONE category at a time: select the item's
  // category chip first when configured. Keep this wait under the ~30s
  // kiosk inactivity timer so a failure dump captures the catalog screen
  // (not the post-inactivity home screen). The chip row is a horizontal
  // SingleChildScrollView (all chips stay in the tree even off-screen), so
  // scroll the chip into view and tap the MakeOrderCategory itself.
  if (e2eItemCategory.isNotEmpty) {
    await pumpUntilFound(tester, findAppTextContaining(e2eItemCategory),
        timeout: const Duration(seconds: 25));
    final chip = find.ancestor(
        of: findAppTextContaining(e2eItemCategory),
        matching: find.byType(MakeOrderCategory));
    await tester.ensureVisible(chip.first);
    await tester.pump();
    await tester.tap(chip.first, warnIfMissed: false);
    await tester.pump();
  }

  // Catalog loads behind a shimmer; find the curated item (scrolling if the
  // category list is long) and add it — it must be option-free, otherwise a
  // modifier modal opens instead of a direct add.
  await pumpUntilFoundScrolling(tester, findAppTextContaining(e2eItemName),
      timeout: const Duration(seconds: 60));
  await tester.tap(findAppTextContaining(e2eItemName).first,
      warnIfMissed: false);
  await tester.pump();

  // The cart summary differs per layout ("Items (n)" only exists on wide
  // screens), so use the keyed confirm button — present in every layout —
  // as the post-add marker, give the state a beat, then confirm.
  await pumpUntilFound(tester, find.byKey(const Key('order_confirm_btn')),
      timeout: const Duration(seconds: 15));
  await pumpFor(tester, const Duration(seconds: 1));
  await tapKey(tester, const Key('order_confirm_btn'));

  // Confirmation view → confirm & pay (creates the staging order).
  await tapKey(tester, const Key('confirm_and_pay_btn'));

  await proceedToPaymentMethods(tester);
}

/// Payment step order depends on the contribuyente: with facturación an
/// invoice-data page precedes the payment methods (all its fields are
/// optional). Handles both and returns once 'Métodos de pago' is visible.
Future<void> proceedToPaymentMethods(WidgetTester tester) async {
  final either = findAppTextAny([S.invoiceData, S.paymentMethods]);
  await pumpUntilFound(tester, either, timeout: const Duration(seconds: 60));

  if (findAppText(S.invoiceData).evaluate().isNotEmpty &&
      findAppText(S.paymentMethods).evaluate().isEmpty) {
    await proceedThroughInvoice(tester);
  }
  await pumpUntilFound(tester, findAppText(S.paymentMethods),
      timeout: const Duration(seconds: 30));
}
