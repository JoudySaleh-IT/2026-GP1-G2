import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/store_catalog.dart';
import '../models/store_item.dart';

class RewardStoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _childRef(String childId) {
    return _db.collection('children').doc(childId);
  }

  DocumentReference<Map<String, dynamic>> _publicRef(String childId) {
    return _db.collection('child_public_profiles').doc(childId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchChild(String childId) {
    return _childRef(childId).snapshots();
  }

  // ============================================================
  // CHECK OWNERSHIP
  // Free items are always available.
  // ============================================================

  bool isItemOwned({
    required Map<String, dynamic> childData,
    required StoreItem item,
  }) {
    final owned = List<String>.from(childData['ownedStoreItems'] ?? []);

    return item.isFree || owned.contains(item.id);
  }

  // ============================================================
  // PURCHASE ITEM
  // Deduct points and save ownership only.
  // Do NOT equip the item automatically.
  // ============================================================

  Future<void> selectItem({
    required String childId,
    required StoreItem item,
  }) async {
    final catalogItem = StoreCatalog.findById(item.id);

    if (catalogItem == null || catalogItem.type != item.type) {
      throw Exception('المكافأة غير موجودة');
    }

    final childRef = _childRef(childId);

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childRef);

      if (!childSnapshot.exists) {
        throw Exception('لم يتم العثور على حساب الطفل');
      }

      final data = childSnapshot.data()!;

      final owned = List<String>.from(data['ownedStoreItems'] ?? []);

      // Already purchased or available for free.
      final bool alreadyOwned =
          catalogItem.isFree || owned.contains(catalogItem.id);

      if (alreadyOwned) {
        // No duplicate purchase and no deduction.
        return;
      }

      final int balance =
          (data['availablePoints'] as num?)?.toInt() ??
          (data['points'] as num?)?.toInt() ??
          0;

      final int cost = catalogItem.price;

      if (balance < cost) {
        throw Exception('نقاطك غير كافية لهذه المكافأة');
      }

      transaction.update(childRef, {
        'availablePoints': balance - cost,
        'ownedStoreItems': FieldValue.arrayUnion([catalogItem.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // EQUIP ONE OWNED ITEM
  // No points are deducted.
  // Updates both private and public profiles.
  // ============================================================

  Future<void> equipOwnedItem({
    required String childId,
    required StoreItem item,
  }) async {
    final catalogItem = StoreCatalog.findById(item.id);

    if (catalogItem == null || catalogItem.type != item.type) {
      throw Exception('المكافأة غير موجودة');
    }

    final childRef = _childRef(childId);
    final publicRef = _publicRef(childId);

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childRef);

      final publicSnapshot = await transaction.get(publicRef);

      if (!childSnapshot.exists) {
        throw Exception('لم يتم العثور على حساب الطفل');
      }

      if (!publicSnapshot.exists) {
        throw Exception('ملف الطفل العام غير موجود');
      }

      final data = childSnapshot.data()!;

      if (!isItemOwned(childData: data, item: catalogItem)) {
        throw Exception('يجب شراء العنصر أولًا');
      }

      final String field = catalogItem.type == StoreItemType.avatar
          ? 'equippedAvatarId'
          : 'equippedBackgroundId';

      transaction.update(childRef, {
        field: catalogItem.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(publicRef, {field: catalogItem.id});
    });
  }

  // ============================================================
  // EQUIP OUTFIT
  // Apply an owned avatar and an owned background together.
  // No points are deducted.
  // ============================================================

  Future<void> equipOutfit({
    required String childId,
    required String avatarId,
    required String backgroundId,
  }) async {
    final avatarItem = StoreCatalog.findById(avatarId);
    final backgroundItem = StoreCatalog.findById(backgroundId);

    if (avatarItem == null || avatarItem.type != StoreItemType.avatar) {
      throw Exception('الشخصية المختارة غير موجودة');
    }

    if (backgroundItem == null ||
        backgroundItem.type != StoreItemType.background) {
      throw Exception('الخلفية المختارة غير موجودة');
    }

    final childRef = _childRef(childId);
    final publicRef = _publicRef(childId);

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childRef);

      final publicSnapshot = await transaction.get(publicRef);

      if (!childSnapshot.exists) {
        throw Exception('لم يتم العثور على حساب الطفل');
      }

      if (!publicSnapshot.exists) {
        throw Exception('ملف الطفل العام غير موجود');
      }

      final data = childSnapshot.data()!;

      final bool ownsAvatar = isItemOwned(childData: data, item: avatarItem);

      final bool ownsBackground = isItemOwned(
        childData: data,
        item: backgroundItem,
      );

      if (!ownsAvatar) {
        throw Exception('يجب شراء الشخصية أولًا');
      }

      if (!ownsBackground) {
        throw Exception('يجب شراء الخلفية أولًا');
      }

      final updates = <String, dynamic>{
        'equippedAvatarId': avatarId,
        'equippedBackgroundId': backgroundId,
      };

      transaction.update(childRef, {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(publicRef, updates);
    });
  }

  // ============================================================
  // PREVIEW MODE - LEGACY COMPATIBILITY ONLY
  // No purchases and no point deductions.
  //
  // Do not call this from the real store.
  // ============================================================

  Future<void> equipPreviewItem({
    required String childId,
    required StoreItem item,
  }) async {
    final catalogItem = StoreCatalog.findById(item.id);

    if (catalogItem == null || catalogItem.type != item.type) {
      throw Exception('المكافأة غير موجودة');
    }

    final String field;

    if (catalogItem.type == StoreItemType.avatar) {
      field = 'equippedAvatarId';
    } else if (catalogItem.type == StoreItemType.background) {
      field = 'equippedBackgroundId';
    } else {
      throw Exception('نوع المكافأة غير مدعوم حاليًا');
    }

    final childRef = _childRef(childId);
    final publicRef = _publicRef(childId);

    final batch = _db.batch();

    batch.update(childRef, {field: catalogItem.id});

    batch.update(publicRef, {field: catalogItem.id});

    await batch.commit();
  }
}
