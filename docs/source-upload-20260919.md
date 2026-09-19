# Mobile source update — 2026-09-19

This update adds whole-thousand withdrawal validation and floors the maximum
request to the nearest 1,000 IQD, leaving the remainder in the wallet. The live
minimum was separately configured to 10,000 IQD; the new client reads it from
the server. This is source only, not a new store binary.

The previous snapshot's full-suite failures remain documented in
`source-upload-20260918.md`; this change does not claim to fix them.

Telegram automation and automatic media notifications are server features in
the separate parent workspace, not this mobile repository. Telegram activation
requires a channel, an administrator bot and server-side credentials. No bot
token or server secret is included in the app.
