import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/sound_service.dart';
import 'duck_logo.dart';

class DuckWardrobeSheet extends ConsumerStatefulWidget {
  const DuckWardrobeSheet({super.key});

  @override
  ConsumerState<DuckWardrobeSheet> createState() => _DuckWardrobeSheetState();
}

class _DuckWardrobeSheetState extends ConsumerState<DuckWardrobeSheet> {
  final List<Map<String, dynamic>> _shopItems = [
    {
      'id': 'none',
      'name': 'Vịt Tự Nhiên',
      'icon': '🐥',
      'price': 0,
    },
    {
      'id': 'grad_cap',
      'name': 'Mũ Cử Nhân',
      'icon': '🎓',
      'price': 30,
    },
    {
      'id': 'sunglasses',
      'name': 'Kính Râm Cool',
      'icon': '🕶️',
      'price': 50,
    },
    {
      'id': 'top_hat',
      'name': 'Mũ Ảo Thuật',
      'icon': '🎩',
      'price': 80,
    },
    {
      'id': 'crown',
      'name': 'Vương Miện',
      'icon': '👑',
      'price': 100,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: statsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: Color(0xFFFF8F00)),
              ),
            ),
            error: (err, stack) => const SizedBox.shrink(),
            data: (stats) {
              final int xpForCurrentLevel = (stats.level - 1) * 100;
              final int currentLevelXp = stats.xp - xpForCurrentLevel;
              final int xpNeeded = 100;
              final double levelProgress =
                  (currentLevelXp / xpNeeded).clamp(0.0, 1.0);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Handle
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header Title
                  const Text(
                    "Tủ Đồ & Hồ Sơ Vịt Vàng 🐥",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF8F00),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mascot Duck Display wearing current hat
                  DuckLogo(
                    size: 130,
                    animate: true,
                    showQuackBadge: true,
                    equippedHat: stats.equippedHat,
                  ),

                  const SizedBox(height: 16),

                  // LEVEL & XP BAR
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                            : const [Color(0xFFFFFBEB), Color(0xFFFFF3C4)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFFFE082),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8F00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'LEVEL ${stats.level} 🐤',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Text('🔥 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  '${stats.currentStreak} ngày',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('🪙 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  '${stats.coins}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: levelProgress,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFFFECB3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF8F00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến trình cấp độ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF78350F),
                              ),
                            ),
                            Text(
                              '${(levelProgress * 100).toInt()}% ($currentLevelXp/$xpNeeded XP)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF8F00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SHOP HEADING
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cửa hàng Mũ & Phụ kiện 🛍️',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // WARDROBE ITEMS GRID
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _shopItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final item = _shopItems[index];
                      final String itemId = item['id'] as String;
                      final String name = item['name'] as String;
                      final String icon = item['icon'] as String;
                      final int price = item['price'] as int;

                      final bool isUnlocked =
                          stats.unlockedHats.contains(itemId);
                      final bool isEquipped = stats.equippedHat == itemId;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? const Color(0xFFFF8F00).withValues(alpha: 0.15)
                              : (isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isEquipped
                                ? const Color(0xFFFF8F00)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade300),
                            width: isEquipped ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await SoundService().playClickHaptics();
                                  if (isEquipped) {
                                    // Unequip
                                    stats.equippedHat = 'none';
                                    await ref
                                        .read(databaseProvider)
                                        .saveUserStats(stats);
                                  } else if (isUnlocked) {
                                    // Equip
                                    stats.equippedHat = itemId;
                                    await ref
                                        .read(databaseProvider)
                                        .saveUserStats(stats);
                                  } else {
                                    // Buy
                                    if (stats.coins >= price) {
                                      stats.coins -= price;
                                      stats.unlockedHats = [
                                        ...stats.unlockedHats,
                                        itemId,
                                      ];
                                      stats.equippedHat = itemId;
                                      await ref
                                          .read(databaseProvider)
                                          .saveUserStats(stats);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '🎉 Bạn đã mở khóa $icon $name!'),
                                            behavior:
                                                SnackBarBehavior.floating,
                                            backgroundColor:
                                                const Color(0xFFFF8F00),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '⚠️ Bạn cần thêm ${price - stats.coins} 🪙 nữa để mua $name!'),
                                            behavior:
                                                SnackBarBehavior.floating,
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEquipped
                                      ? Colors.grey.shade400
                                      : (isUnlocked
                                          ? const Color(0xFFFF8F00)
                                          : const Color(0xFFD97706)),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isEquipped
                                      ? 'Đang đeo'
                                      : (isUnlocked
                                          ? 'Đeo mũ'
                                          : 'Mua ($price 🪙)'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
