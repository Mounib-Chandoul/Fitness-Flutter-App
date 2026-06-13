import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Import your other pages
import 'package:fitness/choosing_page.dart';
import 'package:fitness/custom_widgets.dart';
import 'package:fitness/main_shell.dart';
import 'package:fitness/config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // 1. Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. The Login Logic
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    // 2. Perform Checks
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    if (!emailValid) {
      _showSnackBar("Please enter a valid email address", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // If using Android Emulator, 10.0.2.2 points to your computer's localhost
    final String loginUrl = "${Config.apiBaseUrl}/auth/login";
    try {
      // FastAPI OAuth2 expects x-www-form-urlencoded (Form Data)
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": email, "password": password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String userName = data['name']; // Extract username from response
        // 3. Save session data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        await prefs.setString('user_role', data['role']);
        await prefs.setString('username', data['name']);
        await prefs.setString('email', email);
        if (data.containsKey('id')) {
          await prefs.setInt('user_id', data['id']);
        }
        if (data.containsKey('bio')) {
          await prefs.setString('user_bio', data['bio'] ?? "");
        }
        if (data.containsKey('specialization')) {
          await prefs.setString(
            'user_specialization',
            data['specialization'] ?? "",
          );
        }
        if (data.containsKey('emoji')) {
          await prefs.setString('user_emoji', data['emoji'] ?? "⚡");
        }

        if (!mounted) return;
        _controller.stop();

        // 4. Navigate to Home (initialIndex: 0 for HomePage, not Chat)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainShell(initialIndex: 0, user_name: userName),
          ),
        );
      } else {
        _showSnackBar("Invalid email or password", isError: true);
      }
    } catch (e) {
      _showSnackBar("Cannot reach server. Is FastAPI running?", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
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
                      const SizedBox(height: 50),
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 80),

                      _label("Email"),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _emailController,
                        hint: "Enter your email",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 18),
                      _label("Password"),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _passwordController,
                        hint: "Enter your password",
                        icon: Icons.lock_outline,
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

                      const SizedBox(height: 80),

                      // 5. Button or Loading Spinner
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF1CFF4D),
                            )
                          : GreenButton(
                              label: "Log In",
                              onPressed: _handleLogin,
                              horzSize: 100,
                              vertSize: 30,
                            ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChoosingPage(),
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13),
                            children: [
                              TextSpan(
                                text: "Don’t have an account? ",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const TextSpan(
                                text: "Sign Up",
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

  // --- Helpers ---

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 13,
      ),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
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
