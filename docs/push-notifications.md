# Push notifications

Durable in-app notifications always come from Supabase and update through
Realtime. FCM is an optional delivery channel layered on top of those rows.

## Client configuration

FCM is on by default for the native iOS and Android apps. They load the public
Firebase client identifiers from `GoogleService-Info.plist` and Android
resources respectively. A special build can turn push off with:

```text
--dart-define=APP_FCM_ENABLED=false
```

Web or other clients without bundled platform configuration must supply:

```text
--dart-define=APP_FCM_ENABLED=true
--dart-define=FIREBASE_API_KEY=...
--dart-define=FIREBASE_APP_ID=...
--dart-define=FIREBASE_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_PROJECT_ID=...
```

Optional platform values:

```text
--dart-define=FIREBASE_AUTH_DOMAIN=...
--dart-define=FIREBASE_STORAGE_BUCKET=...
--dart-define=FIREBASE_IOS_BUNDLE_ID=...
--dart-define=FIREBASE_WEB_VAPID_KEY=...
```

These values identify a Firebase client app; they are not an FCM server key or
a service-account secret. Never ship a service-account key in the phone app.
The backend push worker owns server credentials.

Apple releases also require an APNs key uploaded to Firebase and the Xcode Push
Notifications capability. Web background delivery additionally requires a
configured messaging service worker.

## Runtime behavior

- Notification permission is requested only for an authenticated user.
- A stable random installation UUID is kept in `SharedPreferences`.
- `register_device_token(p_device_id, p_platform, p_fcm_token)` atomically
  registers or moves the token to the current authenticated account.
- `onTokenRefresh` re-registers the new token.
- Foreground/opened push events refresh the durable Supabase notification list.
- Logout calls `unregister_device_token(p_fcm_token)`, deletes the local FCM
  token, and then ends the Supabase session.
- Missing or invalid Firebase setup safely selects `NoopDeviceTokenRegistrar`;
  Supabase Realtime and the in-app notification inbox continue to work.
