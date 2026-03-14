import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../core/app_colors.dart';
import '../widgets/glass_card.dart';

class LeaderboardUser {
  final int rank;
  final String name;
  final String avatarUrl; // We'll just use initial if we don't have images
  final int presenceScore;
  final int streakDays;
  final bool isCurrentUser;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.avatarUrl,
    required this.presenceScore,
    required this.streakDays,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late ConfettiController _confettiController;
  int _selectedTabIndex = 0; // 0: Today, 1: Weekly, 2: All Time

  final List<LeaderboardUser> _mockUsers = [
    LeaderboardUser(
      rank: 1,
      name: 'Palak',
      avatarUrl: 'P',
      presenceScore: 98,
      streakDays: 14,
    ),
    LeaderboardUser(
      rank: 2,
      name: 'Vivek',
      avatarUrl: 'V',
      presenceScore: 93,
      streakDays: 12,
    ),
    LeaderboardUser(
      rank: 3,
      name: 'Himadri',
      avatarUrl: 'H',
      presenceScore: 89,
      streakDays: 9,
    ),
    LeaderboardUser(
      rank: 4,
      name: 'Aditi',
      avatarUrl: 'A',
      presenceScore: 85,
      streakDays: 7,
    ),
    LeaderboardUser(
      rank: 5,
      name: 'Parth',
      avatarUrl: 'P',
      presenceScore: 81,
      streakDays: 6,
      isCurrentUser: true,
    ),
    LeaderboardUser(
      rank: 6,
      name: 'Rohan',
      avatarUrl: 'R',
      presenceScore: 78,
      streakDays: 4,
    ),
    LeaderboardUser(
      rank: 7,
      name: 'Neha',
      avatarUrl: 'N',
      presenceScore: 72,
      streakDays: 3,
    ),
    LeaderboardUser(
      rank: 8,
      name: 'Rahul',
      avatarUrl: 'R',
      presenceScore: 65,
      streakDays: 2,
    ),
    LeaderboardUser(
      rank: 9,
      name: 'Sneha',
      avatarUrl: 'S',
      presenceScore: 50,
      streakDays: 1,
    ),
    LeaderboardUser(
      rank: 10,
      name: 'Aman',
      avatarUrl: 'A',
      presenceScore: 45,
      streakDays: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    // Current user for sticky bottom card
    final currentUser = _mockUsers.firstWhere(
      (u) => u.isCurrentUser,
      orElse: () => _mockUsers[0],
    );

    // Gradient background: Deep navy to royal purple
    final headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.darkNavy,
        const Color(0xFF1E0C3A), // Deep royal purple
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Presence Champions',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background
          Container(decoration: BoxDecoration(gradient: headerGradient)),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildFilterToggle(),
                const SizedBox(height: 16),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.neonCyan,
                    backgroundColor: AppColors.bgCardLight,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 120,
                      ), // Space for sticky card
                      itemCount: _mockUsers.length,
                      itemBuilder: (context, index) {
                        final user = _mockUsers[index];
                        if (index < 3) {
                          return _buildHeroCard(user, index)
                              .animate()
                              .fade(delay: Duration(milliseconds: 100 * index))
                              .slideY(begin: 0.1);
                        }
                        return _buildListCard(user, index)
                            .animate()
                            .fade(delay: Duration(milliseconds: 50 * index))
                            .slideX(begin: 0.1);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Current User Bottom Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.bgDark.withValues(alpha: 0.9),
                    AppColors.bgDark,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: _buildStickyUserCard(currentUser),
            ),
          ),

          // Confetti for Rank 1
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // fall straight down
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.yellow,
                AppColors.neonCyan,
                AppColors.lavender,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            _buildTab(0, 'Today'),
            _buildTab(1, 'Weekly'),
            _buildTab(2, 'All Time'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.lavender.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: AppColors.lavender.withValues(alpha: 0.5))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.lavender : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(LeaderboardUser user, int index) {
    // Top 3 distinct gradients
    List<Color> gradientColors;
    Color glowColor;
    if (user.rank == 1) {
      gradientColors = [
        const Color(0xFFFFD700),
        const Color(0xFFD4AF37),
      ]; // Gold
      glowColor = const Color(0xFFFFD700);
    } else if (user.rank == 2) {
      gradientColors = [
        const Color(0xFFE0E0E0),
        const Color(0xFF9E9E9E),
      ]; // Silver
      glowColor = const Color(0xFFE0E0E0);
    } else {
      gradientColors = [
        const Color(0xFFCD7F32),
        const Color(0xFF8B4513),
      ]; // Bronze
      glowColor = const Color(0xFFCD7F32);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: GlassCard(
            margin: EdgeInsets.zero,
            borderColor: glowColor.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradientColors),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#${user.rank}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgDark,
                          border: Border.all(color: glowColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.avatarUrl,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00FF00), // Online green
                            border: Border.all(
                              color: AppColors.bgCard,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.neonCyan,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(
                                begin: 0,
                                end: user.presenceScore,
                              ),
                              duration: const Duration(seconds: 1),
                              builder: (context, value, child) {
                                return Text(
                                  '$value Presence',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.neonCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Streak
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orangeAccent,
                            size: 24,
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            duration: 800.ms,
                          ),
                      const SizedBox(height: 2),
                      Text(
                        '${user.streakDays}d',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(LeaderboardUser user, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(
                alpha: user.isCurrentUser ? 0.8 : 0.4,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: user.isCurrentUser
                    ? AppColors.lavender.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 40,
                  child: Text(
                    '#${user.rank}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgDark,
                      ),
                      child: Center(
                        child: Text(
                          user.avatarUrl,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00FF00), // Online green
                          border: Border.all(
                            color: AppColors.bgCardLight,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: user.presenceScore),
                            duration: const Duration(seconds: 1),
                            builder: (context, value, child) {
                              return Text(
                                '$value Presence',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Streak
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.streakDays}d',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyUserCard(LeaderboardUser user) {
    return GlassCard(
      margin: EdgeInsets.zero,
      borderColor: AppColors.lavender.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.presenceRingGradient,
              ),
              child: Center(
                child: Text(
                  '#${user.rank}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.neonCyan,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.presenceScore} Presence',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${user.streakDays}d',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
