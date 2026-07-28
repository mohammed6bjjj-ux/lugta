# Google Play release checklist — Luqta

Last audited: 28 July 2026

Package: `lugta.nawl.com`

## Build and technical requirements

- Upload an Android App Bundle (`.aab`), not the universal APK.
- Version `0.1.8+10` uses `compileSdk 36`, `targetSdk 36`, AGP 9, and NDK
  `28.2.13676358`.
- The release task fails if `android/key.properties` or its private upload
  keystore is missing. It never falls back to Android's public debug key.
- Release shrinking and resource shrinking are enabled.
- The manifest allows cleartext HTTP neither globally nor through a custom
  network-security exception.
- Android backup is disabled and the backup/data-extraction rules exclude app
  data.
- Production permission list:
  - `INTERNET`
  - `POST_NOTIFICATIONS`
  - `WRITE_EXTERNAL_STORAGE` only up to Android 9 / API 28, used when the user
    explicitly saves product media. Android 10+ uses scoped `MediaStore`.
- No location, contacts, camera, microphone, SMS, call-log, broad photo
  library, exact-alarm, accessibility, VPN, or package-install permission is
  requested.
- Verify every final bundle with:
  - `bundletool dump config` → `PAGE_ALIGNMENT_16K`
  - `zipalign -c -P 16 -v 4` on a generated release APK
  - ELF `LOAD` segments for every ARM64/x86_64 library → `2**14` or greater
  - APK contains `arm64-v8a` (64-bit)

## Public policy URLs

Use the existing HTTPS legal site:

- Privacy policy:
  `https://lugta.nawl.net/privacy/`
- Account deletion:
  `https://lugta.nawl.net/delete-account/`

The app already provides the in-app path:
Account → Settings → Delete account.

## Play Console — App content

### Privacy policy

Enter the public privacy URL above.

### App access

Select **All or some functionality is restricted** and provide a permanent,
reusable reviewer account in English. The account must:

- already be approved;
- not depend on a one-time WhatsApp code;
- remain valid throughout review;
- expose catalogue, order creation, orders, wallet, withdrawal destination,
  complaints, settings, privacy, and deletion screens.

Do not commit the reviewer password to this repository.

### Ads

Select **No, my app does not contain ads**. Update this answer before adding
any ad SDK or paid native-ad placement.

### Target audience and content

- Target age: **18 and over**.
- The app and legal terms must continue to prevent deliberate accounts for
  minors.
- Complete the IARC content-rating questionnaire truthfully.
- App category: **Business** (or Shopping if the store listing is repositioned
  primarily for retail buyers).
- This is not a news, health, government, or dating app.

### Account deletion

- Select that accounts can be created in the app.
- Select that users can request deletion in the app.
- Enter the public account-deletion URL above.
- State that transaction records can be retained for accounting, tax, dispute,
  and fraud-prevention obligations for up to six years.

### Financial features

Complete the declaration for every testing or production release. Luqta does
not lend, offer credit, bank, hold cryptocurrency, trade assets, or provide a
consumer wallet. The in-app balance is an operational earnings ledger and
payout destination for sellers. Review the current form wording:

- If the form treats seller earnings withdrawal as a financial feature, choose
  **Other** and describe it exactly as an internal commerce earnings payout.
- Otherwise choose **My app doesn't provide any financial features**.

Never select mobile wallet or money transfer merely because the user enters a
Zain Cash/SuperQi destination; Luqta does not provide those wallet services.

## Data safety draft

This is a disclosure draft; reconcile it with every backend and provider
contract immediately before submission.

### Security practices

- Data is encrypted in transit: **Yes**.
- Users can request data deletion: **Yes**.
- Independent security review: **No**, unless one is actually completed.

### Data collected

| Google category | App data | Purpose |
| --- | --- | --- |
| Personal info — Name | account and customer names | account management, order fulfilment |
| Personal info — Phone number | user and customer phones | authentication, support, delivery |
| Personal info — Address | customer delivery address/governorate | order fulfilment |
| Personal info — User IDs | Supabase account ID | account management, security |
| Financial info — Purchase history | order history and values | commerce, earnings, support |
| Financial info — Other | payout provider, account holder and destination number | seller payouts |
| App activity — App interactions | favourites, alerts, notification state | app functionality |
| App activity — Other user-generated content | complaint/support text | support and dispute handling |
| Device or other IDs | random installation ID and FCM token | security and notifications |
| App info/performance | version, OS and limited reliability/security events | diagnostics and security |

Passwords are processed by the authentication provider and must never be
available to staff as plaintext. Temporary OTP codes are not retained as a
permanent credential.

### Data shared / service-provider transfers

- Supabase: authentication, database, storage, and backend operations.
- Google Firebase Cloud Messaging: device token and notification delivery.
- SMS.to and WhatsApp/Meta: phone number and temporary WhatsApp verification.
- Delivery providers: customer name, phone, address, and order contents.
- Selected payout provider: payout destination and transfer details.

Google's form has specific exclusions for processors/service providers. Mark
“shared” according to the actual contracts and the form's current definition;
do not omit a transfer merely because an SDK performs it.

## Store listing and release declarations

- App name: `لقطة - Luqta`
- Short description and full description must accurately explain that the app
  is a seller/reseller commerce and order-management service in Iraq.
- Screenshots must show the current build and must not promise unavailable
  features, guaranteed income, guaranteed delivery times, rankings, or awards.
- Support contact and developer contact must be active.
- Complete content rights, copyright/trademark ownership, and Play App Signing.
- Complete the developer-account identity, address/phone, and device
  verification tasks shown in Play Console.
- If the developer account is a new personal account, complete the required
  closed test (minimum 12 opted-in testers continuously for 14 days) before
  applying for production access.
- Review the Pre-launch report, Android vitals, Policy status, and Data safety
  again for every release because dependencies and backend collection can
  change.

## Intellectual-property gate

Do not upload the current promotional screenshots that visibly show names,
logos, or product artwork for Casio/G-Shock, Patek Philippe, Rolex, or another
third-party brand unless Nawl Ltd has written evidence that the products are
genuine and that the listing may use those names and images. Google can request
that evidence before or after publication.

Before submission, either:

1. replace those screenshots and catalogue examples with original,
   unbranded product media and generic names; or
2. send the written licences/authorisations to Google Play support in advance
   and retain supplier authenticity records.

Never market replica, copy, “first copy”, or counterfeit products through the
app. This is a business/content requirement and cannot be satisfied by an
Android build setting.
