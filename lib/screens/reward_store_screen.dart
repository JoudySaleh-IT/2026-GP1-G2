import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/store_catalog.dart';
import '../models/store_item.dart';
import '../services/reward_store_service.dart';
import '../widgets/child_store_avatar.dart';

class RewardStoreScreen extends StatefulWidget {
  final String childId;

  const RewardStoreScreen({super.key, required this.childId});

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen> {
  static const Color purple = Color(0xFF511281);
  static const Color cream = Color(0xFFFCF9EA);
  static const Color coral = Color(0xFFFF6969);

  final RewardStoreService _storeService = RewardStoreService();

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _childStream;

  // Main navigation: Store / My Items
  bool showMyItems = false;

  // Category selection
  StoreItemType selectedType = StoreItemType.avatar;

  // Outfit preview selection
  String? selectedAvatarId;
  String? selectedBackgroundId;

  bool applyingOutfit = false;

  static const List<Color> sectionColors = [
    Color(0xFFF7F0FF),
    Color(0xFFFFF3EC),
    Color(0xFFFFF7E5),
    Color(0xFFF0F8F3),
    Color(0xFFFFF0F4),
    Color(0xFFF0F5FF),
    Color(0xFFF4F1FF),
    Color(0xFFFFF7EC),
  ];

  @override
  void initState() {
    super.initState();
    _childStream = _storeService.watchChild(widget.childId);
  }

  // ============================================================
  // Helpers
  // ============================================================

  int _balance(Map<String, dynamic> data) {
    return (data['availablePoints'] as num?)?.toInt() ??
        (data['points'] as num?)?.toInt() ??
        0;
  }

  bool _isOwned(StoreItem item, Map<String, dynamic> data) {
    return _storeService.isItemOwned(childData: data, item: item);
  }

  bool _isEquipped(StoreItem item, Map<String, dynamic> data) {
    final field = item.type == StoreItemType.avatar
        ? 'equippedAvatarId'
        : 'equippedBackgroundId';

    return data[field]?.toString() == item.id;
  }

  List<StoreItem> _ownedAvatars(Map<String, dynamic> data) {
    return StoreCatalog.avatars.where((item) => _isOwned(item, data)).toList();
  }

  List<StoreItem> _ownedBackgrounds(Map<String, dynamic> data) {
    return StoreCatalog.backgrounds
        .where((item) => _isOwned(item, data))
        .toList();
  }

  String? _validSelection(
    String? selectedId,
    String? equippedId,
    List<StoreItem> owned,
  ) {
    if (selectedId != null && owned.any((item) => item.id == selectedId)) {
      return selectedId;
    }

    if (equippedId != null && owned.any((item) => item.id == equippedId)) {
      return equippedId;
    }

    return owned.isNotEmpty ? owned.first.id : null;
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: error ? coral : purple,
      ),
    );
  }

  // ============================================================
  // Main Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: cream,
        body: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _childStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: purple),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'تعذر تحميل بيانات المتجر',
                        style: TextStyle(fontFamily: 'Tajawal', color: purple),
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        'لم يتم العثور على حساب الطفل',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                    );
                  }

                  final data = snapshot.data!.data()!;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              _buildWelcomeCard(),

                              const SizedBox(height: 12),

                              _buildPointsCard(data),

                              const SizedBox(height: 16),

                              _buildMainTabs(),

                              const SizedBox(height: 16),

                              if (showMyItems)
                                _buildMyItems(data)
                              else
                                _buildCategoryTabs(),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Store avatars: build animal groups lazily.
                      if (!showMyItems && selectedType == StoreItemType.avatar)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final animal = StoreCatalog.animals[index];

                              return _buildAnimalSection(animal, index, data);
                            }, childCount: StoreCatalog.animals.length),
                          ),
                        ),

                      // Store backgrounds.
                      if (!showMyItems &&
                          selectedType == StoreItemType.background)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverToBoxAdapter(
                            child: _buildBackgroundGrid(
                              StoreCatalog.backgrounds,
                              data,
                              closetMode: false,
                            ),
                          ),
                        ),

                      if (showMyItems)
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 14,
        right: 8,
        left: 16,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),

          const SizedBox(width: 5),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متجر المكافآت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'تسوّق ونسّق شخصيتك!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Welcome Card
  // ============================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: purple.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 65, height: 92, child: _SimpleCuteBunny()),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هيا نختار مكافأتك! ✨',
                  style: TextStyle(
                    color: purple,
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'اجمع النقاط، اشترِ ما يعجبك، ثم نسّق شخصيتك!',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontFamily: 'Tajawal',
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Real Points Balance
  // ============================================================

  Widget _buildPointsCard(Map<String, dynamic> data) {
    final balance = _balance(data);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFE9A92E), size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'نقاطك المتاحة للمتجر',
              style: TextStyle(
                color: purple,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$balance',
            style: const TextStyle(
              color: purple,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Store / My Items Tabs
  // ============================================================

  Widget _buildMainTabs() {
    return Row(
      children: [
        _mainTab('المتجر', Icons.storefront_rounded, !showMyItems, () {
          setState(() => showMyItems = false);
        }),
        const SizedBox(width: 10),
        _mainTab('مقتنياتي', Icons.inventory_2_rounded, showMyItems, () {
          setState(() => showMyItems = true);
        }),
      ],
    );
  }

  Widget _mainTab(
    String title,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? purple : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: purple.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : purple),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white : purple,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Avatar / Background Tabs
  // ============================================================

  Widget _buildCategoryTabs() {
    return Row(
      children: [
        _categoryTab('الشخصيات', Icons.pets_rounded, StoreItemType.avatar),
        const SizedBox(width: 10),
        _categoryTab(
          'الخلفيات',
          Icons.wallpaper_rounded,
          StoreItemType.background,
        ),
      ],
    );
  }

  Widget _categoryTab(String label, IconData icon, StoreItemType type) {
    final selected = selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selectedType = type);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE9DAF8) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? purple : purple.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: purple),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: purple,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Store
  // ============================================================

  Widget _buildStore(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildCategoryTabs(),
        const SizedBox(height: 16),

        if (selectedType == StoreItemType.avatar)
          ...List.generate(
            StoreCatalog.animals.length,
            (index) =>
                _buildAnimalSection(StoreCatalog.animals[index], index, data),
          )
        else
          _buildBackgroundGrid(
            StoreCatalog.backgrounds,
            data,
            closetMode: false,
          ),
      ],
    );
  }

  Widget _buildAnimalSection(
    String animal,
    int index,
    Map<String, dynamic> data,
  ) {
    final items = <StoreItem>[
      StoreCatalog.findById('${animal}_basic')!,
      StoreCatalog.findById('${animal}_glasses')!,
      StoreCatalog.findById('${animal}_hat')!,
    ];

    const variants = ['الأساسي', 'النظارة', 'القبعة'];

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: sectionColors[index % sectionColors.length],
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: purple.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StoreCatalog.animalNames[animal] ?? animal,
            style: const TextStyle(
              color: purple,
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 2 ? 0 : 6),
                  child: _buildItemCard(items[i], data, label: variants[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid(
    List<StoreItem> items,
    Map<String, dynamic> data, {
    required bool closetMode,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: closetMode ? 210 : 225,
          ),
          itemBuilder: (context, index) {
            return _buildItemCard(items[index], data, closetMode: closetMode);
          },
        );
      },
    );
  }

  Future<void> _confirmItemSelection(StoreItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'تأكيد الاختيار ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: purple,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 150, height: 150, child: _itemImage(item)),
              const SizedBox(height: 12),
              Text(
                'هل تريد اختيار ${item.name}؟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: purple,
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'تأكيد الاختيار',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      if (item.type == StoreItemType.avatar) {
        selectedAvatarId = item.id;
      } else {
        selectedBackgroundId = item.id;
      }
    });
  }

  // ============================================================
  // Item Cards
  // ============================================================

  Widget _buildItemCard(
    StoreItem item,
    Map<String, dynamic> data, {
    String? label,
    bool closetMode = false,
    bool selected = false,
  }) {
    final owned = _isOwned(item, data);
    final equipped = _isEquipped(item, data);

    return InkWell(
      onTap: () {
        if (closetMode) {
          _confirmItemSelection(item);
        } else {
          _showItemDialog(item, data);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: closetMode ? 200 : 175,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1E5FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? purple : purple.withValues(alpha: 0.10),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: closetMode ? 115 : 90,
                width: double.infinity,
                child: _itemImage(item),
              ),

              const SizedBox(height: 5),

              Text(
                label ?? item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                ),
              ),

              const SizedBox(height: 5),

              if (closetMode)
                _statusChip(
                  selected
                      ? 'تم الاختيار'
                      : equipped
                      ? 'مستخدم حاليًا'
                      : 'اختيار',
                  selected || equipped,
                )
              else if (equipped)
                _statusChip('مستخدم حاليًا', true)
              else if (owned)
                _statusChip('مملوك', true)
              else
                _priceTag(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF7ED) : const Color(0xFFF3EBFA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? const Color(0xFF38865B) : purple,
        ),
      ),
    );
  }

  Widget _itemImage(StoreItem item) {
    final isBackground = item.type == StoreItemType.background;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF9F5FC),
        child: Padding(
          padding: EdgeInsets.all(isBackground ? 0 : 3),
          child: Image.asset(
            item.imagePath,
            fit: isBackground ? BoxFit.cover : BoxFit.contain,
            cacheWidth: 300,
            cacheHeight: 300,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, error, stackTrace) {
              debugPrint('Missing store image ${item.imagePath}: $error');
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFAA96BD),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _priceTag(StoreItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: item.isFree ? const Color(0xFFEAF7ED) : const Color(0xFFFFF1C9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!item.isFree) ...[
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE9A92E)),
            const SizedBox(width: 3),
          ],
          Text(
            item.isFree ? 'مجاني' : '${item.price}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: item.isFree
                  ? const Color(0xFF38865B)
                  : const Color(0xFF906414),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Purchase Dialog
  // ============================================================

  void _showItemDialog(StoreItem item, Map<String, dynamic> data) {
    bool processing = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final owned = _isOwned(item, data);
            final equipped = _isEquipped(item, data);
            final balance = _balance(data);
            final canAfford = balance >= item.price;

            debugPrint('========== STORE DEBUG ==========');
            debugPrint('Child ID: ${widget.childId}');
            debugPrint('Item: ${item.id}');
            debugPrint('Item price: ${item.price}');
            debugPrint('Total points: ${data['points']}');
            debugPrint('Available points: ${data['availablePoints']}');
            debugPrint('Calculated balance: $balance');
            debugPrint('Can afford: $canAfford');
            debugPrint('=================================');

            return AlertDialog(
              backgroundColor: cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 190, height: 190, child: _itemImage(item)),

                  const SizedBox(height: 12),

                  if (owned) _statusChip('مملوك', true) else _priceTag(item),

                  const SizedBox(height: 12),

                  Text(
                    'رصيدك المتاح: $balance نقطة',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: purple,
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (!owned)
                    Text(
                      'سعر العنصر: ${item.price} نقطة',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                      ),
                    ),

                  if (!owned && !canAfford) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'نقاطك غير كافية',
                      style: TextStyle(color: coral, fontFamily: 'Tajawal'),
                    ),
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: processing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: processing || (!owned && !canAfford)
                      ? null
                      : () async {
                          if (owned) {
                            Navigator.pop(dialogContext);

                            if (!mounted) return;

                            setState(() {
                              showMyItems = true;
                              selectedType = item.type;
                            });
                            return;
                          }

                          setDialogState(() {
                            processing = true;
                          });

                          try {
                            await _storeService.selectItem(
                              childId: widget.childId,
                              item: item,
                            );

                            if (!mounted) return;

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            _showMessage(
                              'تم شراء ${item.name}! تجده الآن في مقتنياتي',
                            );
                          } catch (e) {
                            _showMessage(
                              e.toString().replaceFirst('Exception: ', ''),
                              error: true,
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                processing = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    processing
                        ? 'جاري الشراء...'
                        : equipped
                        ? 'عرض في مقتنياتي'
                        : owned
                        ? 'اذهب لمقتنياتي'
                        : 'شراء بـ ${item.price} نقطة',
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // My Items / Closet
  // ============================================================

  Widget _buildMyItems(Map<String, dynamic> data) {
    final ownedAvatars = _ownedAvatars(data);
    final ownedBackgrounds = _ownedBackgrounds(data);

    final avatarId = _validSelection(
      selectedAvatarId,
      data['equippedAvatarId']?.toString(),
      ownedAvatars,
    );

    final backgroundId = _validSelection(
      selectedBackgroundId,
      data['equippedBackgroundId']?.toString(),
      ownedBackgrounds,
    );

    final equippedAvatarId = data['equippedAvatarId']?.toString();

    final equippedBackgroundId = data['equippedBackgroundId']?.toString();

    final isCurrentOutfit =
        avatarId == equippedAvatarId && backgroundId == equippedBackgroundId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOutfitPreview(avatarId, backgroundId, isCurrentOutfit),

        const SizedBox(height: 16),

        _buildCategoryTabs(),

        const SizedBox(height: 16),

        if (selectedType == StoreItemType.avatar)
          _buildClosetGrid(ownedAvatars, data, selectedId: avatarId)
        else
          _buildClosetGrid(ownedBackgrounds, data, selectedId: backgroundId),
      ],
    );
  }

  Widget _buildClosetGrid(
    List<StoreItem> items,
    Map<String, dynamic> data, {
    required String? selectedId,
  }) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'ما عندك عناصر في هذا القسم بعد',
            style: TextStyle(fontFamily: 'Tajawal', color: purple),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 190,
          ),
          itemBuilder: (context, index) {
            return _buildItemCard(
              items[index],
              data,
              closetMode: true,
              selected: items[index].id == selectedId,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Outfit Preview
  // ============================================================

  Widget _buildOutfitPreview(
    String? avatarId,
    String? backgroundId,
    bool isCurrentOutfit,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: purple.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          const Text(
            'نسّق شخصيتك ✨',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: purple,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'اختَر شخصيتك وخلفيتك المفضلة ثم طبّق التنسيق',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Color(0xFF777777),
            ),
          ),

          const SizedBox(height: 18),

          StoreAvatarImage(
            avatar: '🌟',
            avatarId: avatarId,
            backgroundId: backgroundId,
            size: 150,
            backgroundColor: cream,
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets_rounded, size: 16, color: purple),
              const SizedBox(width: 5),
              Text(
                avatarId == null
                    ? 'اختَر شخصية'
                    : StoreCatalog.findById(avatarId)?.name ?? 'شخصية',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  color: purple,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.wallpaper_rounded, size: 16, color: purple),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  backgroundId == null
                      ? 'اختَر خلفية'
                      : StoreCatalog.findById(backgroundId)?.name ?? 'خلفية',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    color: purple,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  applyingOutfit ||
                      avatarId == null ||
                      backgroundId == null ||
                      isCurrentOutfit
                  ? null
                  : () => _applyOutfit(avatarId, backgroundId),
              icon: Icon(
                isCurrentOutfit
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
              ),
              label: Text(
                applyingOutfit
                    ? 'جاري التطبيق...'
                    : isCurrentOutfit
                    ? 'هذا تنسيقك الحالي'
                    : 'تطبيق التنسيق',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE1D6EA),
                disabledForegroundColor: purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyOutfit(String avatarId, String backgroundId) async {
    if (applyingOutfit) return;

    setState(() => applyingOutfit = true);

    try {
      await _storeService.equipOutfit(
        childId: widget.childId,
        avatarId: avatarId,
        backgroundId: backgroundId,
      );

      _showMessage('تم تطبيق تنسيق شخصيتك بنجاح! ✨');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() => applyingOutfit = false);
      }
    }
  }
}

// ============================================================
// Decorative Bunny - Same Faseeh Character
// ============================================================

class _SimpleCuteBunny extends StatelessWidget {
  const _SimpleCuteBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFF8B55B3);
    const Color innerEar = Color(0xFFFFA1B7);
    const Color details = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          right: 11,
          child: Container(
            width: 18,
            height: 34,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 22,
                decoration: BoxDecoration(
                  color: innerEar.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 0,
          left: 11,
          child: Container(
            width: 18,
            height: 34,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 22,
                decoration: BoxDecoration(
                  color: innerEar.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          child: Container(
            width: 42,
            height: 27,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),

        Positioned(
          top: 25,
          child: Container(
            width: 55,
            height: 52,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 19,
                  right: 13,
                  child: CircleAvatar(radius: 3, backgroundColor: details),
                ),
                const Positioned(
                  top: 19,
                  left: 13,
                  child: CircleAvatar(radius: 3, backgroundColor: details),
                ),
                Positioned(
                  top: 31,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  top: 31,
                  left: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Positioned(
                  top: 27,
                  left: 24,
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFFFF7890),
                  ),
                ),
                const Positioned(
                  top: 33,
                  left: 20,
                  child: SizedBox(
                    width: 15,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: details, width: 1.4),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
