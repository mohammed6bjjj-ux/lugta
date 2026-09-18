# Clothing product-screen preview fixture

`clothing-shirt-black.webp` is an unchanged local copy of an existing catalogue
photo, not a generated illustration. It was obtained from the previously saved
catalogue media review (8 September 2026):

- Product: `f40c1c32-edc4-4743-a0cc-427bc615c506` — تيشيرت رياضي
- Media: `products/f40c1c32-edc4-4743-a0cc-427bc615c506/c8ea642b-26e3-4073-a9c9-0e98ba5ab648.webp`
- Local review index: `tmp/vidd-20260908/covers-index.json`, item 43, in the parent workspace.

The full-screen visual test renders the production `ProductDetailScreen` and
theme. Its size variants, stock, and description are illustrative test data;
they do not update this catalogue product or represent its live inventory.
The image source is injected only through `AppNetworkImage.debugImageProvider`.

Keep this fixture outside `fixtures/product-images`: the older brand golden
tests enumerate that directory and depend on the existing image set.
