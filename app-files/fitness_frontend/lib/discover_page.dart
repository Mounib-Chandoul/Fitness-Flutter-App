import 'package:flutter/material.dart';
import 'package:fitness/custom_widgets.dart';
import 'package:fitness/login_page.dart';
import 'package:fitness/choosing_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin {
  late final AnimationController _textController;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _descAnimation;
  late final Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _titleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _descAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/backgroundFitness.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                const Color.fromARGB(255, 17, 17, 17).withValues(alpha: 0.8),
                BlendMode.darken,
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 30),
              Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 10,
                      color: Color.fromARGB(0, 255, 193, 7),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 330),
              FadeTransition(
                opacity: _titleAnimation,
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.3,
                  child: Text(
                    "ELEVATE \nYOUR LIMITS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      letterSpacing: 0.1,
                      wordSpacing: 0.1,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'montserrat',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              FadeTransition(
                opacity: _descAnimation,
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.4,
                  child: Text(
                    "Discover workouts made for you\nTrack your progress every single day\nStay consistent and push your limits\nReach your peak with structured plans",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 80),
              ScaleTransition(
                scale: _buttonAnimation,
                child: GreenButton(
                  label: "Get Started",
                  horzSize: 150,
                  vertSize: 28,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChoosingPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              FadeTransition(
                opacity: _buttonAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Already have an account?  ",
                      style: TextStyle(
                        color: Color.fromARGB(179, 216, 216, 216),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: Color.fromARGB(255, 61, 254, 65),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
