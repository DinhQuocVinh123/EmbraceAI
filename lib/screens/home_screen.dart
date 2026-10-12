import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../l10n/l10n.dart';
import '../widgets/language_picker.dart';
import 'editor_screen.dart';
import 'insights_screen.dart';
import 'journal_screen.dart';
import 'welcome_screen.dart';

/// Khung chính: Buổi tập / Nhật ký / Thống kê.
///
/// Buổi tập đứng đầu vì đó là việc người dùng mở app để làm; nhật ký và
/// thống kê là thứ họ xem lại sau.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.participantCode,
    this.onSignOut,
    this.finalAssessmentDue = false,
    this.onOpenFinalAssessment,
  });

  final String? participantCode;
  final Future<void> Function()? onSignOut;
  final bool finalAssessmentDue;
  final VoidCallback? onOpenFinalAssessment;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _journalTab = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: widget.onSignOut == null
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _displayCode(widget.participantCode),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                const LanguageButton(),
                IconButton(
                  tooltip: l10n.homeSignOut,
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
      // IndexedStack để mỗi tab giữ nguyên vị trí cuộn khi quay lại.
      body: Column(
        children: [
          if (widget.finalAssessmentDue)
            _AssessmentBanner(onOpen: widget.onOpenFinalAssessment),
          Expanded(
            child: MotionIndexedStack(
              index: _index,
              children: const [
                WelcomeScreen(),
                JournalScreen(),
                InsightsScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _index == _journalTab
          ? FloatingActionButton.extended(
              onPressed: () => EditorScreen.open(context),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.homeNewEntry),
            )
          : null,
      floatingActionButtonAnimator: AppMotion.isReduced(context)
          ? FloatingActionButtonAnimator.noAnimation
          : null,
      bottomNavigationBar: NavigationBar(
        animationDuration: AppMotion.duration(context, AppMotion.standard),
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.self_improvement_outlined),
            selectedIcon: const Icon(Icons.self_improvement),
            label: l10n.homeTabSession,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.homeTabJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.homeTabInsights,
          ),
        ],
      ),
    );
  }

  static String _displayCode(String? code) {
    if (code == null) return 'EmbraceAI';
    if (code.length == 10 && code.startsWith('EA')) {
      return '${code.substring(0, 2)}-${code.substring(2, 6)}-'
          '${code.substring(6)}';
    }
    return code;
  }
}

class _AssessmentBanner extends StatelessWidget {
  const _AssessmentBanner({required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        top: false,
        child: ListTile(
          leading: Icon(
            Icons.assignment_turned_in_outlined,
            color: scheme.onTertiaryContainer,
          ),
          title: Text(
            context.l10n.homeFinalReady,
            style: TextStyle(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: TextButton(
            onPressed: onOpen,
            child: Text(context.l10n.commonOpen),
          ),
        ),
      ),
    );
  }
}
