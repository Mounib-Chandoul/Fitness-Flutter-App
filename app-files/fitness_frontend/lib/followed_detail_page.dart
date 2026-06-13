import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:fitness/config.dart';

class FollowedDetailPage extends StatefulWidget {
  final Map<String, dynamic> coachData;

  const FollowedDetailPage({super.key, required this.coachData});

  @override
  State<FollowedDetailPage> createState() => _FollowedDetailPageState();
}

class _FollowedDetailPageState extends State<FollowedDetailPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController specializationController;
  late TextEditingController bioController;

  bool isEditing = false;
  bool isSaving = false;
  bool showCardForm = false;
  late String selectedEmoji;

  // only allow editing if the displayed coach is the logged-in user
  bool isOwner = false;

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

  // Card form controllers
  late TextEditingController cardNumberController;
  late TextEditingController cardHolderController;
  late TextEditingController expiryController;
  late TextEditingController cvvController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.coachData['name'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.coachData['email'] ?? '',
    );
    specializationController = TextEditingController(
      text: widget.coachData['specialization'] ?? '',
    );
    bioController = TextEditingController(text: widget.coachData['bio'] ?? '');
    selectedEmoji = widget.coachData['emoji'] ?? '⚡';

    _checkOwnership();

    cardNumberController = TextEditingController();
    cardHolderController = TextEditingController();
    expiryController = TextEditingController();
    cvvController = TextEditingController();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null && id == widget.coachData['id']) {
      setState(() => isOwner = true);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    specializationController.dispose();
    bioController.dispose();
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!isOwner) return;
    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _showSnackBar('Authentication error', isError: true);
        return;
      }

      final response = await http.patch(
        Uri.parse("${Config.apiBaseUrl}/coach-profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": nameController.text,
          "email": emailController.text,
          "specialization": specializationController.text,
          "bio": bioController.text,
          "emoji": selectedEmoji,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          // Save emoji to local storage for next login
          await prefs.setString(
            'coach_emoji_${widget.coachData['id']}',
            selectedEmoji,
          );

          setState(() {
            isEditing = false;
            widget.coachData['name'] = nameController.text;
            widget.coachData['email'] = emailController.text;
            widget.coachData['specialization'] = specializationController.text;
            widget.coachData['bio'] = bioController.text;
            widget.coachData['emoji'] = selectedEmoji;
          });
          if (isOwner) {
            // sync prefs if the current user updated own profile
            await prefs.setString('user_bio', bioController.text);
            await prefs.setString(
              'user_specialization',
              specializationController.text,
            );
            await prefs.setString('user_emoji', selectedEmoji);
          }
          _showSnackBar('Profile updated successfully!');
        } else {
          _showSnackBar('Failed to update profile', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _saveCardDetails() async {
    if (cardNumberController.text.isEmpty ||
        cardHolderController.text.isEmpty ||
        expiryController.text.isEmpty ||
        cvvController.text.isEmpty) {
      _showSnackBar('Please fill all card details', isError: true);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final username = prefs.getString('username');

      if (token == null) {
        _showSnackBar('Authentication error', isError: true);
        return;
      }

      final response = await http.post(
        Uri.parse("${Config.apiBaseUrl}/save-card"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "username": username,
          "coach_id": widget.coachData['id'],
          "card_number": cardNumberController.text,
          "card_holder": cardHolderController.text,
          "expiry": expiryController.text,
          "cvv": cvvController.text,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() => showCardForm = false);
          cardNumberController.clear();
          cardHolderController.clear();
          expiryController.clear();
          cvvController.clear();
          _showSnackBar('Card saved successfully!');
        } else {
          _showSnackBar('Failed to save card', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1CFF4D),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose Your Emoji",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: fitnessEmojis.length,
              itemBuilder: (context, index) {
                final emoji = fitnessEmojis[index];
                final isSelected = selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedEmoji = emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1CFF4D).withValues(alpha: 0.3)
                          : const Color(0xFF0F1A15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1CFF4D)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.coachData['name'] ?? 'Coach Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((widget.coachData['specialization'] ?? '')
                              .isNotEmpty)
                            Text(
                              widget.coachData['specialization'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      isEditing
                          ? IconButton(
                              onPressed: isSaving ? null : _saveProfile,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF1CFF4D),
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check,
                                      color: Color(0xFF1CFF4D),
                                    ),
                            )
                          : (isOwner
                                ? IconButton(
                                    onPressed: () =>
                                        setState(() => isEditing = true),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF1CFF4D),
                                    ),
                                  )
                                : const SizedBox(width: 24)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: isEditing ? () => _showEmojiPicker() : null,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CFF4D),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1CFF4D,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                selectedEmoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Color(0xFF1CFF4D),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Profile Fields
                  _buildProfileField(
                    label: "Name",
                    controller: nameController,
                    enabled: isEditing && isOwner,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    label: "Email",
                    controller: emailController,
                    enabled: isEditing && isOwner,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    label: "Specialization",
                    controller: specializationController,
                    enabled: isEditing && isOwner,
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    label: "Bio",
                    controller: bioController,
                    enabled: isEditing && isOwner,
                    icon: Icons.info,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          label: "Rating",
                          value: "${widget.coachData['rating'] ?? '⭐'} Stars",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          label: "Plans",
                          value:
                              "${widget.coachData['plans_count'] ?? 0} Created",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Card Section
                  Text(
                    "Payment Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!showCardForm)
                    _buildAddCardButton()
                  else
                    _buildCardForm(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: enabled ? const Color(0xFF1CFF4D) : Colors.white30,
            ),
            filled: true,
            fillColor: enabled
                ? const Color(0xFF1A2A22)
                : const Color(0xFF0F1A15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF1CFF4D).withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1CFF4D)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String label, required String value}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1CFF4D).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1CFF4D),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCardButton() {
    return GestureDetector(
      onTap: () => setState(() => showCardForm = true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A22).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1CFF4D).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card, color: const Color(0xFF1CFF4D)),
              const SizedBox(width: 8),
              const Text(
                "Add Card Details",
                style: TextStyle(
                  color: Color(0xFF1CFF4D),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        _buildCardInput(
          label: "Card Number",
          controller: cardNumberController,
          hint: "1234 5678 9012 3456",
          maxLength: 19,
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 12),
        _buildCardInput(
          label: "Card Holder",
          controller: cardHolderController,
          hint: "John Doe",
          icon: Icons.person,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCardInput(
                label: "Expiry",
                controller: expiryController,
                hint: "MM/YY",
                maxLength: 5,
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardInput(
                label: "CVV",
                controller: cvvController,
                hint: "123",
                maxLength: 3,
                isPassword: true,
                icon: Icons.lock,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => showCardForm = false),
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
                onPressed: _saveCardDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CFF4D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Save Card",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLength: maxLength,
          keyboardType: label == "Card Number"
              ? TextInputType.number
              : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: const Color(0xFF1CFF4D)),
            filled: true,
            fillColor: const Color(0xFF1A2A22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterText: "",
          ),
        ),
      ],
    );
  }
}
