import 'dart:convert';

/// Public identifiers only. These links never carry prices, credentials or a
/// seller identity; the catalog repository still authorizes the target read.
abstract final class ProductLinks {
  static const host = 'product.lugta.app';
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static Uri? forProduct(String id) {
    if (!_uuid.hasMatch(id)) return null;
    final hex = id.replaceAll('-', '');
    final bytes = [
      for (var i = 0; i < 32; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
    return Uri.https(host, '/p/${base64Url.encode(bytes).replaceAll('=', '')}');
  }

  static String? parse(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host != host ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery) {
      return null;
    }
    final match = RegExp(r'^/p/([A-Za-z0-9_-]{22})$').firstMatch(uri.path);
    if (match == null || uri.toString() != 'https://$host${uri.path}') {
      return null;
    }
    try {
      final bytes = base64Url.decode('${match[1]}==');
      if (bytes.length != 16) return null;
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final id =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      return forProduct(id)?.toString() == uri.toString() ? id : null;
    } on FormatException {
      return null;
    }
  }
}
