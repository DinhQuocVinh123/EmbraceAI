import 'package:flutter/material.dart';

import 'editor_screen.dart';
import 'insights_screen.dart';
import 'journal_screen.dart';

/// Khung chính: hai tab Nhật ký / Thống kê, nút thêm nổi ở tab Nhật ký.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack để tab Thống kê giữ nguyên vị trí cuộn khi quay lại.
      body: IndexedStack(
        index: _index,
        children: const [JournalScreen(), InsightsScreen()],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => EditorScreen.open(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ghi lại'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Nhật ký',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }
}
