import 'package:flutter/material.dart';

import 'models.dart';

/// بيانات وهمية للمرحلة الأولى (تصميم الواجهات) — تُستبدل لاحقاً بطبقة API حقيقية.
///
/// الصور من Unsplash بمعرفات صور حقيقية منتقاة بصرياً واحدة واحدة
/// (ساعات، ساعات ذكية، نظارات، إكسسوارات) — ثابتة لا تتغير بين الجلسات.
class MockData {
  MockData._();

  /// معرفات صور Unsplash المنتقاة — كل اسم يصف محتوى الصورة الفعلي.
  static const Map<String, String> _photos = {
    'chronoSteel': '1523170335258-f5ed11844a49',
    'minimalHand': '1524592094714-0f0654e20314',
    'steelDark': '1547996160-81dfa63595aa',
    'smartWrist': '1508685096489-7aacd43bd3b1',
    'analogBlack': '1434056886845-dac89ffe9b56',
    'watchRock': '1495856458515-0637185db551',
    'chronoRed': '1539874754764-5a96559165b0',
    'diveWatch': '1594534475808-b18fc33b045e',
    'bronzeWatch': '1622434641406-a158123450f9',
    'blackLux': '1587836374828-4dbafa94cf0e',
    'appleBlack': '1546868871-7041f2a55e12',
    'roseChrono': '1522312346375-d1a52e2b99b3',
    'appleColor': '1579586337278-3befd40fd17a',
    'appleNike': '1544117519-31a4b719223d',
    'smartBox': '1617043786394-f977fa12eddf',
    'sunRound': '1511499767150-a48a237f0083',
    'sunWayfarer': '1572635196237-14b3f281503f',
    'sunAviator': '1577803645773-f96470509666',
    'sunSand': '1473496169904-658ba7c44d8a',
    'sunRose': '1508296695146-257a814070b4',
    'sunCase': '1509695507497-903c140c43b0',
    'eyeClub': '1574258495973-f010dfbb5371',
    'eyeBokeh': '1591076482161-42ce6da69f67',
    'braceletGold': '1611591437281-460bfbe1220a',
    'pearlBox': '1515562141207-7a88fb7ce338',
    'diveMacro': '1526045431048-f857369baa09',
    'watchSunset': '1533139502658-0198f920d8e8',
    'steelMacro': '1548171915-e79a380a2a4b',
    'goldWhite': '1451290337906-ac938fc89bce',
  };

  /// رابط صورة Unsplash باسمها المنتقى.
  static String _u(String name, {int w = 900}) =>
      'https://images.unsplash.com/photo-${_photos[name]}?w=$w&q=80&auto=format';

  static final DateTime _now = DateTime.now();

  /// إعدادات المنصة (تديرها لوحة الإدارة لاحقاً).
  static const int minWithdrawalAmount = 10000;
  static const String supportPhone = '07738822202';
  static const String supportWhatsapp = '07738822202';

  // ─────────────────────────── البائع الحالي ───────────────────────────

  static final Seller seller = Seller(
    id: 'seller-1',
    name: 'أحمد الياسري',
    phone: '07712345678',
    storeName: 'متجر روائع الساعات',
    instagramUrl: 'instagram.com/rawaea.watches',
    governorateId: 'gov-baghdad',
    status: AccountStatus.approved,
    joinedAt: _now.subtract(const Duration(days: 94)),
    referralCode: 'LUGTA-TEST',
  );

  static const ReferralSummary referralSummary = ReferralSummary(
    referralCode: 'LUGTA-TEST',
    invitedCount: 6,
    qualifiedCount: 3,
    rewardedCount: 2,
    completedReferredOrders: 11,
    availableFreeDeliveries: 2,
    walletRewardsEarned: 15000,
  );

  static final LoyaltySummary loyaltySummary = LoyaltySummary(
    programEnabled: true,
    pointsPerSoldUnit: 10,
    totalPoints: 640,
    completedUnits: 64,
    currentTier: const LoyaltyTierDefinition(
      code: LoyaltyTierCode.bronze,
      nameAr: 'برونزي',
      nameCkb: 'برۆنز',
      nameEn: 'Bronze',
      threshold: 0,
      rewardEnabled: true,
      rewardType: 'free_delivery',
      rewardValue: 1,
      rewardValidDays: 14,
      benefits: [
        LoyaltyTierBenefit(
          type: LoyaltyBenefitType.productSourcing,
          enabled: true,
          monthlyLimit: 2,
          maxPerRequest: 10,
          usedThisMonth: 1,
          remainingThisMonth: 1,
        ),
        LoyaltyTierBenefit(
          type: LoyaltyBenefitType.customPhotography,
          enabled: true,
          monthlyLimit: 1,
          maxPerRequest: 5,
          remainingThisMonth: 1,
        ),
      ],
    ),
    nextTier: const LoyaltyNextTier(
      code: LoyaltyTierCode.silver,
      nameAr: 'فضي',
      nameCkb: 'زیو',
      nameEn: 'Silver',
      threshold: 1000,
      pointsNeeded: 360,
    ),
    pointsToNextTier: 360,
    tiers: const [
      LoyaltyTierDefinition(
        code: LoyaltyTierCode.bronze,
        nameAr: 'برونزي',
        nameCkb: 'برۆنز',
        nameEn: 'Bronze',
        threshold: 0,
        rewardEnabled: true,
        rewardType: 'free_delivery',
        rewardValue: 1,
        rewardValidDays: 14,
        benefits: [
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.productSourcing,
            enabled: true,
            monthlyLimit: 2,
            maxPerRequest: 10,
          ),
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.customPhotography,
            enabled: true,
            monthlyLimit: 1,
            maxPerRequest: 5,
          ),
        ],
      ),
      LoyaltyTierDefinition(
        code: LoyaltyTierCode.silver,
        nameAr: 'فضي',
        nameCkb: 'زیو',
        nameEn: 'Silver',
        threshold: 1000,
        rewardEnabled: true,
        rewardType: 'wallet_credit',
        rewardValue: 10000,
        rewardValidDays: 30,
        benefits: [
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.productSourcing,
            enabled: true,
            monthlyLimit: 4,
            maxPerRequest: 20,
          ),
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.customPhotography,
            enabled: true,
            monthlyLimit: 2,
            maxPerRequest: 8,
          ),
        ],
      ),
      LoyaltyTierDefinition(
        code: LoyaltyTierCode.gold,
        nameAr: 'ذهبي',
        nameCkb: 'زێڕ',
        nameEn: 'Gold',
        threshold: 3000,
        rewardEnabled: true,
        rewardType: 'free_delivery',
        rewardValue: 3,
        rewardValidDays: 30,
        benefits: [
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.productSourcing,
            enabled: true,
            monthlyLimit: 8,
            maxPerRequest: 50,
          ),
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.customPhotography,
            enabled: true,
            monthlyLimit: 4,
            maxPerRequest: 12,
          ),
        ],
      ),
      LoyaltyTierDefinition(
        code: LoyaltyTierCode.diamond,
        nameAr: 'ألماسي',
        nameCkb: 'ئەڵماس',
        nameEn: 'Diamond',
        threshold: 6000,
        rewardEnabled: false,
        rewardType: '',
        rewardValue: 0,
        benefits: [
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.productSourcing,
            enabled: true,
            monthlyLimit: 12,
            maxPerRequest: 75,
          ),
          LoyaltyTierBenefit(
            type: LoyaltyBenefitType.customPhotography,
            enabled: true,
            monthlyLimit: 6,
            maxPerRequest: 20,
          ),
        ],
        stockReservation: StockReservationEntitlement(
          enabled: true,
          maxActiveUnits: 12,
          maxPerReservation: 4,
          holdHours: 24,
          activeUnits: 0,
          remainingUnits: 12,
        ),
      ),
    ],
    recentEntries: [
      LoyaltyPointEntry(
        id: 'points-demo-1',
        type: 'order_completed',
        points: 20,
        orderId: 'order-demo-1',
        orderNumber: 'ORD-0001042',
        soldUnits: 2,
        description: 'نقاط بيع طلب مكتمل',
        createdAt: _now.subtract(const Duration(days: 1)),
      ),
      LoyaltyPointEntry(
        id: 'points-demo-2',
        type: 'order_completed',
        points: 10,
        orderId: 'order-demo-2',
        orderNumber: 'ORD-0001039',
        soldUnits: 1,
        description: 'نقاط بيع طلب مكتمل',
        createdAt: _now.subtract(const Duration(days: 3)),
      ),
    ],
    recentBenefitRequests: [
      LoyaltyBenefitRequest(
        id: 'benefit-demo-1',
        requestNumber: 17,
        tierCode: LoyaltyTierCode.bronze,
        benefitType: LoyaltyBenefitType.productSourcing,
        itemName: 'ساعة رياضية مقاومة للماء',
        requestedQuantity: 3,
        status: LoyaltyBenefitRequestStatus.approved,
        details: 'يفضل لون أسود مع سوار سيليكون.',
        adminResponse: 'تم قبول الطلب وجارٍ البحث عن المورد المناسب.',
        createdAt: _now.subtract(const Duration(days: 2)),
        updatedAt: _now.subtract(const Duration(days: 1)),
      ),
    ],
  );

  static final List<PromotionGrant> promotionGrants = [
    PromotionGrant(
      id: 'grant-demo-free-delivery',
      promotionId: 'promotion-demo-referral',
      sellerId: seller.id,
      rewardOrdinal: 1,
      rewardType: 'free_delivery',
      rewardValue: 1,
      status: PromotionGrantStatus.available,
      expiresAt: _now.add(const Duration(days: 14)),
      createdAt: _now.subtract(const Duration(days: 1)),
      promotion: Promotion(
        id: 'promotion-demo-referral',
        nameAr: 'مكافأة دعوة صديق',
        nameCkb: 'دیاریی بانگهێشتی هاوڕێ',
        nameEn: 'Referral reward',
        descriptionAr: 'توصيل مجاني مقابل دعوة ناجحة.',
        descriptionCkb: 'گەیاندنی بەخۆڕایی بۆ بانگهێشتێکی سەرکەوتوو.',
        descriptionEn: 'Free delivery for a successful referral.',
        audienceType: 'referred_accounts',
        triggerType: 'qualified_referral_count',
        triggerThreshold: 1,
        beneficiary: 'referrer',
        rewardType: 'free_delivery',
        rewardValue: 1,
        rewardValidDays: 14,
        startsAt: null,
        endsAt: null,
        isActive: true,
        priority: 10,
        showPopup: true,
        showInbox: true,
        sendPush: true,
      ),
    ),
  ];

  // ─────────────────────────── التصنيفات ───────────────────────────

  static final List<Category> categories = [
    Category(
      id: 'cat-watches',
      nameAr: 'ساعات يدوية',
      icon: Icons.watch,
      imageUrl: _u('minimalHand', w: 400),
    ),
    Category(
      id: 'cat-smart',
      nameAr: 'ساعات ذكية',
      icon: Icons.watch_outlined,
      imageUrl: _u('appleBlack', w: 400),
    ),
    Category(
      id: 'cat-glasses',
      nameAr: 'نظارات',
      icon: Icons.visibility_outlined,
      imageUrl: _u('sunWayfarer', w: 400),
    ),
    Category(
      id: 'cat-accessories',
      nameAr: 'إكسسوارات',
      icon: Icons.diamond_outlined,
      imageUrl: _u('braceletGold', w: 400),
    ),
  ];

  static Category categoryById(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

  // ─────────────────────────── المنتجات ───────────────────────────

  /// وسائط منتج من صور منتقاة بالاسم — الصور أولاً ثم الفيديوهات
  /// (صورهم المصغرة من نفس المجموعة).
  static List<MediaItem> _media(
    String prefix,
    List<String> imageNames, {
    List<String> videoNames = const [],
  }) => [
    for (final (i, name) in imageNames.indexed)
      MediaItem(id: '$prefix-img-$i', type: MediaType.image, url: _u(name)),
    for (final (v, name) in videoNames.indexed)
      MediaItem(
        id: '$prefix-vid-$v',
        type: MediaType.video,
        url: _u(name),
        thumbnailUrl: _u(name),
        durationSec: 20 + v * 13,
      ),
  ];

  static final List<Product> products = [
    Product(
      id: 'p-classic-leather',
      nameAr: 'ساعة كلاسيك بحزام جلد طبيعي',
      categoryId: 'cat-watches',
      description:
          'ساعة رجالية كلاسيكية بقرص أنيق وحزام جلد طبيعي مريح، تناسب الإطلالات الرسمية واليومية. '
          'مقاومة لرذاذ الماء وتأتي بعلبة هدية فاخرة جاهزة للتسويق.',
      specs: {
        'الماركة': 'Genève Classic',
        'قطر القرص': '42 ملم',
        'الحزام': 'جلد طبيعي',
        'الحركة': 'كوارتز ياباني',
        'مقاومة الماء': '3ATM (رذاذ فقط)',
        'الضمان': 'سنة على الحركة',
      },
      media: _media(
        'cl',
        ['minimalHand', 'watchRock', 'watchSunset', 'goldWhite', 'analogBlack'],
        videoNames: ['steelDark'],
      ),
      variants: [
        ProductVariant(
          id: 'v-cl-black',
          nameAr: 'أسود',
          imageUrl: _u('analogBlack', w: 400),
          stock: 14,
          colorHex: 0xFF232323,
        ),
        ProductVariant(
          id: 'v-cl-brown',
          nameAr: 'بني',
          imageUrl: _u('bronzeWatch', w: 400),
          stock: 9,
          colorHex: 0xFF6B4A2F,
        ),
        ProductVariant(
          id: 'v-cl-blue',
          nameAr: 'أزرق ملكي',
          imageUrl: _u('watchRock', w: 400),
          stock: 3,
          colorHex: 0xFF1F3A6E,
        ),
      ],
      wholesalePrice: 50000,
      suggestedPrice: 65000,
      ordersCount: 132,
      createdAt: _now.subtract(const Duration(days: 40)),
    ),
    Product(
      id: 'p-steel-luxury',
      nameAr: 'ساعة ستانلس ستيل فاخرة',
      categoryId: 'cat-watches',
      description:
          'تصميم فخم بسوار معدني متين وقفل أمان مزدوج، خيار مثالي للإهداء. '
          'قرص بتفاصيل مشغولة بدقة وعقارب مضيئة في الظلام.',
      specs: {
        'الماركة': 'Monarch Steel',
        'قطر القرص': '44 ملم',
        'السوار': 'ستانلس ستيل 316L',
        'الحركة': 'كوارتز',
        'مقاومة الماء': '5ATM',
        'الضمان': 'سنة',
      },
      media: _media(
        'sl',
        [
          'chronoSteel',
          'diveWatch',
          'steelMacro',
          'blackLux',
          'steelDark',
          'diveMacro',
        ],
        videoNames: ['chronoRed', 'roseChrono'],
      ),
      variants: [
        ProductVariant(
          id: 'v-sl-silver',
          nameAr: 'فضي',
          imageUrl: _u('chronoSteel', w: 400),
          stock: 11,
          colorHex: 0xFFB9BCC0,
        ),
        ProductVariant(
          id: 'v-sl-gold',
          nameAr: 'ذهبي',
          imageUrl: _u('goldWhite', w: 400),
          stock: 6,
          colorHex: 0xFFC6A15B,
        ),
        ProductVariant(
          id: 'v-sl-black',
          nameAr: 'أسود مطفي',
          imageUrl: _u('blackLux', w: 400),
          stock: 0,
          colorHex: 0xFF2B2B2B,
        ),
      ],
      wholesalePrice: 75000,
      oldWholesalePrice: 85000,
      suggestedPrice: 95000,
      minSalePrice: 80000,
      ordersCount: 98,
      createdAt: _now.subtract(const Duration(days: 55)),
    ),
    Product(
      id: 'p-lady-elegant',
      nameAr: 'ساعة نسائية أنيقة بسوار رفيع',
      categoryId: 'cat-watches',
      description:
          'ساعة نسائية بقرص صغير راقٍ وسوار رفيع مرصع، تلمع بحضورها في المناسبات. '
          'تأتي بعلبة مخملية أنيقة.',
      specs: {
        'الماركة': 'Bella Rosa',
        'قطر القرص': '32 ملم',
        'السوار': 'معدن مطلي',
        'الحركة': 'كوارتز',
        'مقاومة الماء': '3ATM',
      },
      media: _media(
        'le',
        ['roseChrono', 'goldWhite', 'minimalHand', 'braceletGold', 'pearlBox'],
        videoNames: ['watchSunset'],
      ),
      variants: [
        ProductVariant(
          id: 'v-le-rose',
          nameAr: 'ذهبي وردي',
          imageUrl: _u('roseChrono', w: 400),
          stock: 16,
          colorHex: 0xFFD9A6A0,
        ),
        ProductVariant(
          id: 'v-le-silver',
          nameAr: 'فضي',
          imageUrl: _u('minimalHand', w: 400),
          stock: 12,
          colorHex: 0xFFC0C3C7,
        ),
      ],
      wholesalePrice: 45000,
      oldWholesalePrice: 52000,
      suggestedPrice: 60000,
      ordersCount: 211,
      createdAt: _now.subtract(const Duration(days: 70)),
    ),
    Product(
      id: 'p-chrono-sport',
      nameAr: 'ساعة رياضية كرونوغراف',
      categoryId: 'cat-watches',
      description:
          'كرونوغراف رياضي بعدادات فعلية وحزام مطاطي متين يتحمل الاستخدام اليومي الشاق. '
          'خيار قوي لجمهور الشباب.',
      specs: {
        'الماركة': 'Vortex Sport',
        'قطر القرص': '46 ملم',
        'الحزام': 'سيليكون رياضي',
        'الحركة': 'كوارتز كرونوغراف',
        'مقاومة الماء': '10ATM',
      },
      media: _media(
        'cs',
        ['chronoRed', 'chronoSteel', 'diveMacro', 'diveWatch'],
        videoNames: ['steelMacro'],
      ),
      variants: [
        ProductVariant(
          id: 'v-cs-black',
          nameAr: 'أسود/أحمر',
          imageUrl: _u('chronoRed', w: 400),
          stock: 8,
          colorHex: 0xFF1E1E1E,
        ),
        ProductVariant(
          id: 'v-cs-navy',
          nameAr: 'كحلي/برتقالي',
          imageUrl: _u('diveWatch', w: 400),
          stock: 5,
          colorHex: 0xFF23355C,
        ),
      ],
      wholesalePrice: 60000,
      suggestedPrice: 80000,
      isNew: true,
      ordersCount: 41,
      createdAt: _now.subtract(const Duration(days: 6)),
    ),
    Product(
      id: 'p-smart-pro',
      nameAr: 'ساعة ذكية Pro بشاشة AMOLED',
      categoryId: 'cat-smart',
      description:
          'شاشة AMOLED ساطعة، قياس نبض وأوكسجين، إشعارات مكالمات وواتساب، وبطارية تدوم 7 أيام. '
          'تدعم اللغة العربية بالكامل مع تطبيق مرافق.',
      specs: {
        'الشاشة': '1.43 بوصة AMOLED',
        'البطارية': '7 أيام استخدام فعلي',
        'المقاومة': 'IP68',
        'الاتصال': 'بلوتوث 5.2 + مكالمات',
        'التوافق': 'أندرويد و iOS',
        'اللغة': 'يدعم العربية',
      },
      media: _media(
        'sp',
        ['smartWrist', 'appleBlack', 'appleColor', 'appleNike', 'smartBox'],
        videoNames: ['appleColor', 'smartWrist'],
      ),
      variants: [
        ProductVariant(
          id: 'v-sp-black',
          nameAr: 'أسود',
          imageUrl: _u('appleBlack', w: 400),
          stock: 22,
          colorHex: 0xFF202020,
        ),
        ProductVariant(
          id: 'v-sp-silver',
          nameAr: 'فضي',
          imageUrl: _u('smartWrist', w: 400),
          stock: 10,
          colorHex: 0xFFBFC2C6,
        ),
        ProductVariant(
          id: 'v-sp-gold',
          nameAr: 'ذهبي',
          imageUrl: _u('appleColor', w: 400),
          stock: 2,
          colorHex: 0xFFC9A96A,
        ),
      ],
      wholesalePrice: 55000,
      suggestedPrice: 75000,
      isNew: true,
      ordersCount: 187,
      createdAt: _now.subtract(const Duration(days: 12)),
    ),
    Product(
      id: 'p-smart-band',
      nameAr: 'سوار ذكي رياضي بحزامين',
      categoryId: 'cat-smart',
      description:
          'سوار لياقة خفيف مع حزام إضافي هدية، يتتبع الخطوات والنوم والنبض، '
          'وشاشة ملونة واضحة تحت الشمس.',
      specs: {
        'الشاشة': '1.1 بوصة ملونة',
        'البطارية': '14 يوماً',
        'المقاومة': 'IP67',
        'المستشعرات': 'نبض + خطوات + نوم',
      },
      media: _media(
        'sb',
        ['appleNike', 'appleColor', 'appleBlack', 'smartWrist'],
        videoNames: ['smartBox'],
      ),
      variants: [
        ProductVariant(
          id: 'v-sb-black',
          nameAr: 'أسود + رمادي',
          imageUrl: _u('appleNike', w: 400),
          stock: 30,
          colorHex: 0xFF262626,
        ),
        ProductVariant(
          id: 'v-sb-pink',
          nameAr: 'وردي + أبيض',
          imageUrl: _u('appleColor', w: 400),
          stock: 18,
          colorHex: 0xFFE3A1B0,
        ),
      ],
      wholesalePrice: 25000,
      oldWholesalePrice: 32000,
      suggestedPrice: 38000,
      ordersCount: 264,
      createdAt: _now.subtract(const Duration(days: 90)),
    ),
    Product(
      id: 'p-smart-lady',
      nameAr: 'ساعة ذكية نسائية بإطار معدني',
      categoryId: 'cat-smart',
      description:
          'تصميم نسائي رشيق بإطار معدني لامع وأحزمة قابلة للتبديل، مع تتبع صحي متكامل '
          'وواجهات ساعة متنوعة.',
      specs: {
        'الشاشة': '1.2 بوصة AMOLED',
        'البطارية': '5 أيام',
        'المقاومة': 'IP68',
        'التوافق': 'أندرويد و iOS',
      },
      media: _media(
        'sl2',
        ['smartBox', 'appleColor', 'smartWrist', 'appleBlack', 'appleNike'],
        videoNames: ['appleColor'],
      ),
      variants: [
        ProductVariant(
          id: 'v-sl2-rose',
          nameAr: 'ذهبي وردي',
          imageUrl: _u('appleColor', w: 400),
          stock: 0,
          colorHex: 0xFFD8A49B,
        ),
        ProductVariant(
          id: 'v-sl2-silver',
          nameAr: 'فضي',
          imageUrl: _u('smartBox', w: 400),
          stock: 0,
          colorHex: 0xFFC4C7CB,
        ),
      ],
      wholesalePrice: 48000,
      suggestedPrice: 65000,
      ordersCount: 76,
      createdAt: _now.subtract(const Duration(days: 34)),
    ),
    Product(
      id: 'p-sun-classic',
      nameAr: 'نظارة شمسية رجالية كلاسيك',
      categoryId: 'cat-glasses',
      description:
          'عدسات UV400 بإطار معدني خفيف لا يترك أثراً على الأنف، تصميم خالد يناسب كل الوجوه. '
          'تأتي بعلبة صلبة وقماشة تنظيف.',
      specs: {
        'الإطار': 'معدن خفيف',
        'العدسة': 'UV400 مستقطبة',
        'الوزن': '24 غم',
        'الملحقات': 'علبة + قماشة',
      },
      media: _media(
        'sc',
        ['sunWayfarer', 'sunRound', 'sunAviator', 'sunSand', 'sunCase'],
        videoNames: ['sunWayfarer'],
      ),
      variants: [
        ProductVariant(
          id: 'v-sc-black',
          nameAr: 'أسود',
          imageUrl: _u('sunWayfarer', w: 400),
          stock: 25,
          colorHex: 0xFF1F1F1F,
        ),
        ProductVariant(
          id: 'v-sc-brown',
          nameAr: 'عدسة بنية',
          imageUrl: _u('sunAviator', w: 400),
          stock: 13,
          colorHex: 0xFF7A5230,
        ),
        ProductVariant(
          id: 'v-sc-green',
          nameAr: 'عدسة خضراء',
          imageUrl: _u('sunRound', w: 400),
          stock: 4,
          colorHex: 0xFF3E5C43,
        ),
      ],
      wholesalePrice: 20000,
      oldWholesalePrice: 26000,
      suggestedPrice: 35000,
      ordersCount: 158,
      createdAt: _now.subtract(const Duration(days: 60)),
    ),
    Product(
      id: 'p-sun-lady',
      nameAr: 'نظارة شمسية نسائية أوفرسايز',
      categoryId: 'cat-glasses',
      description:
          'إطار أوفرسايز عصري بعدسات متدرجة اللون، إطلالة جذابة أمام الكاميرا — '
          'من أكثر القطع مبيعاً على صفحات إنستغرام.',
      specs: {
        'الإطار': 'أسيتات فاخر',
        'العدسة': 'UV400 متدرجة',
        'الوزن': '28 غم',
      },
      media: _media(
        'sly',
        [
          'sunRose',
          'sunCase',
          'sunSand',
          'sunAviator',
          'sunRound',
          'sunWayfarer',
        ],
        videoNames: ['sunRose'],
      ),
      variants: [
        ProductVariant(
          id: 'v-sly-black',
          nameAr: 'أسود متدرج',
          imageUrl: _u('sunCase', w: 400),
          stock: 19,
          colorHex: 0xFF232323,
        ),
        ProductVariant(
          id: 'v-sly-havana',
          nameAr: 'هافانا',
          imageUrl: _u('sunAviator', w: 400),
          stock: 7,
          colorHex: 0xFF8A5A33,
        ),
      ],
      wholesalePrice: 22000,
      suggestedPrice: 38000,
      isNew: true,
      ordersCount: 93,
      createdAt: _now.subtract(const Duration(days: 9)),
    ),
    Product(
      id: 'p-bluelight',
      nameAr: 'نظارة حماية من الضوء الأزرق',
      categoryId: 'cat-glasses',
      description:
          'عدسات فلتر ضوء أزرق مريحة لساعات الشاشة الطويلة، بإطار خفيف مرن يناسب الجنسين. '
          'مثالية لجمهور الطلاب والموظفين.',
      specs: {
        'الإطار': 'TR90 مرن',
        'العدسة': 'فلتر ضوء أزرق',
        'الوزن': '18 غم',
      },
      media: _media('bl', ['eyeClub', 'eyeBokeh', 'sunRound', 'sunWayfarer']),
      variants: [
        ProductVariant(
          id: 'v-bl-black',
          nameAr: 'أسود',
          imageUrl: _u('eyeBokeh', w: 400),
          stock: 27,
          colorHex: 0xFF222222,
        ),
        ProductVariant(
          id: 'v-bl-clear',
          nameAr: 'شفاف',
          imageUrl: _u('eyeClub', w: 400),
          stock: 15,
          colorHex: 0xFFDDDDDD,
        ),
      ],
      wholesalePrice: 15000,
      suggestedPrice: 25000,
      ordersCount: 117,
      createdAt: _now.subtract(const Duration(days: 48)),
    ),
    Product(
      id: 'p-bracelet-leather',
      nameAr: 'أسوارة رجالية جلد مضفور',
      categoryId: 'cat-accessories',
      description:
          'أسوارة جلد مضفور بقفل معدني مغناطيسي، قطعة مكملة مثالية تُباع مع الساعات كطقم. '
          'فرصة رفع قيمة الطلب الواحد.',
      specs: {
        'الخامة': 'جلد + ستانلس',
        'القياس': 'قابل للتعديل',
        'القفل': 'مغناطيسي',
      },
      media: _media('br', [
        'braceletGold',
        'pearlBox',
        'goldWhite',
        'bronzeWatch',
      ]),
      variants: [
        ProductVariant(
          id: 'v-br-black',
          nameAr: 'أسود',
          imageUrl: _u('bronzeWatch', w: 400),
          stock: 33,
          colorHex: 0xFF242424,
        ),
        ProductVariant(
          id: 'v-br-brown',
          nameAr: 'بني',
          imageUrl: _u('braceletGold', w: 400),
          stock: 21,
          colorHex: 0xFF6E4A2E,
        ),
      ],
      wholesalePrice: 8000,
      suggestedPrice: 15000,
      ordersCount: 201,
      createdAt: _now.subtract(const Duration(days: 100)),
    ),
    Product(
      id: 'p-watch-box',
      nameAr: 'علبة عرض ساعات فاخرة (6 خانات)',
      categoryId: 'cat-accessories',
      description:
          'علبة تخزين وعرض بست خانات ببطانة مخملية وغطاء زجاجي، هدية راقية لعشاق الساعات '
          'ومنتج مكمل يرفع متوسط سلة الزبون.',
      specs: {
        'السعة': '6 ساعات',
        'الخامة': 'جلد صناعي + مخمل',
        'الغطاء': 'زجاج شفاف',
      },
      media: _media(
        'wb',
        ['pearlBox', 'blackLux', 'smartBox', 'goldWhite'],
        videoNames: ['chronoSteel'],
      ),
      variants: [
        ProductVariant(
          id: 'v-wb-black',
          nameAr: 'أسود',
          imageUrl: _u('blackLux', w: 400),
          stock: 12,
          colorHex: 0xFF1E1E1E,
        ),
        ProductVariant(
          id: 'v-wb-brown',
          nameAr: 'بني غامق',
          imageUrl: _u('pearlBox', w: 400),
          stock: 3,
          colorHex: 0xFF5C3D24,
        ),
      ],
      wholesalePrice: 18000,
      suggestedPrice: 30000,
      isNew: true,
      ordersCount: 22,
      createdAt: _now.subtract(const Duration(days: 4)),
    ),
  ];

  static Product productById(String id) =>
      products.firstWhere((p) => p.id == id, orElse: () => products.first);

  // ─────────────────────────── المحافظات ───────────────────────────

  static final List<Governorate> governorates = [
    Governorate(id: 'gov-baghdad', nameAr: 'بغداد', deliveryFee: 4000),
    Governorate(id: 'gov-basra', nameAr: 'البصرة', deliveryFee: 5000),
    Governorate(id: 'gov-nineveh', nameAr: 'نينوى', deliveryFee: 5000),
    Governorate(id: 'gov-erbil', nameAr: 'أربيل', deliveryFee: 6000),
    Governorate(id: 'gov-najaf', nameAr: 'النجف', deliveryFee: 5000),
    Governorate(id: 'gov-karbala', nameAr: 'كربلاء', deliveryFee: 5000),
    Governorate(id: 'gov-kirkuk', nameAr: 'كركوك', deliveryFee: 5000),
    Governorate(id: 'gov-anbar', nameAr: 'الأنبار', deliveryFee: 6000),
    Governorate(id: 'gov-babil', nameAr: 'بابل', deliveryFee: 5000),
    Governorate(id: 'gov-diyala', nameAr: 'ديالى', deliveryFee: 5000),
    Governorate(id: 'gov-dhiqar', nameAr: 'ذي قار', deliveryFee: 5000),
    Governorate(
      id: 'gov-sulaymaniyah',
      nameAr: 'السليمانية',
      deliveryFee: 6000,
    ),
    Governorate(id: 'gov-salahaddin', nameAr: 'صلاح الدين', deliveryFee: 5000),
    Governorate(id: 'gov-qadisiyah', nameAr: 'الديوانية', deliveryFee: 5000),
    Governorate(id: 'gov-wasit', nameAr: 'واسط', deliveryFee: 5000),
    Governorate(id: 'gov-maysan', nameAr: 'ميسان', deliveryFee: 5000),
    Governorate(id: 'gov-muthanna', nameAr: 'المثنى', deliveryFee: 6000),
    Governorate(id: 'gov-duhok', nameAr: 'دهوك', deliveryFee: 6000),
    Governorate(id: 'gov-halabja', nameAr: 'حلبجة', deliveryFee: 6000),
  ];

  // ─────────────────────────── الطلبات ───────────────────────────

  static List<OrderStatusEntry> _history(
    List<(OrderStatus, int, String?)> steps,
  ) => [
    for (final (status, hoursAgo, note) in steps)
      OrderStatusEntry(
        status: status,
        at: _now.subtract(Duration(hours: hoursAgo)),
        note: note,
      ),
  ];

  static final List<Order> orders = [
    Order(
      id: 'o-1050',
      code: 'ORD-1050',
      productId: 'p-smart-pro',
      productName: 'ساعة ذكية Pro بشاشة AMOLED',
      productImage: _u('appleBlack', w: 400),
      items: [
        OrderItem(
          variantId: 'v-sp-black',
          variantName: 'أسود',
          imageUrl: _u('appleBlack', w: 400),
          quantity: 1,
        ),
      ],
      wholesalePrice: 55000,
      unitSalePrice: 75000,
      deliveryFee: 4000,
      customerName: 'حسين علي كريم',
      customerPhone: '07811112222',
      governorateName: 'بغداد',
      regionName: 'المنصور',
      addressDetails: 'حي دراغ — قرب مول المنصور، شارع 14 رمضان',
      status: OrderStatus.pendingReview,
      statusHistory: _history([(OrderStatus.pendingReview, 2, null)]),
      createdAt: _now.subtract(const Duration(hours: 2)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1049',
      code: 'ORD-1049',
      productId: 'p-classic-leather',
      productName: 'ساعة كلاسيك بحزام جلد طبيعي',
      productImage: _u('minimalHand', w: 400),
      items: [
        OrderItem(
          variantId: 'v-cl-black',
          variantName: 'أسود',
          imageUrl: _u('analogBlack', w: 400),
          quantity: 1,
        ),
        OrderItem(
          variantId: 'v-cl-brown',
          variantName: 'بني',
          imageUrl: _u('bronzeWatch', w: 400),
          quantity: 1,
        ),
      ],
      wholesalePrice: 50000,
      unitSalePrice: 62000,
      deliveryFee: 5000,
      customerName: 'زهراء محمد جاسم',
      customerPhone: '07733334444',
      customerPhone2: '07811110000',
      governorateName: 'البصرة',
      regionName: 'مركز البصرة',
      addressDetails: 'العشار — قرب جامع المقام، زقاق 12',
      notes: 'الاتصال قبل الوصول بنصف ساعة',
      status: OrderStatus.confirmed,
      statusHistory: _history([
        (OrderStatus.pendingReview, 26, null),
        (OrderStatus.confirmed, 20, 'تم التأكيد وجاري التجهيز'),
      ]),
      createdAt: _now.subtract(const Duration(hours: 26)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1047',
      code: 'ORD-1047',
      productId: 'p-sun-lady',
      productName: 'نظارة شمسية نسائية أوفرسايز',
      productImage: _u('sunRose', w: 400),
      items: [
        OrderItem(
          variantId: 'v-sly-black',
          variantName: 'أسود متدرج',
          imageUrl: _u('sunCase', w: 400),
          quantity: 2,
        ),
      ],
      wholesalePrice: 22000,
      unitSalePrice: 35000,
      deliveryFee: 4000,
      customerName: 'نور الهدى سعد',
      customerPhone: '07709998888',
      governorateName: 'بغداد',
      regionName: 'زيونة',
      addressDetails: 'شارع الربيعي — عمارة الياسمين، الطابق الثالث',
      status: OrderStatus.shipped,
      statusHistory: _history([
        (OrderStatus.pendingReview, 78, null),
        (OrderStatus.confirmed, 70, null),
        (OrderStatus.shipped, 30, 'تم التسليم لشركة التوصيل'),
      ]),
      createdAt: _now.subtract(const Duration(hours: 78)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1044',
      code: 'ORD-1044',
      productId: 'p-steel-luxury',
      productName: 'ساعة ستانلس ستيل فاخرة',
      productImage: _u('goldWhite', w: 400),
      items: [
        OrderItem(
          variantId: 'v-sl-gold',
          variantName: 'ذهبي',
          imageUrl: _u('goldWhite', w: 400),
          quantity: 1,
        ),
      ],
      wholesalePrice: 75000,
      unitSalePrice: 95000,
      deliveryFee: 5000,
      customerName: 'كرار حيدر عبد',
      customerPhone: '07722223333',
      governorateName: 'النجف',
      regionName: 'الكوفة',
      addressDetails: 'حي ميسان — قرب مستشفى الكوفة',
      status: OrderStatus.delivered,
      statusHistory: _history([
        (OrderStatus.pendingReview, 130, null),
        (OrderStatus.confirmed, 122, null),
        (OrderStatus.shipped, 96, null),
        (OrderStatus.delivered, 8, 'استلم الزبون ودفع المبلغ'),
      ]),
      createdAt: _now.subtract(const Duration(hours: 130)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1039',
      code: 'ORD-1039',
      productId: 'p-lady-elegant',
      productName: 'ساعة نسائية أنيقة بسوار رفيع',
      productImage: _u('roseChrono', w: 400),
      items: [
        OrderItem(
          variantId: 'v-le-rose',
          variantName: 'ذهبي وردي',
          imageUrl: _u('roseChrono', w: 400),
          quantity: 1,
        ),
      ],
      wholesalePrice: 45000,
      unitSalePrice: 60000,
      deliveryFee: 4000,
      customerName: 'فاطمة عباس حسن',
      customerPhone: '07755556666',
      governorateName: 'بغداد',
      regionName: 'الكاظمية',
      addressDetails: 'قرب ساحة عدن — محلة 314',
      status: OrderStatus.completed,
      statusHistory: _history([
        (OrderStatus.pendingReview, 200, null),
        (OrderStatus.confirmed, 190, null),
        (OrderStatus.shipped, 160, null),
        (OrderStatus.delivered, 120, null),
        (
          OrderStatus.completed,
          72,
          'تمت التسوية وتحويل الربح إلى الرصيد المتاح',
        ),
      ]),
      createdAt: _now.subtract(const Duration(hours: 200)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1036',
      code: 'ORD-1036',
      productId: 'p-smart-band',
      productName: 'سوار ذكي رياضي بحزامين',
      productImage: _u('appleNike', w: 400),
      items: [
        OrderItem(
          variantId: 'v-sb-black',
          variantName: 'أسود + رمادي',
          imageUrl: _u('appleNike', w: 400),
          quantity: 3,
        ),
      ],
      wholesalePrice: 25000,
      unitSalePrice: 35000,
      deliveryFee: 5000,
      customerName: 'مصطفى خالد إبراهيم',
      customerPhone: '07766667777',
      governorateName: 'كركوك',
      regionName: 'مركز كركوك',
      addressDetails: 'حي الواسطي — قرب الملعب',
      status: OrderStatus.completed,
      statusHistory: _history([
        (OrderStatus.pendingReview, 300, null),
        (OrderStatus.confirmed, 290, null),
        (OrderStatus.shipped, 260, null),
        (OrderStatus.delivered, 220, null),
        (OrderStatus.completed, 150, null),
      ]),
      createdAt: _now.subtract(const Duration(hours: 300)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1033',
      code: 'ORD-1033',
      productId: 'p-sun-classic',
      productName: 'نظارة شمسية رجالية كلاسيك',
      productImage: _u('sunWayfarer', w: 400),
      items: [
        OrderItem(
          variantId: 'v-sc-black',
          variantName: 'أسود',
          imageUrl: _u('sunWayfarer', w: 400),
          quantity: 1,
        ),
      ],
      wholesalePrice: 20000,
      unitSalePrice: 33000,
      deliveryFee: 5000,
      customerName: 'سجاد قاسم محمود',
      customerPhone: '07788889999',
      governorateName: 'ذي قار',
      regionName: 'الناصرية',
      addressDetails: 'حي أور — قرب الجسر الجديد',
      status: OrderStatus.deliveryFailed,
      statusHistory: _history([
        (OrderStatus.pendingReview, 240, null),
        (OrderStatus.confirmed, 230, null),
        (OrderStatus.shipped, 200, null),
        (
          OrderStatus.deliveryFailed,
          170,
          'الزبون لا يرد على الاتصال بعد 3 محاولات',
        ),
      ]),
      failReason: 'الزبون لا يرد على الاتصال بعد 3 محاولات',
      createdAt: _now.subtract(const Duration(hours: 240)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1028',
      code: 'ORD-1028',
      productId: 'p-chrono-sport',
      productName: 'ساعة رياضية كرونوغراف',
      productImage: _u('chronoRed', w: 400),
      items: [
        OrderItem(
          variantId: 'v-cs-black',
          variantName: 'أسود/أحمر',
          imageUrl: _u('chronoRed', w: 400),
          quantity: 1,
        ),
      ],
      wholesalePrice: 60000,
      unitSalePrice: 78000,
      deliveryFee: 4000,
      customerName: 'علي حسن فاضل',
      customerPhone: '07700001111',
      governorateName: 'بغداد',
      regionName: 'الدورة',
      addressDetails: 'حي الصحة — قرب المدرسة الابتدائية',
      status: OrderStatus.returned,
      statusHistory: _history([
        (OrderStatus.pendingReview, 400, null),
        (OrderStatus.confirmed, 390, null),
        (OrderStatus.shipped, 360, null),
        (OrderStatus.deliveryFailed, 330, 'الزبون رفض الاستلام'),
        (OrderStatus.returning, 300, null),
        (OrderStatus.returned, 250, 'وصل الراجع وأعيد للمخزون'),
      ]),
      failReason: 'الزبون رفض الاستلام — غيّر رأيه',
      createdAt: _now.subtract(const Duration(hours: 400)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
    Order(
      id: 'o-1025',
      code: 'ORD-1025',
      productId: 'p-bracelet-leather',
      productName: 'أسوارة رجالية جلد مضفور',
      productImage: _u('bronzeWatch', w: 400),
      items: [
        OrderItem(
          variantId: 'v-br-black',
          variantName: 'أسود',
          imageUrl: _u('bronzeWatch', w: 400),
          quantity: 2,
        ),
      ],
      wholesalePrice: 8000,
      unitSalePrice: 14000,
      deliveryFee: 4000,
      customerName: 'يوسف عمار طالب',
      customerPhone: '07799990000',
      governorateName: 'بغداد',
      regionName: 'الأعظمية',
      addressDetails: 'شارع عشرين — قرب الجامع الكبير',
      status: OrderStatus.cancelled,
      statusHistory: _history([
        (OrderStatus.pendingReview, 500, null),
        (OrderStatus.cancelled, 495, 'ألغى البائع الطلب قبل التأكيد'),
      ]),
      createdAt: _now.subtract(const Duration(hours: 500)),
      storeNameSnapshot: 'متجر روائع الساعات',
      sellerPhoneSnapshot: '07712345678',
    ),
  ];

  // ─────────────────────────── المحفظة ───────────────────────────

  static final List<WalletTransaction> transactions = [
    WalletTransaction(
      id: 'tx-12',
      type: WalletTxType.pendingProfit,
      amount: 24000,
      at: _now.subtract(const Duration(hours: 20)),
      orderCode: 'ORD-1049',
      note: 'ربح معلق لحين نجاح التوصيل',
    ),
    WalletTransaction(
      id: 'tx-11',
      type: WalletTxType.pendingProfit,
      amount: 26000,
      at: _now.subtract(const Duration(hours: 70)),
      orderCode: 'ORD-1047',
    ),
    WalletTransaction(
      id: 'tx-10',
      type: WalletTxType.pendingProfit,
      amount: 20000,
      at: _now.subtract(const Duration(hours: 122)),
      orderCode: 'ORD-1044',
    ),
    WalletTransaction(
      id: 'tx-09',
      type: WalletTxType.profitReleased,
      amount: 15000,
      at: _now.subtract(const Duration(hours: 72)),
      orderCode: 'ORD-1039',
      note: 'تحول الربح إلى الرصيد المتاح بعد التسوية',
    ),
    WalletTransaction(
      id: 'tx-08',
      type: WalletTxType.profitReleased,
      amount: 30000,
      at: _now.subtract(const Duration(hours: 150)),
      orderCode: 'ORD-1036',
    ),
    WalletTransaction(
      id: 'tx-07',
      type: WalletTxType.reversal,
      amount: 13000,
      at: _now.subtract(const Duration(hours: 170)),
      orderCode: 'ORD-1033',
      note: 'عكس ربح معلق — فشل التوصيل (لا خصومات عليك)',
    ),
    WalletTransaction(
      id: 'tx-06',
      type: WalletTxType.withdrawal,
      amount: 100000,
      at: _now.subtract(const Duration(days: 12)),
      note: 'سحب عبر زين كاش',
    ),
    WalletTransaction(
      id: 'tx-05',
      type: WalletTxType.profitReleased,
      amount: 55000,
      at: _now.subtract(const Duration(days: 14)),
      orderCode: 'ORD-1019',
    ),
    WalletTransaction(
      id: 'tx-04',
      type: WalletTxType.profitReleased,
      amount: 42000,
      at: _now.subtract(const Duration(days: 18)),
      orderCode: 'ORD-1014',
    ),
  ];

  static final List<Withdrawal> withdrawals = [
    Withdrawal(
      id: 'wd-3',
      amount: 50000,
      method: 'زين كاش',
      accountDetail: '07712345678',
      status: WithdrawalStatus.pending,
      requestedAt: _now.subtract(const Duration(hours: 30)),
    ),
    Withdrawal(
      id: 'wd-2',
      amount: 100000,
      method: 'زين كاش',
      accountDetail: '07712345678',
      status: WithdrawalStatus.paid,
      requestedAt: _now.subtract(const Duration(days: 13)),
      processedAt: _now.subtract(const Duration(days: 12)),
    ),
    Withdrawal(
      id: 'wd-1',
      amount: 75000,
      method: 'ماستر كارد',
      accountDetail: '5321 **** **** 1102',
      status: WithdrawalStatus.paid,
      requestedAt: _now.subtract(const Duration(days: 34)),
      processedAt: _now.subtract(const Duration(days: 33)),
    ),
  ];

  // ─────────────────────────── الإشعارات ───────────────────────────

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'n-8',
      title: 'طلبك ORD-1047 مع شركة التوصيل',
      body:
          'تم تسليم الطلب لشركة التوصيل وهو بطريقه إلى زبونك في بغداد — زيونة.',
      type: NotificationType.order,
      at: _now.subtract(const Duration(hours: 30)),
      targetOrderId: 'o-1047',
    ),
    AppNotification(
      id: 'n-7',
      title: 'ربح جديد أصبح متاحاً 🎉',
      body: 'تحول ربح طلب ORD-1039 بقيمة 15,000 د.ع إلى رصيدك المتاح.',
      type: NotificationType.wallet,
      at: _now.subtract(const Duration(hours: 72)),
      targetOrderId: 'o-1039',
    ),
    AppNotification(
      id: 'n-6',
      title: 'منتج جديد: علبة عرض ساعات فاخرة',
      body:
          'وصل حديثاً — علبة عرض بست خانات بسعر جملة 18,000 د.ع. كن أول من يسوّقها!',
      type: NotificationType.product,
      at: _now.subtract(const Duration(days: 4)),
      targetProductId: 'p-watch-box',
      isRead: true,
    ),
    AppNotification(
      id: 'n-5',
      title: 'تنبيه مخزون: الساعة الذكية النسائية',
      body:
          'نفد مخزون «ساعة ذكية نسائية بإطار معدني» مؤقتاً. سنعلمك فور توفرها.',
      type: NotificationType.product,
      at: _now.subtract(const Duration(days: 5)),
      targetProductId: 'p-smart-lady',
      isRead: true,
    ),
    AppNotification(
      id: 'n-4',
      title: 'تحديث طلب ORD-1033',
      body: 'تعذر توصيل الطلب — الزبون لا يرد. لا توجد أي خصومات عليك.',
      type: NotificationType.order,
      at: _now.subtract(const Duration(hours: 170)),
      targetOrderId: 'o-1033',
      isRead: true,
    ),
    AppNotification(
      id: 'n-3',
      title: 'أهلاً بك في المنصة 👋',
      body: 'تمت الموافقة على حسابك. تصفح المنتجات وابدأ التسويق الآن.',
      type: NotificationType.system,
      at: _now.subtract(const Duration(days: 94)),
      isRead: true,
    ),
  ];

  // ─────────────────────────── البانرات ───────────────────────────

  static final List<PromoBanner> banners = [
    PromoBanner(
      id: 'b-1',
      imageUrl: _u('chronoSteel'),
      title: 'تشكيلة الساعات الفاخرة',
      subtitle: 'هوامش ربح تصل إلى 20,000 د.ع للقطعة',
      targetCategoryId: 'cat-watches',
    ),
    PromoBanner(
      id: 'b-2',
      imageUrl: _u('smartWrist'),
      title: 'الساعات الذكية الأكثر مبيعاً',
      subtitle: 'مطلوبة بكثرة على صفحات إنستغرام',
      targetCategoryId: 'cat-smart',
    ),
    PromoBanner(
      id: 'b-3',
      imageUrl: _u('chronoRed'),
      title: 'وصل حديثاً',
      subtitle: 'كرونوغراف رياضي بمخزون محدود',
      targetProductId: 'p-chrono-sport',
    ),
  ];

  // ─────────────────────────── الأسئلة الشائعة ───────────────────────────

  static const List<FaqItem> faq = [
    FaqItem(
      question: 'متى يتحول ربحي من معلق إلى متاح؟',
      answer:
          'بعد نجاح توصيل الطلب واستلام المنصة المبلغ من شركة التوصيل ومرور خمسة أيام للتسوية، يتحول الربح إلى رصيدك المتاح ويصلك إشعار.',
    ),
    FaqItem(
      question: 'ماذا يحدث إذا رفض الزبون الطلب؟',
      answer:
          'لا تتحمل أي شيء: لا تُخصم أجرة التوصيل أو الإرجاع من محفظتك، ويُلغى الربح المعلق لهذا الطلب فقط.',
    ),
    FaqItem(
      question: 'هل يظهر اسم المنصة للزبون؟',
      answer:
          'لا — يُطبع اسم متجرك ورقم هاتفك على بوليصة الشحن قدر الإمكان وحسب إمكانيات شركة التوصيل، ليصل الطلب باسم متجرك.',
    ),
    FaqItem(
      question: 'ما الحد الأدنى للسحب؟',
      answer: 'الحد الأدنى الحالي هو 10,000 د.ع من الرصيد المتاح.',
    ),
    FaqItem(
      question: 'هل أستطيع تعديل الطلب بعد إرساله؟',
      answer:
          'قبل تأكيد الإدارة يمكنك الإلغاء مباشرة. بعد التأكيد وقبل الشحن يمكنك تقديم طلب تعديل/إلغاء تراجعه الإدارة.',
    ),
  ];

  // ─────────────────────────── نصوص السياسات ───────────────────────────

  static const String policiesText = '''
١. المنصة هي المورد الوحيد للمنتجات، والبائع يسوّق المنتجات لزبائنه ويُدخل طلباتهم عبر التطبيق.

٢. ربح البائع هو الفرق بين سعر البيع الذي يحدده وسعر الجملة، ولا يجوز البيع بأقل من سعر الجملة.

٣. أجرة التوصيل تُضاف على الزبون فوق سعر البيع ولا تُخصم من ربح البائع.

٤. يظهر الربح معلقاً حتى نجاح التوصيل واستلام المنصة المبلغ من شركة التوصيل، ثم يتحول إلى الرصيد المتاح.

٥. في حال فشل التوصيل أو إرجاع الطلب لا يتحمل البائع أي رسوم، ويُلغى الربح المعلق للطلب فقط.

٦. تحتفظ المنصة بحق مراجعة الطلبات ورفض أي طلب مخالف أو مشتبه به.

٧. يُطبع اسم متجر البائع على بوليصة الشحن قدر الإمكان وحسب إمكانيات شركة التوصيل.

٨. الحسابات التي تتعمد إدخال طلبات وهمية تُعرَّض للإيقاف.
''';
}
