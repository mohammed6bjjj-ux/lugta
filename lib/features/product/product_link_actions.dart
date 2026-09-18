import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/product_links.dart';
import 'product_strings.dart';

class ProductLinkActions extends StatefulWidget {
  const ProductLinkActions({
    super.key,
    required this.productId,
    required this.productName,
  });
  final String productId;
  final String productName;
  @override
  State<ProductLinkActions> createState() => _ProductLinkActionsState();
}

class _ProductLinkActionsState extends State<ProductLinkActions> {
  bool _sharing = false;
  Future<void> _share(Uri url) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: '${widget.productName}\n$url',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProductStrings.mediaShareFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = ProductLinks.forProduct(widget.productId);
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            key: const ValueKey('share_product_link'),
            onPressed: _sharing ? null : () => _share(url),
            icon: const Icon(Icons.link_rounded),
            label: Text(ProductStrings.shareProductLink),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          TextButton.icon(
            key: const ValueKey('copy_product_link'),
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: url.toString()));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ProductStrings.productLinkCopied)),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ProductStrings.mediaShareFailed)),
                  );
                }
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: Text(ProductStrings.copyProductLink),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
