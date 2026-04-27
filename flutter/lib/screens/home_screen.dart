import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'teoria_screen.dart';
import 'tuner_screen.dart';
import 'scores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final _screens = const [
    TeoriaScreen(),
    TunerScreen(),
    ScoresScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_tabIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note, color: AppColors.black),
            label: 'Teoria',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: AppColors.black),
            label: 'Afinador',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music, color: AppColors.black),
            label: 'Cifras',
          ),
        ],
      ),
    );
  }
}
