import 'package:fitness/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/config.dart';

// Import your custom widget file here
// import 'package:fitness/plan_detail_card.dart';

class PlansMeListPage extends StatefulWidget {
  final String? userName;

  const PlansMeListPage({super.key, required this.userName});

  @override
  State<PlansMeListPage> createState() => _PlansMeListPageState();
}

class _PlansMeListPageState extends State<PlansMeListPage> {
  // Replace with 10.0.2.2 for Android Emulator or your Local IP
  final String apiUrl = "${Config.apiBaseUrl}/plans/my";

  Future<List<dynamic>> fetchPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load plans: ${response.statusCode}");
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse("${Config.apiBaseUrl}/plans/$planId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan deleted successfully!'),
            backgroundColor: Color(0xFF1CFF4D),
          ),
        );
        // Refresh the page
        setState(() {});
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete plan: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(String planTitle, String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1A12),
        title: const Text(
          'Delete Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$planTitle"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deletePlan(planId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

          final coachPlans = plans
              .where((plan) => plan['coach_name'] == widget.userName)
              .toList();

          if (coachPlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No Plans Yet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You haven't created any plans yet.\nStart building your coaching empire!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CFF4D).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1CFF4D).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      "Create your first plan to get started!",
                      style: TextStyle(
                        color: Color(0xFF1CFF4D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: coachPlans.map((plan) {
              return PlanDetailCardMe(
                coachName: plan['coach_name'] ?? "Elite Coach",
                planCategory: plan['category'] ?? "Training",
                planTitle: plan['title'] ?? "New Plan",
                planDescription: plan['description'] ?? "",
                duration: "${plan['duration']} Weeks",
                workoutsPerWeek: "${plan['workouts_per_week']} Days",
                level: plan['level'] ?? "Intermediate",
                price: "${plan['price'] ?? 0.0}",
                planId: plan['id'].toString(),
                planData: plan,
                onDelete: () => _showDeleteConfirmation(
                  plan['title'] ?? "Plan",
                  plan['id'].toString(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
