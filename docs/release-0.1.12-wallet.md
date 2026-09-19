# Wallet display hotfix: 0.1.12 (14)

The constant `Entrance(child: _BalanceCard())` subtree read mutable global
session values without rebuilding after wallet refresh. Transactions rebuilt,
but the balance card could retain its initial zero values and disabled button.

The card now receives available balance, pending balance, total earned and
minimum withdrawal as explicit immutable inputs from the session listener.
No database, ledger, authorization, or financial calculation was changed.

Verification: 11 targeted tests passed (widget balance refresh in both
directions, button eligibility, wallet refresh, repository reads and withdrawal
validation). Targeted Dart analysis passed with no issues. The widget regression
test uses mocked data, not a physical device or a production account.

Android bundle uses production backend and Firebase flags and the existing
release signing configuration. Store upload/review and physical-device smoke
test remain separate release gates. The full existing suite was not rerun for
this hotfix; do not interpret targeted tests as full release certification.

Artifact: `release/lugta-google-play-0.1.12+14.aab` (versionCode 14).
SHA-256: `81BB1656A02E81A395C4CF9E421483945E576E8B0293C56EEF47A91286625B98`.
Bundletool validation completed successfully. Jarsigner reports `jar verified`;
upload certificate SHA-256 matches the previous release (743911D6...F9A75).
Jarsigner also reports the self-signed certificate/no timestamp and ZIP manifest
ordering/JarInputStream warnings; Google Play accepted and processed the bundle.

Google Play submission (2026-09-19): uploaded version 14 (0.1.12) to the
production track as `Lugta 0.1.12`, with full rollout selected and existing
country availability unchanged. Device compatibility is unchanged. The only
release validation warning concerned increased download size (17.6 MB for new
installs; 8.75 MB for updates); there were no blocking validation errors.
Submitted the one production release change. Publishing overview now shows
`Changes in review`; quick checks are still running and the console states
review proceeds after those checks succeed. Managed publishing remains off.
This is submission confirmation, not confirmation of approval or availability
to users. Physical-device smoke testing remains unperformed.

Console: https://play.google.com/console/u/0/developers/5086523005220829620/app/4974729989277563901/publishing
