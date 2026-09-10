# Lugta 0.1.11 (13)

Release preparation: 2026-09-09. Package: `lugta.nawl.com`.

## Changes included

- Registration/login interruption recovery and duplicate-submit protection.
- Home previews of up to six products per category and navigation to the full catalog.
- Clothing size selection for products that have structured size options.
- Android OS-managed product media downloads, deduplication, and network/cache improvements.
- Pending/released wallet activity presentation and refresh on wallet notifications.
- Delivery quote and referral reward presentation compatible with additive v2 APIs.

## Backend compatibility

This mobile release does not deploy database migrations or change reward policy.
Delivery quoting falls back from `quote_delivery_fee_wholesale_v2` to
`quote_delivery_fee_wholesale` when the new function does not exist. Referral
summaries similarly retain the existing endpoint. Missing-function fallbacks do
not suppress network/authorization errors in delivery quoting or registration.
The configurable-rewards migration remains a separate rollout; do not assume
that this release alone activates its settings or new reward kinds.

## Verification

- Full `flutter analyze`: no issues.
- Full `flutter test`: 599 tests passed.
- Signed production `flutter build appbundle --release
  --dart-define=APP_BACKEND=supabase --dart-define=APP_FCM_ENABLED=true` succeeded.
- Bundletool 1.18.3 validation passed; version 13 / 0.1.11, min SDK 24, target 36.
- Upload certificate SHA-256 matches the previous production bundle:
  `74:39:11:D6:B7:AA:65:DE:06:2D:46:1F:25:F5:1B:6A:05:DC:A3:88:5F:77:8B:50:C8:65:FC:46:F6:DF:9A:75`.
- Bundle config is `PAGE_ALIGNMENT_16K`; all ARM64/x86_64 ELF LOAD segments
  align to at least 16 KB; a generated universal test APK passes `zipalign -c -P 16 4`.
  That temporary APK is debug-signed for alignment checking only, not distributed.
- Release has no debug flag, disables Android backup and cleartext traffic.
- No physical-device end-to-end test was performed for this release.

## Artifact

Local, excluded from Git: `release/lugta-google-play-0.1.11+13.aab`.

SHA-256: `EC1D31F9A225350F9B990A3E2E538E8B728981442FFC35594833F0F9B35C9A1F`.

## Google Play

Uploaded successfully to production release `Lugta 0.1.11` (release 4).
Saved with full rollout to the existing targeted countries and explicitly sent
for review. Play Console confirms **Changes in review**, with automatic quick
checks still running before handoff to review. Managed publishing remains off;
publication depends on successful checks and Google's approval. This is not a
claim that the update is already available to users.
