import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/brand_logo.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'catalog_strings.dart';

const _promoInk = Color(0xFF1F1D19);
const _promoAccent = Color(0xFF1B9E6A);
const _promoCream = Color(0xFFFAF6ED);

/// Picks the product the opening promo should advertise.
///
/// Newest first, and only genuinely new arrivals, so the promo never reopens
/// the same stale item every launch. Returns null when there is nothing worth
/// interrupting the seller for.
Product? pickPromoProduct(List<Product> products, {Random? random}) {
  final candidates = products
      .where((product) => product.isNew && product.coverImage.trim().isNotEmpty)
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final pool = candidates.take(6).toList();
  return pool[(random ?? Random()).nextInt(pool.length)];
}

/// Shows the opening promo at most once per app launch.
///
/// Guarded rather than shown on every navigation to the shell: reappearing
/// after every tab switch or push-notification return would read as spam.
class NewArrivalsPromo {
  NewArrivalsPromo._();

  static bool _shownThisLaunch = false;

  @visibleForTesting
  static void resetForTesting() => _shownThisLaunch = false;

  static Future<void> maybeShow(BuildContext context, {Random? random}) async {
    if (_shownThisLaunch) return;
    final product = pickPromoProduct(session.products, random: random);
    if (product == null || !context.mounted) return;
    _shownThisLaunch = true;

    final navigator = Navigator.of(context);
    final open = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: CatalogStrings.promoDismiss,
      barrierColor: Colors.black.withValues(alpha: .55),
      transitionDuration: AppDurations.base,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _NewArrivalsPromoCard(product: product),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .12),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (open != true) return;
    await navigator.pushNamed(Routes.productDetail, arguments: product);
  }
}

class _NewArrivalsPromoCard extends StatelessWidget {
  const _NewArrivalsPromoCard({required this.product});

  final Product product;

  void _open(BuildContext context) => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GestureDetector(
            // A flick upwards opens the product, matching the call to action.
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -180) _open(context);
              if (velocity > 180) Navigator.of(context).pop(false);
            },
            child: Material(
              color: _promoInk,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The Latin wordmark keeps its own left placement even
                        // in the RTL layout, matching the brand artwork.
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: LugtaWordmark(height: 30, inverse: true),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AspectRatio(
                          aspectRatio: 1.15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: ColoredBox(
                              color: const Color(0xFF2B2822),
                              child: AppNetworkImage(
                                product.coverImage,
                                fallbackIcon: Icons.image_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          CatalogStrings.promoNewArrivalsTitle,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: _promoCream,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product.localizedName,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _promoCream.withValues(alpha: .62),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () => _open(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _promoAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(CatalogStrings.promoSwipeUp),
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: IconButton(
                      tooltip: CatalogStrings.promoDismiss,
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      color: _promoCream.withValues(alpha: .55),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
