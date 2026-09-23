import 'package:flutter/material.dart';

import '../core/motion.dart';
import 'editor_screen.dart';
import 'insights_screen.dart';
import 'journal_screen.dart';
import 'welcome_screen.dart';

/// Khung chính: Buổi tập / Nhật ký / Thống kê.
///
/// Buổi tập đứng đầu vì đó là việc người dùng mở app để làm; nhật ký và
/// thống kê là thứ họ xem lại sau.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _journalTab = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack để mỗi tab giữ nguyên vị trí cuộn khi quay lại.
      body: MotionIndexedStack(
        index: _index,
        children: const [WelcomeScreen(), JournalScreen(), InsightsScreen()],
      ),
      floatingActionButton: _index == _journalTab
          ? FloatingActionButton.extended(
              onPressed: () => EditorScreen.open(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New entry'),
            )
          : null,
      floatingActionButtonAnimator: AppMotion.isReduced(context)
          ? FloatingActionButtonAnimator.noAnimation
          : null,
      bottomNavigationBar: NavigationBar(
        animationDuration: AppMotion.duration(context, AppMotion.standard),
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'Session',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
