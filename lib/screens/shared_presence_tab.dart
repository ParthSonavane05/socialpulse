import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_colors.dart';
import '../widgets/glass_card.dart';
import 'leaderboard_screen.dart';

class SharedPresenceTab extends StatefulWidget {
  const SharedPresenceTab({super.key});
  @override
  State<SharedPresenceTab> createState() => _SharedPresenceTabState();
}

class _SharedPresenceTabState extends State<SharedPresenceTab> {
  final GlobalKey<AnimatedListState> _feedKey = GlobalKey<AnimatedListState>();

  // Mock Friends List (Stories)
  final List<_FriendStatus> _friends = [
    _FriendStatus('You', 'Highly Present', true, 'Y'),
    _FriendStatus('Vivek', 'In Focus Flow', true, 'V'),
    _FriendStatus('Palak', 'Active 10m ago', false, 'P'),
    _FriendStatus('Himadri', 'Present', true, 'H'),
    _FriendStatus('Rahul', 'Active recently', false, 'R'),
  ];

  // Mock Feed Events
  final List<_FeedEvent> _feedEvents = [
    _FeedEvent(
      'Vivek',
      'Completed a 2-hour Focus Flow block! 🎯',
      DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    _FeedEvent(
      'Palak',
      'Reduced phone unlocks by 15% today. 📉',
      DateTime.now().subtract(const Duration(hours: 1)),
    ),
    _FeedEvent(
      'Himadri',
      'Joined the "No Phone Dinner" challenge! 🍽️',
      DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFriendsStories(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Activity Feed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedList(
                key: _feedKey,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                initialItemCount: _feedEvents.length,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFeedCard(_feedEvents[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social Feed',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your friends\' presence journey',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildLeaderboardBtn(),
              const SizedBox(width: 12),
              _buildAddFriendBtn(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardBtn() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
          );
        },
        tooltip: 'Leaderboard',
      ),
    );
  }

  Widget _buildAddFriendBtn() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: const Icon(Icons.person_add_rounded, color: AppColors.neonCyan),
        onPressed: () => _showAddFriendsSheet(context),
        tooltip: 'Add Friends',
      ),
    );
  }

  Widget _buildFriendsStories() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: friend.isPresent
                        ? AppColors.presenceRingGradient
                        : null,
                    color: !friend.isPresent ? AppColors.bgCardLight : null,
                    border: friend.isPresent
                        ? null
                        : Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.2),
                            width: 2,
                          ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgDark,
                      ),
                      child: Center(
                        child: Text(
                          friend.initial,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  friend.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: friend.name == 'You'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: friend.isPresent
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ).animate().fade().scale(delay: Duration(milliseconds: 50 * index)),
          );
        },
      ),
    );
  }

  Widget _buildFeedCard(_FeedEvent event) {
    String timeAgo = '';
    final diff = DateTime.now().difference(event.time);
    if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else {
      timeAgo = '${diff.inHours}h ago';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lavender.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    event.userName[0],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lavender,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.userName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _ReactionRow(event: event),
        ],
      ),
    );
  }

  void _showAddFriendsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Friends',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.bgCardLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'Suggested',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neonCyan,
              ),
            ),
            const SizedBox(height: 12),
            _buildSuggestedFriend('Aditi', 'Active recently'),
            _buildSuggestedFriend('Rohan', 'In "Weekend Present"'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.qr_code_rounded,
                  color: AppColors.lavender,
                ),
                label: Text(
                  'Share My Profile Link',
                  style: GoogleFonts.inter(
                    color: AppColors.lavender,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lavender),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showQrDialog(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Me',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan to connect on SocialPulse',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: 'socialpulse://addfriend/my_unique_id_123',
                  version: QrVersions.auto,
                  size: 200.0,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link Copied to Clipboard!'),
                      backgroundColor: AppColors.bgCardLight,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'socialpulse.app/add/P38x9',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.copy_rounded,
                        color: AppColors.lavender,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedFriend(String name, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgDark,
            ),
            child: Center(
              child: Text(
                name[0],
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan,
              foregroundColor: AppColors.darkNavy,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {},
            child: Text(
              'Add',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendStatus {
  final String name, status, initial;
  final bool isPresent;
  _FriendStatus(this.name, this.status, this.isPresent, this.initial);
}

class _FeedEvent {
  final String userName, content;
  final DateTime time;
  int flames = 0;
  bool reported = false;
  _FeedEvent(this.userName, this.content, this.time);
}

class _ReactionRow extends StatefulWidget {
  final _FeedEvent event;
  const _ReactionRow({required this.event});
  @override
  State<_ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends State<_ReactionRow> {
  bool _reacted = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _reacted = !_reacted;
              if (_reacted) {
                widget.event.flames++;
              } else {
                widget.event.flames--;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _reacted
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.bgDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _reacted
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: _reacted ? AppColors.warning : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.event.flames > 0 ? widget.event.flames : 'React'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: _reacted ? FontWeight.bold : FontWeight.normal,
                    color: _reacted ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Awesome 😎'),
                backgroundColor: AppColors.bgCardLight,
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Text(
            'Encourage',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
