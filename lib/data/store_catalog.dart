import '../models/store_item.dart';

class StoreCatalog {
  static const List<String> animals = [
    'fox',
    'panda',
    'tiger',
    'lion',
    'rabbit',
    'raccoon',
    'koala',
    'bear',
  ];

  static const Map<String, String> animalNames = {
    'fox': 'الثعلب',
    'panda': 'الباندا',
    'tiger': 'النمر',
    'lion': 'الأسد',
    'rabbit': 'الأرنب',
    'raccoon': 'الراكون',
    'koala': 'الكوالا',
    'bear': 'الدب',
  };

  static const Map<String, String> backgroundNames = {
    'lavender_stars': 'النجوم البنفسجية',
    'blue_clouds': 'الغيوم الزرقاء',
    'peach_dots': 'النقاط الملونة',
    'pink_hearts': 'القلوب الوردية',
    'mint_leaves': 'الأوراق الخضراء',
    'aqua_waves': 'الأمواج',
    'blue_paws': 'آثار الأقدام',
    'spring_flowers': 'زهور الربيع',
    'purple_sparkles': 'اللمعات البنفسجية',
    'pastel_rainbow': 'قوس قزح',
    'space_planets': 'الكواكب',
    'golden_crowns': 'التيجان الذهبية',
  };

  static const Map<String, int> backgroundPrices = {
    'lavender_stars': 0,
    'blue_clouds': 0,
    'peach_dots': 0,
    'pink_hearts': 50,
    'mint_leaves': 50,
    'aqua_waves': 50,
    'blue_paws': 75,
    'spring_flowers': 75,
    'purple_sparkles': 100,
    'pastel_rainbow': 100,
    'space_planets': 125,
    'golden_crowns': 150,
  };

  static final List<StoreItem> avatars = [
    for (final animal in animals) ...[
      StoreItem(
        id: '${animal}_basic',
        name: animalNames[animal]!,
        type: StoreItemType.avatar,
        price: 0,
        imagePath: 'assets/store/avatars/${animal}_basic.png',
      ),
      StoreItem(
        id: '${animal}_hat',
        name: '${animalNames[animal]} - قبعة',
        type: StoreItemType.avatar,
        price: 150,
        imagePath: 'assets/store/avatars/${animal}_hat.png',
      ),
      StoreItem(
        id: '${animal}_glasses',
        name: '${animalNames[animal]} - نظارة',
        type: StoreItemType.avatar,
        price: 120,
        imagePath: 'assets/store/avatars/${animal}_glasses.png',
      ),
    ],
  ];

  static final List<StoreItem> backgrounds = [
    for (final entry in backgroundPrices.entries)
      StoreItem(
        id: entry.key,
        name: backgroundNames[entry.key]!,
        type: StoreItemType.background,
        price: entry.value,
        imagePath: 'assets/store/backgrounds/${entry.key}.png',
      ),
  ];

  static final List<StoreItem> allItems = [...avatars, ...backgrounds];

  static StoreItem? findById(String id) {
    for (final item in allItems) {
      if (item.id == id) return item;
    }
    return null;
  }
}
