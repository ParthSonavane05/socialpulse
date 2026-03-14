import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/detection_service.dart';
import 'dashboard_tab.dart';
import 'insights_tab.dart';
import 'shared_presence_tab.dart';
import 'settings_tab.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  final _service = DetectionService();

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(service: _service),
      InsightsTab(service: _service),
      const SharedPresenceTab(),
      SettingsTab(service: _service),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          ['Dashboard', 'Insights', 'Social Feed', 'Settings'][_currentTab],
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.neonCyan,
            ),
            onPressed: () async {
              final code = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
              if (code != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scanned Profile: $code'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            tooltip: 'Add Friend by QR',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentTab, children: tabs),
          // Floating bottom nav
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppColors.bgCard.withValues(alpha: 0.85),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Home',
                        active: _currentTab == 0,
                        onTap: () => setState(() => _currentTab = 0),
                      ),
                      _NavItem(
                        icon: Icons.insights_rounded,
                        label: 'Insights',
                        active: _currentTab == 1,
                        onTap: () => setState(() => _currentTab = 1),
                      ),
                      _NavItem(
                        icon: Icons.people_rounded,
                        label: 'Social',
                        active: _currentTab == 2,
                        onTap: () => setState(() => _currentTab = 2),
                      ),
                      _NavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        active: _currentTab == 3,
                        onTap: () => setState(() => _currentTab = 3),
                      ),
                    ],
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: active
              ? AppColors.neonCyan.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.neonCyan : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.neonCyan : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
