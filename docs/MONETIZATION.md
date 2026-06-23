# Monetization (Ads + In-App Purchases)

## Current state: demo / mock only

The store UI is fully built and runs against **no-op mock services**, so it
demos end-to-end without any paid-SDK dependencies:

- `lib/core/services/ad_service_simple.dart` — `MockAdService` (no real ads;
  `AdBannerWidget` shows a placeholder).
- `lib/core/services/purchase_service_simple.dart` — `MockPurchaseService`
  returns a fixed catalog and always "succeeds".

`google_mobile_ads` and `in_app_purchase` are **intentionally not** in
`pubspec.yaml`.

## Why real monetization wasn't enabled in this pass

It is deliberately deferred, not forgotten:

1. **External accounts required** — AdMob app/ad-unit IDs, and App Store
   Connect / Play Console product definitions. None exist yet.
2. **Mobile platforms required** — both SDKs are mobile-first and need the
   native config that only lands with `flutterfire configure` + store setup
   (see `docs/MOBILE_SETUP.md`).
3. **Not headless-verifiable** — purchase and ad flows can't be exercised in
   `flutter test`; shipping them unverified risks a broken paid surface, which
   is worse than a clean demo.
4. **Project ethos** — the app targets zero ongoing cost on the Firebase free
   tier; ads/IAP are a post-launch concern.

## Integration path when ready

### Ads (google_mobile_ads)
1. `flutter pub add google_mobile_ads` and create an AdMob account + ad units.
2. Add the app id to `AndroidManifest.xml` and `Info.plist`.
3. Implement `AdServiceImpl` (real banner/interstitial/rewarded) behind the
   existing `AdService` interface; swap it in `service_locator.dart` for the
   non-mock branch. Keep `MockAdService` for tests.
4. Restore a real `AdBannerWidget` (the previous package-based version was
   removed; it can be rebuilt from the `AdService.createBanner` pattern).

### In-app purchases (in_app_purchase)
1. `flutter pub add in_app_purchase` and define products (`taskmaster_pro`,
   `task_pack_basic|premium|ultimate`) in both stores.
2. Implement `PurchaseServiceImpl` against the real `InAppPurchase.instance`
   behind the existing `PurchaseService` interface; map store `ProductDetails`
   to the app's lightweight `ProductDetails` (or adopt the package type).
3. Add **server-side receipt verification** (a Cloud Function) before granting
   entitlements — never trust the client.
4. Persist entitlements (e.g. a `pro` flag on the user doc) and gate features
   (remove ads, unlock packs) on it.

The UI in `lib/features/store/` already renders the catalog and a purchase
flow, so enabling real purchases is mostly implementing the two `*Impl`
classes and store/console configuration.
