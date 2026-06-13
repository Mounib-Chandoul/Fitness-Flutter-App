import 'package:fitness/custom_widgets.dart';
import 'package:fitness/choosing_page.dart';
import 'package:fitness/login_page.dart';
import 'package:flutter/material.dart';

class DiscoverSecPage extends StatefulWidget {
  const DiscoverSecPage({super.key});

  @override
  State<DiscoverSecPage> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<DiscoverSecPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/me.jpg'),
              repeat: ImageRepeat.repeat,
              scale: 1.0,

              colorFilter: ColorFilter.mode(
                const Color.fromARGB(193, 20, 20, 20).withValues(alpha: 0.8),
                BlendMode.darken,
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 100),
              Container(
                color: const Color.fromARGB(0, 0, 0, 0),
                child: Transform(
                  transform: Matrix4.rotationZ(0.0),
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                    width: 200,
                    height: 200,
                  ),
                ),
              ),

              Text(
                "DISCOVER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Elevate your performance",
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
              SizedBox(height: 50),
              SizedBox(
                height: 80,
                width: 420,
                child: LabelBoxes(
                  icon: Icons.person_search,
                  text: "Find workout coaches",
                  secondaryText: "Connect with experts worldwide",
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 80,
                width: 420,
                child: LabelBoxes(
                  icon: Icons.fitness_center,
                  text: "Pro training plans",
                  secondaryText: "Curated by world-class coaches",
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 80,
                width: 420,
                child: LabelBoxes(
                  icon: Icons.analytics_outlined,
                  text: "Real-time Analytics",
                  secondaryText: "Track every heartbeat & rep",
                ),
              ),
              SizedBox(height: 50),
              GreenButton(
                label: "Go to sign up",
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChoosingPage(),
                    ),
                  ),
                },
                horzSize: 100,
                vertSize: 30,
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
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
                        TextSpan(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
