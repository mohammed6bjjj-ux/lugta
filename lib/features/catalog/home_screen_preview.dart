import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../app/theme.dart';
import 'home_screen.dart';
import 'products_screen.dart';

/// Uses the session's demo catalog in the isolated preview runner.
@Preview(
  name: 'Home category previews — RTL',
  group: 'Catalog',
  size: Size(375, 844),
)
Widget homeCatalogPreview() => MaterialApp(
  theme: AppTheme.light(),
  home: Builder(
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: HomeScreen(
        onOpenProducts: (filters) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: ProductsScreen(initialFilters: filters),
            ),
          ),
        ),
      ),
    ),
  ),
);
