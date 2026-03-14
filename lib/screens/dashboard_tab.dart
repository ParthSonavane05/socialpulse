import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../core/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/detection_service.dart';

class DashboardTab extends StatefulWidget {
  final DetectionService service;
  const DashboardTab({super.key, required this.service});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  bool _showNudge = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    widget.service.addListener(_onServiceChanged);

    // Show nudge after delay if social mode
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.service.socialAwarenessEnabled) {
        setState(() => _showNudge = true);
      }
    });
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ringController.dispose();
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final score = svc.presenceScore;
    final nudge = svc.getActiveNudge();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PresencePulse',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay Truly Present',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgGlass,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Permission prompts (only on Android with native backend)
              if (svc.nativeAvailable && !svc.hasUsageStatsPermission)
                _PermissionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Enable Usage Stats',
                  subtitle: 'Required to track phone unlock patterns',
                  onTap: () async {
                    await NativeBackend.openUsageStatsSettings();
                    await Future.delayed(const Duration(seconds: 1));
                    svc.refreshPermissions();
                  },
                ),
              if (svc.nativeAvailable && !svc.hasNotificationPermission)
                _PermissionCard(
                  icon: Icons.notifications_rounded,
                  title: 'Enable Notification Access',
                  subtitle: 'Required to detect notification-triggered unlocks',
                  onTap: () async {
                    await NativeBackend.openNotificationListenerSettings();
                    await Future.delayed(const Duration(seconds: 1));
                    svc.refreshPermissions();
                  },
                ),

              const SizedBox(height: 12),

              // Presence Score Ring
              Center(
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, child) {
                    final progress =
                        Curves.easeOutCubic.transform(_ringController.value);
                    return CircularPercentIndicator(
                      radius: 100,
                      lineWidth: 12,
                      percent: (score / 100) * progress,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(score * progress).toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Presence Score',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor:
                          AppColors.bgCardLight.withValues(alpha: 0.5),
                      linearGradient: AppColors.presenceRingGradient,
                      animation: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Real-Time Awareness Card
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (svc.checkCount > 5
                                ? AppColors.warning
                                : AppColors.success)
                            .withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        svc.checkCount > 5
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                        color: svc.checkCount > 5
                            ? AppColors.warning
                            : AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            svc.checkCount > 5
                                ? 'You\'ve checked your phone ${svc.checkCount} times recently.'
                                : 'You\'re doing great. Stay present!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${svc.unlockCount} unlocks today',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Social Context Chip
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      _contextIcon(svc.socialContext),
                      color: _contextColor(svc.socialContext),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      svc.socialContext,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _contextColor(svc.socialContext),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _contextColor(svc.socialContext),
                        boxShadow: [
                          BoxShadow(
                            color: _contextColor(svc.socialContext)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.self_improvement_rounded,
                      label: svc.focusSessionActive
                          ? 'End Focus'
                          : 'Start Focus',
                      color: AppColors.neonCyan,
                      onTap: () {
                        if (svc.focusSessionActive) {
                          svc.stopFocusSession();
                        } else {
                          svc.startFocusSession();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.people_rounded,
                      label: svc.socialAwarenessEnabled
                          ? 'Social: ON'
                          : 'Social Mode',
                      color: AppColors.lavender,
                      onTap: () => svc.toggleSocialAwareness(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.mic_rounded,
                      label:
                          svc.microphoneEnabled ? 'Mic: ON' : 'Audio Detect',
                      color: AppColors.success,
                      onTap: () => svc.toggleMicrophone(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Simulate button (for demo)
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: InkWell(
                  onTap: () => svc.simulatePhoneCheck(),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Simulate Phone Check (Demo)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nudge card
              if (_showNudge && nudge != null) ...[
                const SizedBox(height: 16),
                _NudgeCard(
                  message: nudge.message,
                  onDismiss: () => setState(() => _showNudge = false),
                  onStartPresence: () {
                    setState(() => _showNudge = false);
                    svc.startFocusSession();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _contextIcon(String ctx) {
    switch (ctx) {
      case 'Social Mode Likely':
        return Icons.groups_rounded;
      case 'Focus Mode':
        return Icons.center_focus_strong_rounded;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _contextColor(String ctx) {
    switch (ctx) {
      case 'Social Mode Likely':
        return AppColors.lavender;
      case 'Focus Mode':
        return AppColors.neonCyan;
      default:
        return AppColors.textMuted;
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onStartPresence;

  const _NudgeCard({
    required this.message,
    required this.onDismiss,
    required this.onStartPresence,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.neonCyan.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonCyan.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.spa_rounded,
                    color: AppColors.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStartPresence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('10-min focus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
