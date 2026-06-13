// custom_widgets.dart
import 'package:fitness/chat_page.dart';
import 'package:fitness/notifs_page.dart';
import 'package:fitness/followed_page.dart';
import 'package:fitness/home_page.dart';
import 'package:fitness/profile_page.dart';
import 'package:fitness/plan_purchase_page.dart';
import 'package:fitness/plan_detail_page.dart';
import 'package:fitness/user_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math';

class GreenButton extends StatelessWidget {
  // Changed to PascalCase
  final String label;
  final VoidCallback onPressed;
  final double horzSize;
  final double vertSize;

  const GreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.horzSize,
    required this.vertSize,
  });
  // ignore: non_constant_identifier_name

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
              255,
              61,
              254,
              65,
            ).withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 61, 254, 65),
          padding: EdgeInsets.symmetric(
            horizontal: horzSize,
            vertical: vertSize,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              40,
            ), // Ensures button matches container
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ); // Added closing parenthesis
  } // Added closing brace for build method
} // Added closing brace for the class

class LabelBoxes extends StatelessWidget {
  final String text;
  final String secondaryText;
  final IconData icon;

  const LabelBoxes({
    super.key,
    required this.text,
    required this.secondaryText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent.withValues(alpha: 0.18),
                ),
                child: Icon(icon, color: Colors.greenAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      secondaryText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlidingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SlidingBottomNav({super.key, required this.currentIndex, this.onTap});

  static const List<IconData> icons = [
    Icons.home_rounded,
    Icons.source_rounded,
    Icons.chat_rounded,
    Icons.person_rounded,
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    // If a callback is provided, call it to let the parent handle navigation/state
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Fallback (backwards compatibility): navigate as before
    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const FollowedPage();
        break;
      case 2:
        page = const ChatPage();
        break;
      case 3:
        page = const ProfilePage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final double barWidth = MediaQuery.of(context).size.width * 0.85;
    final double itemWidth = barWidth / icons.length;

    return Center(
      child: Container(
        width: barWidth,
        height: 70,
        decoration: BoxDecoration(
          color: const Color.fromARGB(0, 0, 0, 0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// Sliding indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: currentIndex * itemWidth + itemWidth / 2 - 22,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF66),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF66).withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            /// Icons
            Row(
              children: List.generate(icons.length, (index) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(context, index),
                    child: Icon(
                      icons[index],
                      color: index == currentIndex
                          ? Colors.black
                          : Colors.grey.shade600,
                      size: 26,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeHeader extends StatefulWidget {
  final String userName;

  const HomeHeader({super.key, required this.userName});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String userEmoji = "⚡";

  final List<String> motivationPhrases = [
    "Track your progress",
    "Stay consistent",
    "Discipline beats motivation",
    "Focus on improvement",
    "Start now",
    "One step at a time",
    "Trust the process",
    "Work with purpose",
    "Progress over perfection",
    "Build good habits",
    "Show up daily",
    "Embrace the grind",
    "Think long term",
    "Control your effort",
    "Learn every day",
    "Stay mentally strong",
    "Execute the plan",
    "Be relentlessly focused",
    "Earn your results",
    "Finish what you start",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserEmoji();
    // listen for username changes
    UserState.username.addListener(() {
      setState(() {});
    });
    // listen for emoji changes
    UserState.emoji.addListener(() {
      setState(() {
        userEmoji = UserState.emoji.value;
      });
    });
  }

  Future<void> _loadUserEmoji() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emoji = prefs.getString('user_emoji') ?? "⚡";
      setState(() {
        userEmoji = emoji;
      });
      UserState.emoji.value = emoji;
    } catch (e) {
      debugPrint('Error loading emoji: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07120C),
            Color(0xFF050D09),
          ], // Dark card background
        ),
      ),
      child: Row(
        children: [
          // 1. Profile Picture with Neon Green Border
          Container(
            padding: const EdgeInsets.all(2.5), // Space for the ring
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1CFF4D), // Green to match app theme
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1A2A22),
              child: Text(userEmoji, style: const TextStyle(fontSize: 24)),
            ),
          ),

          const SizedBox(width: 16),

          // 2. Welcome Text
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motivationPhrases[Random().nextInt(motivationPhrases.length)],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  // prefer live username from UserState if available
                  UserState.username.value.isNotEmpty
                      ? UserState.username.value
                      : widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Circular Notification Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotifsPage()),
              );
            },
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlanDetailCard extends StatelessWidget {
  // Define your parameters here
  final String coachName;
  final String planCategory;
  final String planTitle;
  final String planDescription;
  final String duration;
  final String workoutsPerWeek;
  final String level;
  final IconData profileIcon;
  final String price;
  final BuildContext context;
  final Map<String, dynamic> planData;

  const PlanDetailCard({
    super.key,
    required this.coachName,
    required this.planCategory,
    required this.planTitle,
    required this.planDescription,
    required this.duration,
    required this.workoutsPerWeek,
    required this.level,
    required this.price,
    required this.context,
    required this.planData,
    this.profileIcon = Icons.person, // Default icon if none provided
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanDetailPage(planData: planData),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF08140E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlowingAvatar(profileIcon),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBorderedText(coachName, isTitle: true),
                      const SizedBox(height: 10),
                      _buildBorderedText(
                        planCategory,
                        color: const Color(0xFF1CFF4D),
                      ),
                    ],
                  ),
                ),
                _buildInfoBox(),
              ],
            ),
            const SizedBox(height: 25),
            _buildBorderedText(planTitle, isTitle: true, fontSize: 28),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'plan description',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    planDescription,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: GreenButton(
                label: "Get",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlanPurchasePage(planData: planData),
                    ),
                  );
                },
                horzSize: 25,
                vertSize: 10,
              ),
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.center,
              child: Text(
                price == '0' || price == '0.0' ? 'Free' : 'Price: \$$price',
                style: const TextStyle(
                  color: Color(0xFF1CFF4D),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildGlowingAvatar(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xFF1CFF4D), width: 3),
      ),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.black,
        child: Icon(icon, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildBorderedText(
    String text, {
    bool isTitle = false,
    double fontSize = 22,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text.toLowerCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isTitle ? FontWeight.w900 : FontWeight.normal,
          fontStyle: isTitle ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'plan info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.lock_outline, 'Duration: $duration'),
          _infoRow(Icons.fitness_center, 'Workouts: $workoutsPerWeek'),
          _infoRow(Icons.trending_up, 'Level: $level'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1CFF4D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class PlanDetailCardMe extends StatelessWidget {
  // Define your parameters here
  final String coachName;
  final String planCategory;
  final String planTitle;
  final String planDescription;
  final String duration;
  final String workoutsPerWeek;
  final String level;
  final IconData profileIcon;
  final String price;
  final String planId;
  final VoidCallback onDelete;
  final Map<String, dynamic>? planData;

  const PlanDetailCardMe({
    super.key,
    required this.coachName,
    required this.planCategory,
    required this.planTitle,
    required this.planDescription,
    required this.duration,
    required this.workoutsPerWeek,
    required this.level,
    required this.price,
    required this.planId,
    required this.onDelete,
    this.planData,
    this.profileIcon = Icons.person, // Default icon if none provided
  });

  @override
  Widget build(BuildContext context) {
    final planDataToUse =
        planData ??
        {
          'title': planTitle,
          'category': planCategory,
          'description': planDescription,
          'duration': int.tryParse(duration.split(' ')[0]) ?? 0,
          'workouts_per_week': int.tryParse(workoutsPerWeek.split(' ')[0]) ?? 0,
          'level': level,
          'price': double.tryParse(price) ?? 0,
          'coach_name': coachName,
          'id': planId,
        };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanDetailPage(planData: planDataToUse),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF08140E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlowingAvatar(profileIcon),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBorderedText(coachName, isTitle: true),
                      const SizedBox(height: 10),
                      _buildBorderedText(
                        planCategory,
                        color: const Color(0xFF1CFF4D),
                      ),
                    ],
                  ),
                ),
                _buildInfoBox(),
              ],
            ),
            const SizedBox(height: 25),
            _buildBorderedText(planTitle, isTitle: true, fontSize: 28),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'plan description',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    planDescription,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: Text(
                price == '0' || price == '0.0' ? 'Free' : 'Price: \$$price',
                style: const TextStyle(
                  color: Color(0xFF1CFF4D),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Delete Button
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Delete Plan',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildGlowingAvatar(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xFF1CFF4D), width: 3),
      ),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.black,
        child: Icon(icon, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildBorderedText(
    String text, {
    bool isTitle = false,
    double fontSize = 22,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text.toLowerCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isTitle ? FontWeight.w900 : FontWeight.normal,
          fontStyle: isTitle ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'plan info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.lock_outline, 'Duration: $duration'),
          _infoRow(Icons.fitness_center, 'Workouts: $workoutsPerWeek'),
          _infoRow(Icons.trending_up, 'Level: $level'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1CFF4D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
