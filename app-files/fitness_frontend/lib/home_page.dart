// ignore: file_names
import 'dart:convert';

import 'package:fitness/allplans.dart';
import 'package:fitness/createplanpage.dart';
import 'package:fitness/premiumad.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fitness/custom_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Add this
import 'package:fitness/config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userRole;
  String? userName;
  bool isLoading = true;
  late Future<List<dynamic>> _featuredPlansFuture;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allPlans = [];
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _featuredPlansFuture = _fetchFeaturedPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final results = _allPlans.where((plan) {
      final title = plan['title']?.toString().toLowerCase() ?? '';
      final category = plan['category']?.toString().toLowerCase() ?? '';
      final coachName = plan['coach_name']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
          category.contains(searchQuery) ||
          coachName.contains(searchQuery);
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  // Fetch role from SharedPreferences
  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_role'); // Match login key from login
      userName = prefs.getString('username');
      isLoading = false;
    });
  }

  Future<List<dynamic>> _fetchFeaturedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse("${Config.apiBaseUrl}/plans/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> allPlans = jsonDecode(response.body);
      // Store all plans for search functionality
      _allPlans = allPlans;
      return allPlans;
    } else {
      throw Exception("Failed to load plans: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050D09),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1CFF4D)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050D09),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1A12), Color(0xFF050D09)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sleek Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TimeOfDay.now().format(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              "TODAY'S SCHEDULE",
                              style: TextStyle(
                                color: Color(0xFF1CFF4D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        // --- CONDITIONAL BUTTON ---
                        // Only shows if userRole is exactly 'coach'
                        if (userRole == 'coach')
                          GreenButton(
                            label: "Create plan",
                            onPressed: () async {
                              // 1. Wait for the page to pop
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreatePlanPage(),
                                ),
                              );

                              // 2. This code runs AFTER CreatePlanPage is closed
                              setState(() {
                                // This triggers a rebuild, and if you have a FutureBuilder,
                                // it will fetch the data again.
                                _featuredPlansFuture = _fetchFeaturedPlans();
                              });
                            },

                            horzSize: 20,
                            vertSize: 25,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildHorizontalCalendar(),
                  const SizedBox(height: 25),
                  _buildPremiumPromo(context),
                  const SizedBox(height: 30),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _performSearch,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              "Search plans by name, category, or coach...",
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    context,
                    title: _isSearching ? "Search Results" : "Active Plans",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlansListPage(userName: userName),
                        ),
                      );
                    },
                  ),

                  // Featured Plans or Search Results
                  _isSearching
                      ? _buildSearchResults()
                      : FutureBuilder<List<dynamic>>(
                          future: _featuredPlansFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1CFF4D),
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  "No plans found.",
                                  style: TextStyle(color: Colors.white38),
                                ),
                              );
                            }

                            final plans = snapshot.data!;

                            return Column(
                              children: plans
                                  .where(
                                    (plan) => plan['coach_name'] != userName,
                                  ) // Show plans NOT belonging to the current user
                                  .map((plan) {
                                    return PlanDetailCard(
                                      coachName:
                                          plan['coach_name'] ?? "Elite Coach",
                                      planCategory:
                                          plan['category'] ?? "Training",
                                      planTitle: plan['title'] ?? "New Plan",
                                      planDescription:
                                          plan['description'] ?? "",
                                      duration: "${plan['duration']} Weeks",
                                      workoutsPerWeek:
                                          "${plan['workouts_per_week']} Days",
                                      level: plan['level'] ?? "Intermediate",
                                      price: "${plan['price'] ?? 0.0}",
                                      context: context,
                                      planData: plan,
                                    );
                                  })
                                  .toList(),
                            );
                          },
                        ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: List.generate(7, (index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: index == 0
                  ? const Color(0xFF1CFF4D)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                  style: TextStyle(
                    color: index == 0 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${15 + index}',
                  style: TextStyle(
                    color: index == 0 ? Colors.black : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPremiumPromo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _glassContainer(
        height: 140,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.star,
                size: 150,
                color: const Color(0xFF1CFF4D).withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "TRY PREMIUM PLANS",
                    style: TextStyle(
                      color: Color(0xFF1CFF4D),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Unlock elite coaching & custom routines",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MembershipTiersPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1CFF4D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Go Pro",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Text(
                    "View All",
                    style: TextStyle(
                      color: Color(0xFF1CFF4D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Color(0xFF1CFF4D),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassContainer({required Widget child, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          "No plans match your search.",
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return Column(
      children: _searchResults
          .where((plan) => plan['coach_name'] != userName)
          .map((plan) {
            return PlanDetailCard(
              coachName: plan['coach_name'] ?? "Elite Coach",
              planCategory: plan['category'] ?? "Training",
              planTitle: plan['title'] ?? "New Plan",
              planDescription: plan['description'] ?? "",
              duration: "${plan['duration']} Weeks",
              workoutsPerWeek: "${plan['workouts_per_week']} Days",
              level: plan['level'] ?? "Intermediate",
              price: "${plan['price'] ?? 0.0}",
              context: context,
              planData: plan,
            );
          })
          .toList(),
    );
  }
}
