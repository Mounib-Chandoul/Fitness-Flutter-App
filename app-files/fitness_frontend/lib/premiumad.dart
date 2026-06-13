import 'dart:ui';
import 'package:fitness/allplans.dart';
import 'package:flutter/material.dart';
import 'package:fitness/custom_widgets.dart';

class MembershipTiersPage extends StatelessWidget {
  const MembershipTiersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgroundFitness.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.85),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "CHOOSE YOUR\nLEVEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'montserrat',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Access elite training methodologies used by pro athletes.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // --- PREMIUM PLANS CARD ---
                _buildTierCard(
                  context,
                  title: "PREMIUM PLANS",
                  subtitle: "CURATED BY TOP-TIER COACHES",
                  description:
                      "Unlock the secrets of the pros. These plans include advanced periodization, secret recovery techniques, and specialized hypertrophy modules.",
                  features: [
                    "Elite Coach Insights",
                    "Hidden Pro Techniques",
                    "Video Demonstrations",
                  ],
                  icon: Icons.workspace_premium,
                  isPopular: true,
                ),

                const SizedBox(height: 25),

                // --- CUSTOM PLANS CARD ---
                _buildTierCard(
                  context,
                  title: "CUSTOM PLANS",
                  subtitle: "TAILORED TO YOUR GENETICS",
                  description:
                      "Work 1-on-1 with a coach. Tell them your goals, your limitations, and your schedule. Get a blueprint designed exclusively for you.",
                  features: [
                    "Direct Coach Messaging",
                    "Weekly Plan Adjustments",
                    "Personal Goal Tracking",
                  ],
                  icon: Icons.access_time_sharp,
                  isPopular: false,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required IconData icon,
    required bool isPopular,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isPopular
                  ? const Color(0xFF1CFF4D).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: const Color(0xFF1CFF4D), size: 30),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1CFF4D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "MOST ELITE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'montserrat',
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF1CFF4D),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF1CFF4D),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        f,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: GreenButton(
                  label: "SELECT PLAN",
                  horzSize: 100,
                  vertSize: 22,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlansListPage(userName: ""),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
