import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../core/presentation/responsive_utils.dart';
import '../../../categories/presentation/providers/categories_providers.dart';
import '../widgets/client_bottom_nav_bar.dart';
import '../widgets/service_card.dart';
import '../widgets/service_data.dart';

const _kGreen = Color(0xFFDB6234);
const _kDark = Color(0xFF1A1A1A);
const _kGray = Color(0xFF6B7280);

// Fetches current area label (subLocality → locality → "Your Area").
final _currentAreaProvider = FutureProvider<String>((ref) async {
  try {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return 'Your Area';
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 6),
      ),
    );
    final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (marks.isEmpty) return 'Your Area';
    final m = marks.first;
    return m.subLocality?.isNotEmpty == true
        ? m.subLocality!
        : m.locality?.isNotEmpty == true
            ? m.locality!
            : 'Your Area';
  } catch (_) {
    return 'Your Area';
  }
});

class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final firstName = user?.firstName ?? 'there';
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header: logo + Handygo | location pill | notification ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Logo icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo-green.png',
                      height: 30,
                      width: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.home_repair_service_rounded,
                          color: _kGreen,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Handygo',
                    style: TextStyle(
                      fontSize: rFont(screenWidth, 19, min: 16, max: 22),
                      fontWeight: FontWeight.w800,
                      color: _kGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  // Dynamic location pill
                  Consumer(
                    builder: (_, cRef, _) {
                      final area =
                          cRef.watch(_currentAreaProvider).valueOrNull ??
                          'Your Area';
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.32,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: _kGreen,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                area,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  // Notification bell with unread badge
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: _kDark,
                          ),
                        ),
                        Consumer(
                          builder: (_, cRef, _) {
                            final count =
                                cRef
                                    .watch(unreadNotificationCountProvider)
                                    .valueOrNull ??
                                0;
                            if (count == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _kGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Compact greeting + search pill ────────────────────
                    GestureDetector(
                      onTap: () => context.push('/client/post-job'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: _kGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hi $firstName 👋',
                              style: TextStyle(
                                fontSize: rFont(screenWidth, 13, min: 11, max: 14),
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 1,
                              height: 14,
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: Text(
                                'Try "AC not cooling" ...',
                                style: TextStyle(
                                  fontSize: rFont(screenWidth, 12, min: 11, max: 13),
                                  color: const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Categorized service sections (planned list + backend) ─
                    Consumer(
                      builder: (_, cRef, _) {
                        final backendCategories =
                            cRef.watch(allCategoriesProvider).valueOrNull ?? [];

                        // Build a set of backend names for fast availability check.
                        final availableNames = <String>{
                          for (final c in backendCategories)
                            c.name.toLowerCase(),
                        };

                        // Helper: build items for a planned section, marking
                        // availability from backend. Also collect "extra" backend
                        // categories not in the planned list for "More Services".
                        final plannedBackendNames = <String>{};

                        List<_HomeServiceItem> itemsFor(
                            List<ServiceItem> planned) {
                          return planned.map((s) {
                            plannedBackendNames.add(s.backendName.toLowerCase());
                            final available = availableNames.isEmpty ||
                                availableNames
                                    .contains(s.backendName.toLowerCase());
                            return _HomeServiceItem(
                              displayTitle: s.title,
                              backendName: s.backendName,
                              emoji: s.emoji,
                              bg: s.bg,
                              emojiBg: s.emojiBg,
                              imagePath: s.imagePath,
                              isAvailable: available,
                            );
                          }).toList();
                        }

                        // Build planned sections in fixed order.
                        final sections = [
                          for (final cat in kServiceCategories)
                            _SectionData(
                              heading: cat.heading,
                              items: itemsFor(cat.items),
                            ),
                        ];

                        // Collect unknown backend categories → "More Services".
                        final extras = backendCategories
                            .where((c) => !plannedBackendNames
                                .contains(c.name.toLowerCase()))
                            .map((c) => _HomeServiceItem(
                                  displayTitle: c.name,
                                  backendName: c.name,
                                  emoji: emojiForCategory(c.name),
                                  bg: bgColorForCategory(c.name),
                                  emojiBg: emojiBgForCategory(c.name),
                                  imagePath: imagePathForCategory(c.name),
                                  isAvailable: true,
                                ))
                            .toList();

                        if (extras.isNotEmpty) {
                          sections.add(_SectionData(
                            heading: 'More Services',
                            items: extras,
                          ));
                        }

                        void onTap(_HomeServiceItem item) {
                          if (item.isAvailable) {
                            context.push(
                              '/client/post-job?service='
                              '${Uri.encodeComponent(item.backendName)}',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${item.displayTitle} — coming soon!',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }

                        return Column(
                          children: sections
                              .map((sec) => _ServiceSection(
                                    heading: sec.heading,
                                    items: sec.items,
                                    onItemTap: onTap,
                                  ))
                              .toList(),
                        );
                      },
                    ),

                    // ── Recent Notifications ──────────────────────────────
                    const _RecentNotifications(),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const ClientBottomNavBar(currentIndex: 0),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _HomeServiceItem {
  final String displayTitle;
  final String backendName;
  final String emoji;
  final Color bg;
  final Color emojiBg;
  final String? imagePath;
  final bool isAvailable;

  const _HomeServiceItem({
    required this.displayTitle,
    required this.backendName,
    required this.emoji,
    required this.bg,
    required this.emojiBg,
    this.imagePath,
    this.isAvailable = true,
  });
}

class _SectionData {
  final String heading;
  final List<_HomeServiceItem> items;
  const _SectionData({required this.heading, required this.items});
}

// ── One categorized service section ──────────────────────────────────────────

class _ServiceSection extends StatelessWidget {
  final String heading;
  final List<_HomeServiceItem> items;
  final void Function(_HomeServiceItem item) onItemTap;

  const _ServiceSection({
    required this.heading,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // cardW derived from screen width minus the outer 20+20 padding that the
    // parent SingleChildScrollView already applies, so heading and cards share
    // the same left edge automatically.
    const hPad = 20.0; // must match parent SingleChildScrollView padding
    const spacing = 10.0;
    final availableW = screenWidth - hPad * 2;
    final cardW = (availableW - spacing) / 2.28;
    final imageH = cardW * 0.55;
    final cardH = imageH + 30; // image + 6px gap + ~18px title + 6px bottom

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(
            fontSize: rFont(screenWidth, 16, min: 14, max: 18),
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: spacing),
                  child: SizedBox(
                    width: cardW,
                    height: cardH,
                    child: Opacity(
                      opacity: s.isAvailable ? 1.0 : 0.55,
                      child: ServiceCard(
                        title: s.displayTitle,
                        emoji: s.emoji,
                        backgroundColor: s.bg,
                        emojiBackgroundColor: s.emojiBg,
                        imagePath: s.imagePath,
                        useImageStyle: true,
                        onTap: () => onItemTap(s),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Recent notifications strip ────────────────────────────────────────────────

class _RecentNotifications extends ConsumerWidget {
  const _RecentNotifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return async.maybeWhen(
      data: (all) {
        if (all.isEmpty) return const SizedBox.shrink();
        final items = all.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: rFont(screenWidth, 18, min: 15, max: 21),
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontSize: rFont(screenWidth, 13, min: 11, max: 15),
                      fontWeight: FontWeight.w500,
                      color: _kGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((n) => _CompactNotifTile(n)),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _CompactNotifTile extends StatelessWidget {
  final NotificationEntity n;
  const _CompactNotifTile(this.n);

  @override
  Widget build(BuildContext context) {
    final isUnread = !n.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          if (n.route != null && n.route!.isNotEmpty) {
            context.push(n.route!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? _kGreen.withValues(alpha: 0.2)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isUnread
                      ? _kGreen.withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 17,
                  color: isUnread ? _kGreen : _kGray,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w500,
                        color: _kDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style: const TextStyle(fontSize: 12, color: _kGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmt(n.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(dt);
  }
}
