enum StoreItemType {
  avatar,
  background,
  frame, // For future customization
}

class StoreItem {
  final String id;
  final String name;
  final StoreItemType type;
  final int price;
  final String imagePath;

  const StoreItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.imagePath,
  });

  bool get isFree => price == 0;
}
