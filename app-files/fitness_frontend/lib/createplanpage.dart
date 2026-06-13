import 'package:flutter/material.dart';
import 'package:fitness/custom_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/config.dart';

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({super.key});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dietController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _workoutsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<TextEditingController> _exerciseControllers = [
    TextEditingController(),
  ];

  String _selectedLevel = 'Intermediate';
  String _selectedCategory = 'Strength Training';
  bool _isLoading = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dietController.dispose();
    _durationController.dispose();
    _workoutsController.dispose();
    _priceController.dispose();
    for (var controller in _exerciseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exerciseControllers.add(TextEditingController());
    });
  }

  void _removeExercise(int index) {
    if (_exerciseControllers.length > 1) {
      setState(() {
        _exerciseControllers[index].dispose();
        _exerciseControllers.removeAt(index);
      });
    }
  }

  Future<void> _handleCreatePlan() async {
    final title = _titleController.text.trim();
    final exercises = _exerciseControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (title.isEmpty || exercises.isEmpty) {
      _showSnackBar(
        "Please add a title and at least one exercise and set a price",
      );
      return;
    }

    setState(() => _isLoading = true);

    // Note: Use 10.0.2.2 if using Android Emulator, otherwise use your PC IP
    final String apiUrl = "${Config.apiBaseUrl}/plans/";

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      // the login page stores the name under "username" not "user_name"
      // (and the server ignores any creator_name field anyway), so we don't
      // actually need to send it at all.  keep the request body minimal.
      if (token == null) {
        _showSnackBar("Session expired. Please login again.");
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "category": _selectedCategory,
          "description": _descriptionController.text.trim(),
          "diet": _dietController.text.trim(),
          "duration": int.tryParse(_durationController.text) ?? 0,
          "workouts_per_week": int.tryParse(_workoutsController.text) ?? 0,
          "level": _selectedLevel,
          "exercises": exercises,
          "price": price,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Plan Created Successfully!");
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        final errorBody = jsonDecode(response.body);
        _showSnackBar(errorBody['detail'] ?? "Failed to create plan");
      }
    } catch (e) {
      _showSnackBar("Connection error. Check if FastAPI is running.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1A12), Color(0xFF08140E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
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
                    const SizedBox(height: 10),
                    const Text(
                      'Design Your\nTraining Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Plan Title"),
                              _inputField(
                                hint: "Name your plan",
                                icon: Icons.title,
                                controller: _titleController,
                                isNumber: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Plan Price"),
                              _inputField(
                                hint: "Set a price",
                                icon: Icons.monetization_on,
                                controller: _priceController,
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _label("Category"),
                    _categoryDropdownField(),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Duration (Weeks)"),
                              _inputField(
                                hint: "6",
                                icon: Icons.calendar_today,
                                controller: _durationController,
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Workouts/Week"),
                              _inputField(
                                hint: "5",
                                icon: Icons.repeat,
                                controller: _workoutsController,
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _label("Difficulty Level"),
                    _dropdownField(),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _label("Exercises / Routine"),
                        GestureDetector(
                          onTap: _addExercise,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1CFF4D,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFF1CFF4D,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Color(0xFF1CFF4D),
                                  size: 16,
                                ),
                                Text(
                                  " Add",
                                  style: TextStyle(
                                    color: Color(0xFF1CFF4D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exerciseControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Text(
                                "${index + 1}.",
                                style: const TextStyle(
                                  color: Colors.white24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _inputField(
                                  hint: "Exercise name",
                                  icon: Icons.bolt,
                                  controller: _exerciseControllers[index],
                                ),
                              ),
                              if (_exerciseControllers.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeExercise(index),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _label("Plan Description"),
                    _inputField(
                      hint: "What is this plan about?",
                      icon: Icons.description_outlined,
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    _label("Diet Plan"),
                    _inputField(
                      hint: "Describe the diet/nutrition guidelines",
                      icon: Icons.restaurant_outlined,
                      controller: _dietController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),

                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF1CFF4D),
                            )
                          : GreenButton(
                              label: "Publish Plan",
                              onPressed: _handleCreatePlan,
                              horzSize: 120,
                              vertSize: 25,
                            ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(maxLines > 1 ? 15 : 25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLevel,
          dropdownColor: const Color(0xFF0B1A12),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white),
          onChanged: (String? newValue) =>
              setState(() => _selectedLevel = newValue!),
          items: <String>['Beginner', 'Intermediate', 'Advanced']
              .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget _categoryDropdownField() {
    final List<String> categories = [
      'Strength Training',
      'Cardio & Endurance',
      'Weight Loss',
      'Muscle Building',
      'CrossFit',
      'Yoga & Flexibility',
      'HIIT (High-Intensity Interval Training)',
      'Bodybuilding',
      'Powerlifting',
      'Olympic Weightlifting',
      'Functional Fitness',
      'Calisthenics',
      'Martial Arts',
      'Boxing & Combat Sports',
      'Running & Jogging',
      'Cycling',
      'Swimming',
      'Sports Performance',
      'Rehabilitation',
      'Senior Fitness',
      'Women\'s Fitness',
      'Men\'s Fitness',
      'Athletic Performance',
      'General Fitness',
      'Home Workouts',
      'Gym Workouts',
      'Outdoor Training',
      'Nutrition & Diet',
      'Mental Wellness',
      'Recovery & Mobility',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          dropdownColor: const Color(0xFF0B1A12),
          icon: const Icon(Icons.category_outlined, color: Colors.white54),
          style: const TextStyle(color: Colors.white),
          onChanged: (String? newValue) =>
              setState(() => _selectedCategory = newValue!),
          items: categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}
