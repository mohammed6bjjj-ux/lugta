# Mobile source snapshot — 2026-09-18

This review-branch snapshot includes the existing storefront work, Lugta assistant entry in My Account, and product-link handling. It is not a store release and does not include signing material, API credentials, or release binaries.

The admin and Supabase server code live in the separate parent workspace and are not part of this mobile repository. The assistant requires its authenticated server endpoint; model-provider keys must remain server-side.

## Verification

- Full `flutter analyze`: passed, no issues.
- Full `flutter test --reporter compact`: 769 passed, 8 failed; exit code 1. This snapshot must not be treated as fully green.
- Observed failures include the full clothing product golden comparison (2.19% difference) and the clothing cart configurator test (missing widget at `ensureVisible`, test line 120). The complete set of eight failures requires follow-up; golden baselines were not regenerated to conceal failures.
- Focused assistant/profile and product-link tests passed in the preceding verification runs.
- Staged-file credential-pattern scan and `git diff --cached --check`: passed before upload. A pattern scan is not a guarantee against every possible secret.
- iOS domain association and Apple CDN responses were checked; no physical iPhone verification or new iOS binary is included in this upload.

Uploaded to a separate `codex/` review branch, leaving `main` unchanged.
