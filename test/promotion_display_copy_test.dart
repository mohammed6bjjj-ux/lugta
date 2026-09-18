import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/promotion_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => appSettings.language = AppLanguage.ar);
  test('optional copy localizes without changing the reward snapshot', () {
    final grant = promotionGrantFromJson({
      'reward_type': 'free_delivery', 'reward_value': 1,
      'promotions': {
        'name_ar': 'original', 'name_en': 'Original English',
        'description_ar': 'terms', 'reward_value': 99,
        'promotion_display_copy': {'copy': {
          'title_ar': 'خصم التوصيل', 'title_en': 'Delivery discount',
          'label_ar': 'خصم حتى ٢٬٥٠٠ د.ع', 'description_ar': 'شروط معدلة',
        }},
      },
    });
    expect(grant.rewardValue, 1);
    expect(grant.rewardType, 'free_delivery');
    expect(grant.promotion!.localizedName, 'خصم التوصيل');
    expect(grant.promotion!.localizedRewardLabel, 'خصم حتى ٢٬٥٠٠ د.ع');
    appSettings.language = AppLanguage.en;
    expect(grant.promotion!.localizedName, 'Delivery discount');
    expect(grant.promotion!.localizedDescription, 'شروط معدلة');
    appSettings.language = AppLanguage.ckb;
    expect(grant.promotion!.localizedName, 'خصم التوصيل');
  });
  test('missing, empty and malformed copy preserve originals', () {
    for (final value in [null, [], {}, {'copy': {}}, {'copy': {'title_ar': 5, 'label_ar': ' '}}]) {
      final promotion = promotionFromJson({'name_ar':'original', 'promotion_display_copy':value});
      expect(promotion.localizedName, 'original');
      expect(promotion.localizedRewardLabel, isNull);
    }
    expect(promotionFromJson({'promotion_display_copy':[{'copy':{'title_ar':'array'}}]}).localizedName, 'array');
  });
}
