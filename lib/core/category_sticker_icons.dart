import 'package:flutter/material.dart';

import '../data/models.dart';

/// One exhaustive visual contract for every sticker value accepted by the
/// backend. Automatic selection is resolved from the category name by the
/// presentation layer, while `none` intentionally has no icon.
IconData? categoryStickerIconFor(CategoryStickerKey sticker) =>
    switch (sticker) {
      CategoryStickerKey.auto || CategoryStickerKey.none => null,
      CategoryStickerKey.newArrival => Icons.auto_awesome_rounded,
      CategoryStickerKey.premium => Icons.workspace_premium_rounded,
      CategoryStickerKey.favorite => Icons.favorite_rounded,
      CategoryStickerKey.star => Icons.star_rounded,
      CategoryStickerKey.gift => Icons.redeem_rounded,
      CategoryStickerKey.electronics => Icons.memory_rounded,
      CategoryStickerKey.smart => Icons.bolt_rounded,
      CategoryStickerKey.phone => Icons.smartphone_rounded,
      CategoryStickerKey.computer => Icons.desktop_windows_rounded,
      CategoryStickerKey.laptop => Icons.laptop_mac_rounded,
      CategoryStickerKey.tablet => Icons.tablet_mac_rounded,
      CategoryStickerKey.tv => Icons.tv_rounded,
      CategoryStickerKey.camera => Icons.photo_camera_rounded,
      CategoryStickerKey.audio => Icons.headphones_rounded,
      CategoryStickerKey.gaming => Icons.sports_esports_rounded,
      CategoryStickerKey.network => Icons.wifi_rounded,
      CategoryStickerKey.charger => Icons.electrical_services_rounded,
      CategoryStickerKey.home => Icons.home_rounded,
      CategoryStickerKey.appliances => Icons.kitchen_rounded,
      CategoryStickerKey.furniture => Icons.chair_rounded,
      CategoryStickerKey.box => Icons.inventory_2_rounded,
      CategoryStickerKey.men => Icons.male_rounded,
      CategoryStickerKey.women => Icons.female_rounded,
      CategoryStickerKey.kids => Icons.child_care_rounded,
      CategoryStickerKey.fashion => Icons.checkroom_rounded,
      CategoryStickerKey.bags => Icons.shopping_bag_rounded,
      CategoryStickerKey.footwear => Icons.hiking_rounded,
      CategoryStickerKey.beauty => Icons.palette_rounded,
      CategoryStickerKey.watch => Icons.watch_rounded,
      CategoryStickerKey.glasses => Icons.visibility_outlined,
      CategoryStickerKey.accessories => Icons.diamond_rounded,
      CategoryStickerKey.sport => Icons.fitness_center_rounded,
      CategoryStickerKey.toys => Icons.toys_rounded,
      CategoryStickerKey.books => Icons.menu_book_rounded,
      CategoryStickerKey.pets => Icons.pets_rounded,
      CategoryStickerKey.automotive => Icons.directions_car_rounded,
      CategoryStickerKey.tools => Icons.build_rounded,
      CategoryStickerKey.food => Icons.restaurant_rounded,
      CategoryStickerKey.grocery => Icons.shopping_basket_rounded,
      CategoryStickerKey.health => Icons.health_and_safety_rounded,
      CategoryStickerKey.office => Icons.business_center_rounded,
      CategoryStickerKey.travel => Icons.luggage_rounded,
    };
