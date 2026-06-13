import 'package:fitness/login_page.dart';
import 'package:flutter/material.dart';
import 'package:fitness/user_state.dart';
import 'package:fitness/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserState.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Check if user is logged in and route accordingly
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<Widget> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _checkLoginStatus();
  }

  Future<Widget> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final username = prefs.getString('username');

      if (token != null && username != null) {
        // User is logged in - show MainShell with FollowedPage (index 1)
        return MainShell(initialIndex: 1, user_name: username);
      } else {
        // User is not logged in - show LoginPage
        return const LoginPage();
      }
    } catch (e) {
      // On error, show LoginPage
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1A12), Color(0xFF08140E)],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF1CFF4D)),
            ),
          );
        }
        if (snapshot.hasError) {
          return const LoginPage();
        }
        return snapshot.data ?? const LoginPage();
      },
    );
  }
}
