import 'package:flutter/material.dart';

import '../screens/friends_screen.dart';

class ChildBottomNav extends StatelessWidget {
  final String currentRoute;
  final String childId;

  const ChildBottomNav({
    super.key,
    required this.currentRoute,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              9,
              10,
              7,
            ),
            child: Row(
              children: [
                // ───────────────── Home ─────────────────
                Expanded(
                  child: _ChildNavItem(
                    icon: Icons.home_rounded,
                    label: 'الرئيسية',
                    color: const Color(0xFFFF6969),
                    isActive:
                        currentRoute == '/child/home',
                    onTap: () {
                      if (currentRoute ==
                          '/child/home') {
                        return;
                      }

                      Navigator.pushReplacementNamed(
                        context,
                        '/child/home',
                        arguments: childId,
                      );
                    },
                  ),
                ),

                // ───────────────── Exercises ─────────────────
                Expanded(
                  child: _ChildNavItem(
                    icon: Icons.menu_book_rounded,
                    label: 'التمارين',
                    color: const Color(0xFF7B3FC6),
                    isActive:
                        currentRoute ==
                            '/child/exercises',
                    onTap: () {
                      if (currentRoute ==
                          '/child/exercises') {
                        return;
                      }

                      Navigator.pushReplacementNamed(
                        context,
                        '/child/exercises',
                        arguments: childId,
                      );
                    },
                  ),
                ),

                // ───────────────── Friends ─────────────────
                Expanded(
                  child: _ChildNavItem(
                    icon: Icons.people_alt_rounded,
                    label: 'الأصدقاء',
                    color: const Color(0xFF27AE76),
                    isActive:
                        currentRoute ==
                            '/child/friends',
                    onTap: () {
                      if (currentRoute ==
                          '/child/friends') {
                        return;
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FriendsScreen(
                            childId: childId,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ───────────────── Leaderboard ─────────────────
                Expanded(
                  child: _ChildNavItem(
                    icon:
                        Icons.emoji_events_rounded,
                    label: 'المتصدرون',
                    color: const Color(0xFFF3AA22),
                    isActive:
                        currentRoute ==
                            '/child/leaderboard',
                    onTap: () {
                      if (currentRoute ==
                          '/child/leaderboard') {
                        return;
                      }

                      Navigator.pushReplacementNamed(
                        context,
                        '/child/leaderboard',
                        arguments: childId,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ChildNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ───────── Colored rounded icon box ─────────
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: isActive ? 50 : 46,
              height: isActive ? 50 : 46,
              decoration: BoxDecoration(
                color: color.withOpacity(
                  isActive ? 0.20 : 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: isActive ? 29 : 26,
              ),
            ),

            const SizedBox(height: 4),

            // ───────── Label ─────────
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10.5,
                fontWeight: isActive
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isActive
                    ? color
                    : const Color(0xFF444444),
              ),
            ),

            // ───────── Active indicator ─────────
            const SizedBox(height: 3),

            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              width: isActive ? 18 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}