# Layout Sweep Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic 320/360/412 dp by 1.0/1.3 text-scale sweep for every merchant and partner UI surface, fix every in-scope layout exception, and document residual device risk.

**Architecture:** A table-driven widget-test harness owns viewport setup, text scaling, themes, provider overrides, and exception assertions. Public view widgets cover distinct visual states directly, while provider-backed top-level screens prove their real composition; fixes stay local to the failing merchant or partner widget.

**Tech Stack:** Flutter 3, Dart 3.9, `flutter_test`, Riverpod 3, `intl`

## Global Constraints

- Required widths are exactly 320, 360, and 412 dp at 800 dp height and device pixel ratio 1.
- Required text scales are exactly 1.0 and 1.3 through `TextScaler.linear`.
- Call `initializeDateFormatting('id_ID')` from `setUpAll`.
- Use `tester.view.physicalSize`; never use `binding.setSurfaceSize`.
- Do not change colors, font sizes, feature behavior, data logic, or dependencies.
- Preserve the partner 90 sp primary number and 140 dp primary button.
- Do not modify `lib/features/consumer/`, `lib/core/`, or `lib/shared/`.
- Report any `core`/`shared` source failure instead of fixing it.
- Baseline on 1 September 2026 is clean analyze and 86 passing tests.

---

### Task 1: Deterministic Layout Sweep Harness and Fixtures

**Files:**
- Create: `test/layout_sweep_test.dart`

**Interfaces:**
- Consumes: merchant and partner public screen/widget constructors, Riverpod provider overrides, Dark Glass and Plain themes.
- Produces: `_sweepSurface(String, Widget Function(double), ThemeData)` registering six widget tests per surface; deterministic `_merchant`, `_partner`, `_forecast`, `_report`, `_listing`, `_waste`, and `_nearbyWaste` fixtures.

- [ ] **Step 1: Add the required locale initialization and layout matrix**

```dart
const _widths = <double>[320, 360, 412];
const _textScales = <double>[1, 1.3];

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));
  // Surface registrations follow in Tasks 2 and 3.
}
```

- [ ] **Step 2: Add the reusable viewport and theme harness**

```dart
Future<void> _pumpSurface(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required ThemeData theme,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: appChild!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}
```

- [ ] **Step 3: Add immutable fixtures with long realistic labels and values**

Create one complete instance of each model needed by the public surfaces. Use a
long merchant name, a long listing name, a seven-row forecast history, a large
Rupiah amount, a multi-sentence ESG narrative, a long pickup address, and both
B2C/B2B triage results. Keep all dates fixed in August/September 2026 and avoid
network image URLs by using `imageUrl: null` or an empty string.

- [ ] **Step 4: Format and compile the harness**

Run: `dart format test/layout_sweep_test.dart`

Run: `flutter test --no-pub test/layout_sweep_test.dart`

Expected: the file compiles; any failures are concrete layout or plugin
exceptions labeled with surface, width, and text scale.

- [ ] **Step 5: Commit the harness foundation**

```powershell
git add -- test/layout_sweep_test.dart
git commit -m "test: add responsive layout sweep harness"
```

### Task 2: Cover and Harden Merchant Surfaces

**Files:**
- Modify: `test/layout_sweep_test.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/merchant_home_screen.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/merchant_inventory_screen.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/merchant_scan_screen.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/merchant_esg_screen.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/widgets/merchant_forecast_card.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/widgets/merchant_inventory_widgets.dart`
- Modify only when its case fails: `lib/features/merchant/presentation/widgets/merchant_esg_widgets.dart`

**Interfaces:**
- Consumes: `_pumpSurface`, merchant fixtures, `currentMerchantProvider`, `merchantHomeProvider`, `merchantListingsProvider`, `merchantWasteProvider`, and `merchantEsgProvider`.
- Produces: six passing cases for each merchant top-level screen and each public merchant view widget, including B2C/B2B and saved/unsaved variants.

- [ ] **Step 1: Register direct public-widget cases**

Register `MerchantForecastCard`, `FoodSafetyResultCard` for both B2C and B2B,
`MerchantListingList` for populated and empty data, and
`MerchantEsgReportView` for saved and unsaved reports. Wrap intrinsically tall
standalone cards in a vertical `SingleChildScrollView`; do not wrap real screen
widgets that already own their scrolling.

- [ ] **Step 2: Register provider-backed screen cases**

Use a `ProviderScope` child with exact provider overrides:

```dart
ProviderScope(
  overrides: [
    currentMerchantProvider.overrideWith((ref) async => _merchant),
    merchantHomeProvider(
      _merchant.id,
    ).overrideWith((ref) async => _merchantHomeData),
  ],
  child: const MerchantHomeScreen(),
)
```

Apply the same pattern to `MerchantInventoryScreen` with listing/waste stream
overrides and `MerchantEsgScreen` with an ESG override. Render
`MerchantScanScreen` without triggering scan/manual-code callbacks so the
scanner shell and lower action area are still constrained at all six sizes.

- [ ] **Step 3: Run merchant cases and record exact failures**

Run: `flutter test --no-pub test/layout_sweep_test.dart --plain-name merchant`

Expected before fixes: every emitted `RenderFlex overflowed by N pixels` line
identifies its source file, direction, width, and scale. Record those exact
values for `H-HANDOFF.md` before editing source.

- [ ] **Step 4: Apply the smallest allowed fix to each merchant failure**

For a `Row`, constrain its text-bearing child with `Expanded` or `Flexible`.
For a label, use `maxLines` and `TextOverflow.ellipsis`. For an amount or other
indivisible display value, preserve its font style and wrap it in:

```dart
FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: Text(value, maxLines: 1, style: existingStyle),
)
```

Use vertical `SingleChildScrollView` only for a non-scrollable column whose
height exceeds 800 dp. Do not edit `core` or `shared` when a stack trace points
there; add the finding to the handoff notes instead.

- [ ] **Step 5: Re-run merchant cases after each source edit**

Run: `flutter test --no-pub test/layout_sweep_test.dart --plain-name merchant`

Expected: all merchant matrix cases pass with zero exception.

- [ ] **Step 6: Run the full regression gates**

Run: `flutter analyze --no-pub`

Expected: `No issues found!`

Run: `flutter test --no-pub`

Expected: all tests pass and the total is at least 86.

- [ ] **Step 7: Commit merchant hardening**

```powershell
git add -- test/layout_sweep_test.dart lib/features/merchant
git commit -m "fix: harden merchant layouts for phone widths"
```

### Task 3: Cover and Harden Partner Surfaces

**Files:**
- Modify: `test/layout_sweep_test.dart`
- Modify only when its case fails: `lib/features/partner/presentation/partner_home_screen.dart`
- Modify only when its case fails: `lib/features/partner/presentation/partner_riwayat_screen.dart`
- Modify only when its case fails: `lib/features/partner/presentation/partner_langganan_screen.dart`
- Modify only when its case fails: `lib/features/partner/presentation/widgets/partner_plain_widgets.dart`

**Interfaces:**
- Consumes: `_pumpSurface`, partner fixtures, `currentProfileProvider`, `currentPartnerProvider`, `partnerNearbyWasteProvider`, and `partnerHistoryProvider`.
- Produces: six passing cases for every partner screen and public view/widget, while preserving the 90 sp number and 140 dp button contracts.

- [ ] **Step 1: Register direct public-view cases**

Register `PartnerAvailableView`, both matched and picked-up
`PartnerJourneyView` variants, `PartnerEmptyView`, `PartnerWasteMapView`,
`PartnerLoadError`, populated and empty `PartnerHistoryView`, active and
inactive `PartnerSubscriptionView`, `PartnerPrimaryButton`,
`PartnerOutlineButton`, `PartnerSectionCard`, `PartnerScreenTitle`, and
`PartnerStatTile`.

- [ ] **Step 2: Register provider-backed partner screen cases**

Render `PartnerHomeScreen` with profile, partner, and nearby-waste overrides;
render `PartnerRiwayatScreen` with partner and history overrides; render
`PartnerLanggananScreen` with a partner override. Do not tap callbacks that
write repository state because direct journey/subscription views cover their
post-action layouts.

- [ ] **Step 3: Add invariant assertions for protected dimensions**

Within the 320 dp, scale 1.3 cases, assert that the source `Text` for the main
weight still has `fontSize == 90`, and that the outer
`PartnerPrimaryButton` container remains 140 dp high. Scaling may happen only
through a surrounding `FittedBox`, not by mutating these design values.

- [ ] **Step 4: Run partner cases and record exact failures**

Run: `flutter test --no-pub test/layout_sweep_test.dart --plain-name partner`

Expected before fixes: each failure contains the surface, width, scale, source
file, overflow direction, and pixel count needed for the handoff.

- [ ] **Step 5: Apply the smallest allowed partner fix**

Use `Expanded`/`Flexible`, label ellipsis, and `FittedBox(scaleDown)` in that
order. Keep Plain theme semantics, uppercase copy, 90 sp number, 140 dp button,
and the absence of horizontal scrolling, modal UI, and new visual effects.

- [ ] **Step 6: Re-run partner and full regression gates**

Run: `flutter test --no-pub test/layout_sweep_test.dart --plain-name partner`

Run: `flutter analyze --no-pub`

Run: `flutter test --no-pub`

Expected: zero layout exceptions, clean analyze, and at least 86 total tests.

- [ ] **Step 7: Commit partner hardening**

```powershell
git add -- test/layout_sweep_test.dart lib/features/partner
git commit -m "fix: harden partner layouts for phone widths"
```

### Task 4: Final Audit and Agent H Handoff

**Files:**
- Create: `docs/06-agent-briefs/H-HANDOFF.md`
- Verify: `test/layout_sweep_test.dart`

**Interfaces:**
- Consumes: recorded failing output, final passing output, Git diff, and test counts.
- Produces: auditable completion record matching all five Prompt H handoff sections.

- [ ] **Step 1: Format every touched Dart file**

Run `dart format` with an explicit list consisting only of
`test/layout_sweep_test.dart` and the in-scope merchant/partner Dart files
actually changed.

- [ ] **Step 2: Run final required commands without filtering**

Run: `flutter analyze --no-pub`

Expected: `No issues found!`

Run: `flutter test --no-pub`

Expected: all tests pass; total is at least 86 and therefore at least the
required 74.

- [ ] **Step 3: Audit matrix and forbidden-path changes**

Run: `rg -n "320|360|412|TextScaler.linear|initializeDateFormatting|physicalSize|devicePixelRatio" test/layout_sweep_test.dart`

Run: `rg -n "setSurfaceSize" test/layout_sweep_test.dart`

Expected: every required value and reset is present; `setSurfaceSize` has no
matches.

Run: `git diff --name-only c44d115..HEAD`

Expected: no source paths under `lib/features/consumer`, `lib/core`, or
`lib/shared`.

- [ ] **Step 4: Write the handoff with measured evidence**

Include: every original overflow with file/line/width/pixels; every fix; any
unmodified `core`/`shared` finding; the worst passing condition `320 dp at text
scale 1.3`; current analyze/test totals; and physical-device risks covering
font rasterization, system insets, keyboard, camera preview, map tiles, and
sunlight/readability.

- [ ] **Step 5: Self-review handoff and diff**

Run: `rg -n "TBD|TODO|belum dihitung|isi nanti" docs/06-agent-briefs/H-HANDOFF.md`

Expected: no placeholders.

Run: `git diff --check`

Expected: no whitespace errors.

- [ ] **Step 6: Commit final evidence**

```powershell
git add -- docs/06-agent-briefs/H-HANDOFF.md test/layout_sweep_test.dart lib/features/merchant lib/features/partner
git commit -m "docs: hand off layout hardening results"
```
