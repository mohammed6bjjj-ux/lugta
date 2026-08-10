# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Primary users are Iraqi resellers who browse Lugta's catalog, set a customer-facing sale price, submit delivery orders, and track profit from a phone. The app must remain usable in Arabic, Central Kurdish, and English, including right-to-left operation.

## Product Purpose

Lugta gives a reseller one mobile workflow for discovering products, sharing media, configuring an order, entering customer delivery details, tracking fulfillment, and receiving profit in a wallet. Success means a seller can complete those jobs quickly and confidently on an ordinary Android or iOS phone, including on an unstable connection.

## Positioning

Lugta combines a ready-to-sell multilingual catalog with seller-controlled pricing, fulfillment, packaging choices, order tracking, and wallet profit in one operational flow.

## Operating Context

- The product is used primarily one-handed on phones in Iraq.
- Sellers move frequently between catalog, product media, cart/order creation, order tracking, and wallet screens.
- Product and order data come from Supabase; WhatsApp OTP and server-authoritative pricing/order rules must remain intact.
- Network latency and intermittent connectivity are normal operating conditions.

## Capabilities and Constraints

- Preserve all current authentication, authorization, Supabase, cart, pricing, delivery, packaging, order, promotion, referral, notification, wallet, payout, and withdrawal behavior.
- Preserve the package identifier `lugta.nawl.com` and existing backend interfaces.
- The redesign covers the Flutter phone app, native Android/iOS icon and splash assets, and store presentation assets. It excludes the admin panel and marketing website.
- The app supports light and dark themes and preserves the user's saved theme choice.
- Release UI may not mix the previous green/black identity with the new identity.

## Brand Commitments

- Official name: `لكطة` in Arabic and `Lugta` in Latin script.
- Binding visual source: `C:/Users/mm/Downloads/هوية بصرية لكطة فاينل.pdf`.
- Brand purple: `#37379B`.
- Brand yellow: `#FCC803`, sampled from the supplied official logo exports; the printed `#0071FC` label in the PDF conflicts with the rendered yellow and is treated as a source typo.
- Primary type family: Zain, bundled locally for offline-safe rendering.
- The logo combines the Lugta wordmark with a shopping-bag character built into the letter G. Production uses the designer-supplied official PNG masters and remains unmirrored in RTL.

## Evidence on Hand

- A complete one-page visual-identity PDF with logo construction, palette, typography, clear-space rules, and applications.
- Existing production Flutter flows, localization copy, tests, and working Supabase integration.
- The official transparent PNG export pack is stored with the project; only the five variants required by app, splash, monochrome, and store placements are retained.

## Product Principles

- Keep every high-frequency selling action obvious and reachable with one hand.
- Show price, profit, delivery, order state, and recovery actions without ambiguity.
- Let the brand feel energetic and contemporary without obscuring operational work.
- Treat Arabic and Kurdish RTL behavior as first-class, not as a mirrored afterthought.
- Degrade gracefully under slow or failed network conditions.

## Accessibility & Inclusion

- Target WCAG 2.1 AA contrast.
- Minimum interactive target is 48dp.
- Support 200% text scaling, 320dp-wide layouts, screen-reader labels, reduced motion, and correct bidirectional formatting for phone numbers, prices, and order identifiers.
