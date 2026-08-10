# Lugta store assets

These files are generated from the final Flutter golden baselines and the official `لكطة — Lugta` brand system.

## Ready-to-upload files

- `brand/google-play-feature-1024x500.png`: Google Play feature graphic.
- `brand/store-social-square-1200.png`: reusable social/store announcement artwork.
- `google_play/{ar,ckb,en}/`: six 1080×1920 phone screenshots for every supported language.
- `app_store/{ar,ckb,en}/`: six 1290×2796 iPhone screenshots for every supported language.

## Source and regeneration

1. Regenerate the application brand and native icon assets:

   ```powershell
   python tooling/generate_brand_assets.py
   ```

2. Refresh the golden screens after an intentional visual change:

   ```powershell
   flutter test test/brand_journeys_golden_test.dart --update-goldens
   ```

3. Regenerate all store artwork:

   ```powershell
   python tooling/generate_store_assets.py
   ```

Do not manually stretch the logo, recolor the mark, place white text on yellow, or mix screenshots from the former green identity with this set.
