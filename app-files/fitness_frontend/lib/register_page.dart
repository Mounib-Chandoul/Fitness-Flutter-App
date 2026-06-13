import 'package:fitness/config.dart';
import 'package:flutter/material.dart';
import 'package:fitness/custom_widgets.dart';
import 'package:fitness/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.role, required this.title});

  final String role;
  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
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
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- REGISTRATION LOGIC WITH INPUT CONTROLS ---
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Basic Empty Check
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    // 2. Name Check: Exactly one word (no internal spaces)
    if (name.contains(" ")) {
      _showSnackBar("Name must be a single word (no spaces)");
      return;
    }

    // 3. Gmail Validation: Must end with @gmail.com
    final bool isGmail = RegExp(
      r"^[a-zA-Z0-9._%+-]+@gmail\.com$",
    ).hasMatch(email);

    if (!isGmail) {
      _showSnackBar("Please enter a valid @gmail.com address");
      return;
    }

    // 4. Password Length Check: Must be > 6 (at least 7 characters)
    if (password.length <= 6) {
      _showSnackBar("Password must be longer than 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    // Use 127.0.0.1 for local Linux testing
    final String apiUrl = "${Config.apiBaseUrl}/auth/register";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "role": widget.role.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Registration successful! Please login.");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(error['detail'] ?? "Registration failed");
      }
    } catch (e) {
      _showSnackBar("Could not connect to server. Ensure FastAPI is running.");
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Create Account\nAs a ${widget.role}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      _label("Full Name (Single word)"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "Enter your name",
                        icon: Icons.person_outline,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 18),
                      _label("Gmail Address"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "example@gmail.com",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 18),
                      _label("Password (> 6 chars)"),
                      const SizedBox(height: 8),
                      _inputField(
                        hint: "Create a password",
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF1CFF4D),
                            )
                          : GreenButton(
                              label: "Sign up",
                              onPressed: _handleRegister,
                              horzSize: 100,
                              vertSize: 30,
                            ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13),
                            children: [
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const TextSpan(
                                text: "Log In",
                                style: TextStyle(
                                  color: Color(0xFF1CFF4D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
