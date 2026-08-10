import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'catalog_strings.dart';
import 'recent_search_history.dart';

/// شاشة البحث: سجل + اقتراحات قبل الكتابة، ونتائج شبكية مع debounce.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.history});

  final RecentSearchHistory? history;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const double _gridAspectRatio = ProductCard.gridAspectRatio;

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late final RecentSearchHistory _history;

  List<String> get _recentSearches => _history.items;

  @override
  void initState() {
    super.initState();
    _history = widget.history ?? recentSearchHistory;
    _history.bindOwner(session.seller.id);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // تحديث فوري لزر المسح، وتأجيل البحث الفعلي 300 مللي ثانية.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _commitSearch(String value) {
    final term = value.trim();
    if (term.isEmpty) return;
    _debounce?.cancel();
    setState(() {
      _history.add(term);
      _query = term;
    });
  }

  void _useTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _commitSearch(term);
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  List<Product> _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return session.products.where((p) {
      final categoryName = session.categoryById(p.categoryId).localizedName;
      return p.localizedName.toLowerCase().contains(q) ||
          p.localizedDescription.toLowerCase().contains(q) ||
          categoryName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _history.bindOwner(session.seller.id);
    final theme = Theme.of(context);
    final hasQuery = _query.isNotEmpty;

    // حقل البحث كبسولة surfaceAlt حديثة كاملة الاستدارة.
    final capsuleBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(100),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _commitSearch,
            decoration: InputDecoration(
              hintText: CatalogStrings.searchLongHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              border: capsuleBorder,
              enabledBorder: capsuleBorder,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(color: AppColors.accent, width: 1.4),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.accentStrong,
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: CatalogStrings.clear,
                      onPressed: _clearQuery,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => SessionRefreshIndicator(
          onRefresh: session.refreshCatalog,
          child: hasQuery ? _buildResults(theme) : _buildIdle(theme),
        ),
      ),
    );
  }

  /// قبل الكتابة: سجل البحث + اقتراحات التصنيفات — بدخول متدرج.
  Widget _buildIdle(ThemeData theme) {
    var entranceIndex = 0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Entrance(
            index: entranceIndex++,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    CatalogStrings.recentSearches,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(_history.clear),
                  child: Text(CatalogStrings.clearAll),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final term in List.of(_recentSearches))
            Entrance(
              index: entranceIndex++,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                title: Text(term, style: theme.textTheme.bodyMedium),
                trailing: IconButton(
                  tooltip: CatalogStrings.remove,
                  onPressed: () => setState(() => _history.remove(term)),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () => _useTerm(term),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Entrance(
          index: entranceIndex++,
          child: Text(
            CatalogStrings.suggestedCategories,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        Entrance(
          index: entranceIndex++,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in session.categories)
                ActionChip(
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: AppColors.accentStrong,
                  ),
                  label: Text(category.localizedName),
                  onPressed: () => _useTerm(category.localizedName),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// نتائج البحث أو حالة «لا نتائج».
  Widget _buildResults(ThemeData theme) {
    final results = _search(_query);

    if (results.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: CatalogStrings.noResultsFor(_query),
              subtitle: CatalogStrings.noResultsHint,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Entrance(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              CatalogStrings.resultsCountFor(
                formatNumber(results.length),
                _query,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm + 4,
              crossAxisSpacing: AppSpacing.sm + 4,
              childAspectRatio: _gridAspectRatio,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) => Entrance(
              index: index,
              child: ProductCard(product: results[index]),
            ),
          ),
        ),
      ],
    );
  }
}
