import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/shimmer.dart';
import '../../data/storefront_models.dart';
import 'storefront_strings.dart';
import 'storefront_design_widgets.dart';

class StorefrontRemoveAction extends StatelessWidget {
  const StorefrontRemoveAction({
    super.key,
    this.onPressed,
    this.loading = false,
  });
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
      minimumSize: const Size(48, 48),
    ),
    onPressed: loading ? null : onPressed,
    icon: loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.remove_circle_outline),
    label: Text(StorefrontStrings.remove),
  );
}

/// Uses the established Material button theme, preserving the label's footprint
/// during requests. Large text wraps instead of being truncated.
class StorefrontAction extends StatelessWidget {
  const StorefrontAction({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: loading,
    label: loading ? StorefrontStrings.working : null,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              opacity: loading ? 0 : 1,
              child: Text(label, textAlign: TextAlign.center),
            ),
            if (loading)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    ),
  );
}

class StorefrontMessage extends StatelessWidget {
  const StorefrontMessage({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.storefront_outlined,
    this.action,
  });
  final String title;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(body, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
      ],
    ),
  );
}

class StorefrontLoading extends StatelessWidget {
  const StorefrontLoading({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: StorefrontStrings.loading,
    child: ExcludeSemantics(
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const ShimmerBox(height: 180),
      ),
    ),
  );
}

class StoreThemeCard extends StatelessWidget {
  const StoreThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.onSelect,
    required this.onPreview,
  });
  final StoreTheme theme;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '${StorefrontStrings.preview}: ${theme.name}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: InkWell(
              onTap: onPreview,
              child: Container(
                height: 340,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: StoreDesignImage(theme: theme),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(theme.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.open_in_full),
                label: Text(
                  StorefrontStrings.preview,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                selected: selected,
                child: FilledButton.icon(
                  onPressed: onSelect,
                  icon: Icon(
                    selected ? Icons.check_circle_outline : Icons.check,
                  ),
                  label: Text(
                    selected
                        ? StorefrontStrings.selected
                        : StorefrontStrings.select,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A wrapping step indicator remains readable with large system text.
class StorefrontSetupProgress extends StatelessWidget {
  const StorefrontSetupProgress({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        StorefrontStrings.t(
          'الخطوة $step من ٢',
          'هەنگاوی $step لە ٢',
          'Step $step of 2',
        ),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      LinearProgressIndicator(value: step / 2, minHeight: 4),
      const SizedBox(height: AppSpacing.sm),
      Text(
        StorefrontStrings.t(
          'اختر التصميم، ثم اسم المتجر واللوغو',
          'دیزاین هەڵبژێرە، پاشان ناو و لۆگۆ',
          'Choose a design, then add your store name and logo',
        ),
      ),
    ],
  );
}

class StoreThemePreviewScreen extends StatelessWidget {
  const StoreThemePreviewScreen({super.key, required this.theme});
  final StoreTheme theme;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(theme.name)),
    body: SafeArea(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Text(
                StorefrontStrings.t(
                  'معاينة القالب: المنتجات والأسعار للعرض فقط وليست عروضاً حقيقية.',
                  'پێشبینینی قاڵب: بەرهەم و نرخەکان تەنها نموونەن.',
                  'Theme preview: products and prices are illustrative, not live offers.',
                ),
              ),
            ),
            StoreDesignImage(theme: theme, full: true, fit: BoxFit.fitWidth),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.md),
      child: StorefrontAction(
        label: StorefrontStrings.select,
        onPressed: () => Navigator.pop(context, true),
      ),
    ),
  );
}
