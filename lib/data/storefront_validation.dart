/// Accept Iraqi keyboards and correctly grouped thousands, never decimals.
int? parseStorefrontPrice(String input) {
  var value = input.trim();
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  if (!RegExp(r'^(?:[0-9]+|[0-9]{1,3}(?:[,٬ ][0-9]{3})+)$').hasMatch(value)) {
    return null;
  }
  return int.tryParse(value.replaceAll(RegExp(r'[,٬ ]'), ''));
}

/// Mirrors slug constraints; the server owns uniqueness and authorization.
bool isValidStorefrontSlug(String value) {
  final slug = value.trim();
  return RegExp(r'^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$').hasMatch(slug) &&
      !slug.contains('--') &&
      !_reservedStorefrontSlugs.contains(slug);
}

const _reservedStorefrontSlugs = {
  'product',
  'www',
  'admin',
  'api',
  'app',
  'auth',
  'mail',
  'email',
  'smtp',
  'ftp',
  'cdn',
  'static',
  'assets',
  'media',
  'images',
  'support',
  'help',
  'status',
  'shop',
  'store',
  'stores',
  'loqta',
  'luqta',
  'laqta',
  'checkout',
  'billing',
  'dashboard',
  'login',
  'signup',
  'register',
  'account',
  'accounts',
  'ns1',
  'ns2',
  'dev',
  'test',
  'stage',
  'staging',
  'preview',
  'theme1',
  'theme2',
  'theme3',
  'theme4',
  'theme5',
  'theme6',
  'theme7',
  'theme8',
  'theme9',
  'theme10',
};

String normalizeStorefrontRejectionReason(String value) =>
    value.replaceAll(RegExp(r'[\s\x00-\x1f\x7f-\x9f]+'), ' ').trim();

bool isValidStorefrontRejectionReason(String value) {
  final normalized = normalizeStorefrontRejectionReason(value);
  return normalized.runes.length >= 2 && normalized.runes.length <= 300;
}
