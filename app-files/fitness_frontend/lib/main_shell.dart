import 'package:flutter/material.dart';
import 'package:fitness/custom_widgets.dart';
import 'package:fitness/followed_page.dart';
import 'package:fitness/home_page.dart';
import 'package:fitness/chat_page.dart';
import 'package:fitness/profile_page.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  // ignore: non_constant_identifier_names
  final String user_name;
  // ignore: non_constant_identifier_names
  const MainShell({super.key, this.initialIndex = 0, required this.user_name});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  List<Widget> get _pages => [
    const HomePage(),
    FollowedPage(isActive: _currentIndex == 1),
    const ChatPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HomeHeader(userName: widget.user_name),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07120C), Color(0xFF050D09)],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(9.0),
                  child: SlidingBottomNav(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
