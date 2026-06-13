import 'package:fitness/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/config.dart';

// Import your custom widget file here
// import 'package:fitness/plan_detail_card.dart';

class PlansListPage extends StatefulWidget {
  final String? userName;

  const PlansListPage({super.key, required this.userName});

  @override
  State<PlansListPage> createState() => _PlansListPageState();
}

class _PlansListPageState extends State<PlansListPage> {
  // Replace with 10.0.2.2 for Android Emulator or your Local IP
  final String apiUrl = "${Config.apiBaseUrl}/plans/";

  Future<List<dynamic>> fetchPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final currentUserId = prefs.getInt('user_id');

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> allPlans = jsonDecode(response.body);

      // Filter out plans created by the current user (coach)
      if (currentUserId != null) {
        allPlans = allPlans
            .where((plan) => plan['coach_id'] != currentUserId)
            .toList();
      }

      return allPlans;
    } else {
      throw Exception("Failed to load plans: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "AVAILABLE PLANS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CFF4D)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No plans available yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final plans = snapshot.data!;

          return Column(
            children: plans
                .where(
                  (plan) => plan['coach_name'] != widget.userName,
                ) // Show plans NOT belonging to the current user
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
        },
      ),
    );
  }
}
