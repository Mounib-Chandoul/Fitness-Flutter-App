import 'dart:ui';
import 'dart:convert';
import 'package:fitness/allplansme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/login_page.dart';
import 'package:fitness/user_state.dart';
import 'package:fitness/config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName;
  String? userEmail;
  String? userRole;
  String userEmoji = "⚡";
  bool isLoading = true;
  bool isEditingName = false;
  bool isSavingName = false;
  late TextEditingController nameEditController;

  // Coach fields
  late TextEditingController bioController;
  late TextEditingController specializationController;
  bool isEditingBio = false;
  bool isSavingBio = false;

  final List<String> fitnessEmojis = [
    "⚡",
    "🔥",
    "💪",
    "🏋️",
    "🏃",
    "🥗",
    "🧘",
    "🏆",
    "🎯",
    "🦁",
    "🦈",
    "🦾",
    "🥊",
    "🚴",
  ];

  @override
  void initState() {
    super.initState();
    nameEditController = TextEditingController();
    bioController = TextEditingController();
    specializationController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    nameEditController.dispose();
    bioController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('username') ?? "Fitness User";
      nameEditController.text = userName ?? "Fitness User";
      userEmail = prefs.getString('email') ?? "";
      userRole = prefs.getString('user_role') ?? "Member";
      userEmoji = prefs.getString('user_emoji') ?? "⚡";
      bioController.text = prefs.getString('user_bio') ?? "";
      specializationController.text =
          prefs.getString('user_specialization') ?? "";
      isLoading = false;
    });
  }

  Future<void> _saveName() async {
    if (nameEditController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => isSavingName = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _showErrorSnackBar('Authentication failed');
        return;
      }

      final response = await http.patch(
        Uri.parse("${Config.apiBaseUrl}/users/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": nameEditController.text}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          await prefs.setString('username', nameEditController.text);
          // update global UserState so HomeHeader re-renders
          UserState.username.value = nameEditController.text;
          setState(() {
            userName = nameEditController.text;
            isEditingName = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Name updated successfully!'),
                backgroundColor: Color(0xFF1CFF4D),
              ),
            );
          }
        } else {
          _showErrorSnackBar('Failed to update name');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSavingName = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveBioAndSpecialization() async {
    setState(() => isSavingBio = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _showErrorSnackBar('Authentication failed');
        return;
      }

      final response = await http.patch(
        Uri.parse("${Config.apiBaseUrl}/users/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "bio": bioController.text,
          "specialization": specializationController.text,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            isEditingBio = false;
          });
          // persist to locals
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_bio', bioController.text);
          await prefs.setString(
            'user_specialization',
            specializationController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Color(0xFF1CFF4D),
              ),
            );
          }
        } else {
          _showErrorSnackBar(
            response.statusCode == 401
                ? 'Please log in again'
                : 'Failed to update profile',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSavingBio = false);
      }
    }
  }

  // --- SYNC EMOJI WITH SERVER ---
  Future<void> _updateEmoji(String newEmoji) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // Update locally first for speed
    setState(() => userEmoji = newEmoji);
    UserState.emoji.value = newEmoji;
    await prefs.setString('user_emoji', newEmoji);

    try {
      await http.post(
        Uri.parse("${Config.apiBaseUrl}/update-avatar"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"emoji": newEmoji}),
      );
    } catch (e) {
      debugPrint("Server sync failed: $e");
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildAvatarSection(),
                  const SizedBox(height: 30),

                  // --- NEW: MY CREATED PLANS SECTION ---
                  // Only show this if the user is a coach or has created content
                  if (userRole == 'coach') _buildMyContentCard(),

                  const SizedBox(height: 30),
                  _buildEditableNameField(),
                  const SizedBox(height: 20),
                  _buildProfileField(
                    label: "EMAIL ADDRESS",
                    value: userEmail!,
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 20),
                  _buildProfileField(
                    label: "ROLE",
                    value: userRole!.toUpperCase(),
                    icon: Icons.shield_outlined,
                  ),

                  // Bio field for all users
                  const SizedBox(height: 30),
                  _buildBioField(),
                  const SizedBox(height: 20),

                  // Coach-specific fields
                  if (userRole == 'coach') ...[
                    _buildCoachSpecializationField(),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW WIDGET: CREATED PLANS CARD ---
  Widget _buildMyContentCard() {
    return GestureDetector(
      onTap: () {
        // Navigate to PlansListPage, passing the userEmail to filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlansMeListPage(
              userName: userName,
            ), // Logic inside allplans.dart will handle filtering by coach name/email
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1CFF4D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF1CFF4D).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1CFF4D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.black),
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MY CREATED PLANS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Manage your training programs",
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF1CFF4D),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            "FULL NAME",
            style: const TextStyle(
              color: Color(0xFF1CFF4D),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (!isEditingName)
          GestureDetector(
            onTap: () {
              nameEditController.text = userName ?? "";
              setState(() => isEditingName = true);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          userName ?? "Fitness User",
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.edit,
                        color: Color(0xFF1CFF4D),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1CFF4D).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: nameEditController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF1CFF4D),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A2A22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: "Enter your name",
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() => isEditingName = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSavingName ? null : _saveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1CFF4D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isSavingName
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Save",
                                    style: TextStyle(color: Colors.black),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper methods (_buildHeader, _buildAvatarSection, _buildProfileField, _buildLogoutButton)
  // remain the same as your previous version to keep the code clean...
  // [Insert those methods here]

  Widget _buildHeader() {
    // show name and specialization if coach, otherwise generic title
    if (userRole == 'coach') {
      return Column(
        children: [
          Text(
            userName ?? 'Coach',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specializationController.text.isNotEmpty
                ? specializationController.text
                : 'Fitness Coach',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
    return const Center(
      child: Text(
        "PROFILE SETTINGS",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1CFF4D).withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: const Color(0xFF1CFF4D), width: 2),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: const Color(0xFF050D09),
              child: Text(userEmoji, style: const TextStyle(fontSize: 60)),
            ),
          ),
          GestureDetector(
            onTap: _showEmojiPicker,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF1CFF4D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A12).withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                ),
                itemCount: fitnessEmojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _updateEmoji(fitnessEmojis[index]);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: userEmoji == fitnessEmojis[index]
                              ? const Color(0xFF1CFF4D)
                              : Colors.white10,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          fitnessEmojis[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1CFF4D),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white38, size: 22),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0B1A12),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              TextButton(
                onPressed: _handleLogout,
                child: const Text(
                  "LOGOUT",
                  style: TextStyle(color: Color(0xFFFF4D4D)),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF4D4D).withValues(alpha: 0.4),
          ),
        ),
        child: const Center(
          child: Text(
            "LOGOUT ACCOUNT",
            style: TextStyle(
              color: Color(0xFFFF4D4D),
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBioField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF1CFF4D).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "BIO",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (!isEditingBio)
                    GestureDetector(
                      onTap: () => setState(() => isEditingBio = true),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF1CFF4D),
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (isEditingBio)
                Column(
                  children: [
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your bio",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1CFF4D),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFF1CFF4D,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1CFF4D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => isEditingBio = false),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSavingBio
                              ? null
                              : _saveBioAndSpecialization,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1CFF4D),
                          ),
                          child: isSavingBio
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.black),
                                ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Text(
                  bioController.text.isEmpty
                      ? "No bio added yet"
                      : bioController.text,
                  style: TextStyle(
                    color: bioController.text.isEmpty
                        ? Colors.white38
                        : Colors.white,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachSpecializationField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF1CFF4D).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "SPECIALIZATION",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (!isEditingBio)
                    GestureDetector(
                      onTap: () => setState(() => isEditingBio = true),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF1CFF4D),
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (isEditingBio)
                Column(
                  children: [
                    TextField(
                      controller: specializationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "e.g., Strength Training, Yoga, Cardio",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1CFF4D),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFF1CFF4D,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1CFF4D),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  specializationController.text.isEmpty
                      ? "No specialization added yet"
                      : specializationController.text,
                  style: TextStyle(
                    color: specializationController.text.isEmpty
                        ? Colors.white38
                        : Colors.white,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
