import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fitness/config.dart';
import 'package:fitness/followed_detail_page.dart';
import 'package:fitness/plan_detail_page.dart';

class FollowedPage extends StatefulWidget {
  final bool isActive;

  const FollowedPage({super.key, this.isActive = false});

  @override
  State<FollowedPage> createState() => _FollowedPageState();
}

class _FollowedPageState extends State<FollowedPage> {
  List<Map<String, dynamic>> followedCoaches = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFollowedCoaches();
  }

  @override
  void didUpdateWidget(covariant FollowedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadFollowedCoaches();
    }
  }

  Future<void> _loadFollowedCoaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final email = prefs.getString('email');

      if (token == null || email == null) {
        if (mounted) {
          setState(() {
            errorMessage = "Please log in to see followed coaches";
            isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse("${Config.apiBaseUrl}/followed-coaches/$email"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            followedCoaches = List<Map<String, dynamic>>.from(
              data['coaches'] ?? [],
            );
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = response.statusCode == 401
                ? "Please log in again"
                : "Failed to load followed coaches";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1A12), Color(0xFF08140E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Subscriptions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1CFF4D),
                      ),
                    )
                  : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadFollowedCoaches,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1CFF4D),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    )
                  : followedCoaches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            color: Colors.white30,
                            size: 64,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No subscriptions yet",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFollowedCoaches,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        children: [
                          // My Plans Section
                          _buildMyPlansSection(),
                          const SizedBox(height: 30),
                          // Coaches Section
                          Padding(
                            padding: const EdgeInsets.only(left: 0, bottom: 12),
                            child: Text(
                              'Coaches',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...followedCoaches.map(
                            (coach) => _buildCoachCard(coach),
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

  Widget _buildMyPlansSection() {
    // Extract all unique subscribed plans from coaches
    final Set<String> planTitles = {};
    final List<Map<String, dynamic>> allPlans = [];

    for (var coach in followedCoaches) {
      if (coach['plans'] is List) {
        for (var plan in coach['plans'] as List) {
          if (plan is Map && plan['id'] != null && plan['title'] != null) {
            final planId = plan['id'].toString();
            if (!planTitles.contains(planId)) {
              planTitles.add(planId);
              allPlans.add(plan as Map<String, dynamic>);
            }
          }
        }
      }
    }

    if (allPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              color: Colors.white30,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              "No plans subscribed yet",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Your Plans (${allPlans.length})',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPlans.length,
            itemBuilder: (context, index) {
              final plan = allPlans[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == allPlans.length - 1 ? 0 : 12,
                ),
                child: _buildPlanCard(plan),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final title = plan['title'] ?? 'Untitled Plan';
    final category = plan['category'] ?? 'Fitness';
    final duration = plan['duration'] ?? 0;
    final level = plan['level'] ?? 'All Levels';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanDetailPage(planData: plan),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1CFF4D).withValues(alpha: 0.15),
              const Color(0xFF1CFF4D).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1CFF4D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.length > 12
                    ? '${category.substring(0, 12)}...'
                    : category,
                style: const TextStyle(
                  color: Color(0xFF1CFF4D),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.length > 20 ? '${title.substring(0, 20)}...' : title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Duration & Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$duration weeks',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                Text(
                  level,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowedDetailPage(coachData: coach),
          ),
        ).then((_) {
          _loadFollowedCoaches(); // Refresh when returning
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A22).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1CFF4D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    coach['emoji'] ?? '⚡',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Coach Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach['name'] ?? 'Coach',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coach['specialization'] ?? 'Fitness Coach',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rating: ${coach['rating'] ?? '⭐'} | Plans: ${coach['plans_count'] ?? 0}",
                      style: TextStyle(
                        color: const Color(0xFF1CFF4D).withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    // if we have the actual plans list from the server show the
                    // titles in a subtle subtitle. this helps the user remember
                    // what they've bought without opening the detail page.
                    if (coach['plans'] != null && coach['plans'] is List)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          (coach['plans'] as List)
                              .map((p) => p['title'] ?? '')
                              .where((t) => t.isNotEmpty)
                              .join(', '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF1CFF4D).withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
