import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/worker_profile_entity.dart';
import '../../domain/entities/ongoing_job_entity.dart';
import '../../domain/entities/worker_skill_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/worker_review_entity.dart';
import '../providers/worker_providers.dart';
import '../providers/worker_review_providers.dart';
import '../widgets/worker_bottom_nav_bar.dart';

const _kOrange = Color(0xFFDB6234);
const _kDark   = Color(0xFF1A1A1A);
const _kGray   = Color(0xFF6B7280);
const _kLight  = Color(0xFF94A3B8);
const _kBorder = Color(0xFFE2E8F0);

class WorkerHomePage extends ConsumerStatefulWidget {
  const WorkerHomePage({super.key});

  @override
  ConsumerState<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends ConsumerState<WorkerHomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationTrackerProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        ref.watch(authStateProvider).valueOrNull?.firstName ?? 'there';
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kOrange),
          ),
          error: (err, _) => _ErrorView(
            message: err.toString(),
            onRetry: () => ref.read(workerProfileProvider.notifier).refresh(),
          ),
          data: (profile) => _HomeBody(
            firstName: firstName,
            profile: profile,
          ),
        ),
      ),
      bottomNavigationBar: const WorkerBottomNavBar(currentIndex: 0),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  final String firstName;
  final WorkerProfileEntity profile;
  const _HomeBody({required this.firstName, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () => ref.read(workerProfileProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(firstName: firstName)),
          SliverToBoxAdapter(
            child: _AvailabilityRow(profile: profile),
          ),
          if (profile.ongoingJob != null)
            SliverToBoxAdapter(
              child: _ActiveJobSection(job: profile.ongoingJob!),
            ),
          SliverToBoxAdapter(child: _StatsRow(profile: profile)),
          SliverToBoxAdapter(
            child: _SkillsSection(skills: profile.skills),
          ),
          SliverToBoxAdapter(child: _ReviewsSection(profile: profile)),
          SliverToBoxAdapter(
            child: _TipBanner(
              status: profile.availabilityStatus,
              hasSkills: profile.skills.isNotEmpty,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final String firstName;
  const _Header({required this.firstName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your dashboard',
                  style: TextStyle(fontSize: 13, color: _kGray),
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.notifications_outlined,
                      size: 24, color: _kDark),
                ),
                Consumer(builder: (context, ref, child) {
                  final count = ref
                          .watch(unreadNotificationCountProvider)
                          .valueOrNull ??
                      0;
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _kOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Logout
          GestureDetector(
            onTap: () =>
                ref.read(logoutNotifierProvider.notifier).logout(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.logout_rounded, size: 22, color: _kGray),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Availability row ──────────────────────────────────────────────────────────

class _AvailabilityRow extends ConsumerWidget {
  final WorkerProfileEntity profile;
  const _AvailabilityRow({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = profile.availabilityStatus;
    final isLoading = ref.watch(availabilityNotifierProvider).isLoading;

    final dotColor = _dotColor(status);
    final label = status.label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Status dot + label
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _labelColor(status),
            ),
          ),
          const Spacer(),
          // Toggle button
          if (status == AvailabilityStatus.busy)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'On Active Job',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),
            )
          else if (status == AvailabilityStatus.offline)
            _ToggleBtn(
              label: isLoading ? 'Connecting...' : 'Go Online',
              filled: true,
              loading: isLoading,
              onTap: () => _handleGoOnline(context, ref),
            )
          else
            _ToggleBtn(
              label: isLoading ? 'Going offline...' : 'Go Offline',
              filled: false,
              loading: isLoading,
              onTap: () => _handleGoOffline(context, ref),
            ),
        ],
      ),
    );
  }

  Color _dotColor(AvailabilityStatus s) {
    switch (s) {
      case AvailabilityStatus.online:
        return const Color(0xFF22C55E);
      case AvailabilityStatus.busy:
        return const Color(0xFFFF6B35);
      case AvailabilityStatus.offline:
        return const Color(0xFF94A3B8);
    }
  }

  Color _labelColor(AvailabilityStatus s) {
    switch (s) {
      case AvailabilityStatus.online:
        return const Color(0xFF16A34A);
      case AvailabilityStatus.busy:
        return const Color(0xFFE65100);
      case AvailabilityStatus.offline:
        return _kDark;
    }
  }

  Future<void> _handleGoOnline(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(availabilityNotifierProvider.notifier).goOnline();
    if (result == AvailabilityToggleResult.needsSkills && context.mounted) {
      await _showSkillsSheet(context, ref);
    } else if (context.mounted) {
      final err = ref.read(availabilityNotifierProvider).error;
      if (err != null) _showSnack(context, err.toString());
    }
  }

  Future<void> _handleGoOffline(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Go Offline?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text('You will stop appearing to nearby clients.',
            style: TextStyle(color: _kGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _kGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Yes, Go Offline'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(availabilityNotifierProvider.notifier).goOffline();
      if (context.mounted) {
        final err = ref.read(availabilityNotifierProvider).error;
        if (err != null) _showSnack(context, err.toString());
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final bool loading;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.filled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? _kOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: filled
              ? null
              : Border.all(color: _kOrange, width: 1.5),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: filled ? Colors.white : _kOrange,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : _kOrange,
                ),
              ),
      ),
    );
  }
}

// ── Active job section ────────────────────────────────────────────────────────

class _ActiveJobSection extends StatelessWidget {
  final OngoingJobEntity job;
  const _ActiveJobSection({required this.job});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(job.status);
    final statusColor = _statusColor(job.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => context.push('/worker/job/${job.id}'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kOrange.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _kOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Active Job',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kOrange,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Job title
              Text(
                job.title ?? job.categoryName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 4),
              // Category + location
              Row(
                children: [
                  const Icon(Icons.construction_rounded,
                      size: 12, color: _kLight),
                  const SizedBox(width: 4),
                  Text(job.categoryName,
                      style: const TextStyle(fontSize: 12, color: _kGray)),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_rounded,
                      size: 12, color: _kLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.clientArea,
                      style: const TextStyle(fontSize: 12, color: _kGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View details →',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return 'Accepted';
      case 'EN_ROUTE':
        return 'En Route';
      case 'IN_PROGRESS':
        return 'In Progress';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return const Color(0xFF3B82F6);
      case 'EN_ROUTE':
        return const Color(0xFFF59E0B);
      case 'IN_PROGRESS':
        return _kOrange;
      default:
        return _kGray;
    }
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final WorkerProfileEntity profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatItem(
            label: 'Completed',
            value: '${profile.stats.completedJobs}',
            icon: Icons.check_circle_outline_rounded,
          ),
          _Divider(),
          _StatItem(
            label: 'Rating',
            value: profile.rating > 0
                ? profile.rating.toStringAsFixed(1)
                : '—',
            icon: Icons.star_outline_rounded,
          ),
          _Divider(),
          _StatItem(
            label: 'Active',
            value: '${profile.stats.activeJobs}',
            icon: Icons.bolt_rounded,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: _kBorder,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kLight),
          ),
        ],
      ),
    );
  }
}

// ── Skills section ────────────────────────────────────────────────────────────

class _SkillsSection extends ConsumerWidget {
  final List<WorkerSkillEntity> skills;
  const _SkillsSection({required this.skills});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Your Skills',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showSkillsSheet(context, ref),
                child: Text(
                  skills.isEmpty ? '+ Add Skills' : 'Edit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            const Text(
              'No skills added yet — add skills to receive jobs.',
              style: TextStyle(fontSize: 13, color: _kGray),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: _kOrange.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    skill.categoryName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kOrange,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends ConsumerWidget {
  final WorkerProfileEntity profile;
  const _ReviewsSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(workerRecentReviewsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              if (profile.totalRatings > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded,
                    size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 3),
                Text(
                  '${profile.rating.toStringAsFixed(1)} · ${profile.totalRatings}',
                  style: const TextStyle(fontSize: 12, color: _kGray),
                ),
              ],
              const Spacer(),
              if (profile.totalRatings > 0)
                GestureDetector(
                  onTap: () => context.push('/worker/reviews'),
                  child: const Text(
                    'See all →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          reviewsAsync.when(
            loading: () => const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kOrange),
            ),
            error: (e, s) => const SizedBox.shrink(),
            data: (reviews) => reviews.isEmpty
                ? const Text(
                    'No reviews yet — they will appear here after jobs complete.',
                    style: TextStyle(fontSize: 13, color: _kGray),
                  )
                : Column(
                    children: reviews
                        .map((r) => _ReviewItem(review: r))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final WorkerReviewEntity review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 13,
                    color: i < review.rating
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFD1D5DB),
                  );
                }),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: const TextStyle(fontSize: 10, color: _kLight),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment!,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF374151), height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                review.serviceCategory,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kOrange,
                ),
              ),
              if (review.clientName != null &&
                  review.clientName!.isNotEmpty) ...[
                const Text('  ·  ',
                    style: TextStyle(fontSize: 11, color: _kLight)),
                Text(
                  review.clientName!,
                  style: const TextStyle(fontSize: 11, color: _kGray),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: _kBorder, height: 1),
        ],
      ),
    );
  }
}

// ── Tip banner ────────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  final AvailabilityStatus status;
  final bool hasSkills;
  const _TipBanner({required this.status, required this.hasSkills});

  @override
  Widget build(BuildContext context) {
    final message = !hasSkills
        ? 'Add skills to get more job opportunities'
        : status == AvailabilityStatus.offline
            ? 'Stay online to receive nearby work from clients'
            : 'Great! Clients near you can find and book you';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _kOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: _kGray),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skills bottom sheet ───────────────────────────────────────────────────────

Future<void> _showSkillsSheet(BuildContext context, WidgetRef ref) async {
  final profile = ref.read(workerProfileProvider).valueOrNull;
  final existingIds =
      profile?.skills.map((s) => s.categoryId).toSet() ?? {};
  ref.read(selectedCategoryIdsProvider.notifier).state = existingIds;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: const _SkillsSheet(),
    ),
  );
}

class _SkillsSheet extends ConsumerWidget {
  const _SkillsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryIdsProvider);
    final isSaving = ref.watch(skillsNotifierProvider).isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your skills first',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Select at least one service to start receiving work',
                  style: TextStyle(fontSize: 13, color: _kGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(color: _kOrange)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load categories: $e'),
            ),
            data: (categories) => _CategoryChips(
              categories: categories,
              selected: selected,
              onToggle: (id) {
                final current =
                    Set<String>.from(ref.read(selectedCategoryIdsProvider));
                if (current.contains(id)) {
                  current.remove(id);
                } else {
                  current.add(id);
                }
                ref.read(selectedCategoryIdsProvider.notifier).state =
                    current;
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isSaving || selected.isEmpty)
                    ? null
                    : () async {
                        final saved = await ref
                            .read(skillsNotifierProvider.notifier)
                            .saveSkills(selected.toList());
                        if (!context.mounted) return;
                        if (saved) {
                          Navigator.pop(context);
                          await ref
                              .read(availabilityNotifierProvider.notifier)
                              .goOnline();
                        } else {
                          final err =
                              ref.read(skillsNotifierProvider).error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err?.toString() ??
                                  'Failed to save skills. Please try again.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        selected.isEmpty
                            ? 'Select at least one skill'
                            : 'Save & Go Online',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<CategoryEntity> categories;
  final Set<String> selected;
  final void Function(String id) onToggle;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categories.map((cat) {
          final isSelected = selected.contains(cat.id);
          return GestureDetector(
            onTap: () => onToggle(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _kOrange : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isSelected ? _kOrange : _kBorder,
                ),
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : _kGray,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: _kLight),
            const SizedBox(height: 12),
            const Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kGray),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
