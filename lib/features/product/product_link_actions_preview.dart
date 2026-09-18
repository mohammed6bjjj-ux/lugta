import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../app/theme.dart';
import 'product_link_actions.dart';

@Preview(name: 'Product link actions — RTL', size: Size(390, 220))
Widget productLinkActionsPreview() => MaterialApp(
  theme: AppTheme.light(),
  home: const Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: SafeArea(
        child: ProductLinkActions(
          productId: '22222222-2222-4222-8222-222222222222',
          productName: 'ساعة كلاسيك',
        ),
      ),
    ),
  ),
);
