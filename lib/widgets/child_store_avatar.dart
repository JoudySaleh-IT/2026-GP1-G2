import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/store_catalog.dart';
import '../models/store_item.dart';

class ChildStoreAvatar extends StatelessWidget {
  final String childId;
  final String fallbackAvatar;
  final double size;
  final Color backgroundColor;

  const ChildStoreAvatar({
    super.key,
    required this.childId,
    required this.fallbackAvatar,
    this.size = 48,
    this.backgroundColor = const Color(0xFFFCF9EA),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        return StoreAvatarImage(
          avatar: data?['avatar']?.toString() ?? fallbackAvatar,
          avatarId: data?['equippedAvatarId']?.toString(),
          backgroundId: data?['equippedBackgroundId']?.toString(),
          size: size,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}

class StoreAvatarImage extends StatelessWidget {
  final String avatar;
  final String? avatarId;
  final String? backgroundId;
  final double size;
  final Color backgroundColor;

  const StoreAvatarImage({
    super.key,
    required this.avatar,
    this.avatarId,
    this.backgroundId,
    this.size = 48,
    this.backgroundColor = const Color(0xFFFCF9EA),
  });

  @override
  @override
  Widget build(BuildContext context) {
    final avatarItem = avatarId == null
        ? null
        : StoreCatalog.findById(avatarId!);

    final backgroundItem = backgroundId == null
        ? null
        : StoreCatalog.findById(backgroundId!);

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            ColoredBox(color: backgroundColor),

            // Equipped store background
            if (backgroundItem != null &&
                backgroundItem.type == StoreItemType.background)
              Image.asset(
                backgroundItem.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(color: backgroundColor);
                },
              ),

            // Avatar
            if (avatarItem != null && avatarItem.type == StoreItemType.avatar)
              Padding(
                padding: EdgeInsets.all(size * 0.04),
                child: Image.asset(
                  avatarItem.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) {
                    return _buildFallback();
                  },
                ),
              )
            else
              _buildFallback(),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(avatar, style: TextStyle(fontSize: size * 0.60)),
    );
  }
}
