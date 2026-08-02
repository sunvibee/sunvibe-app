import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'robots_screen.dart';
import 'reports_screen.dart';
import 'support_screen.dart';

import '../widgets/bottom_nav_bar.dart';
import '../services/mqtt_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    MQTTService.instance.connect();
  }

  @override
  void dispose() {
    MQTTService.instance.disconnect();
    super.dispose();
  }

  final List<Widget> pages = const [
    HomeScreen(),
    RobotsScreen(),
    ReportsScreen(),
    SupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}