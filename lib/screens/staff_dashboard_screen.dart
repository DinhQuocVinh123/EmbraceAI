import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../models/participant_record.dart';
import '../models/study_assessment.dart';
import '../services/staff_portal_service.dart';
import '../state/auth_store.dart';
import '../widgets/blocking_loading_overlay.dart';

enum _StaffSection { overview, participants }

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  _StaffSection _section = _StaffSection.overview;
  StaffPortalService? _service;
  Stream<List<ParticipantRecord>>? _participantsStream;
  String? _busyMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<StaffPortalService>();
    if (identical(service, _service)) return;
    _service = service;
    _participantsStream = service.watchParticipants();
  }

  @override
  Widget build(BuildContext context) {
    final service = _service!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Stack(
          children: [
            Scaffold(
              appBar: compact
                  ? AppBar(
                      title: const Text('EmbraceAI Study Portal'),
                      actions: [
                        IconButton(
                          tooltip: 'Sign out',
                          onPressed: () => context.read<AuthStore>().signOut(),
                          icon: const Icon(Icons.logout),
                        ),
                      ],
                    )
                  : null,
              bottomNavigationBar: compact
                  ? NavigationBar(
                      selectedIndex: _section.index,
                      onDestinationSelected: (index) => setState(
                        () => _section = _StaffSection.values[index],
                      ),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Overview',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: 'Participants',
                        ),
                      ],
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact)
                    _PortalSidebar(
                      selected: _section,
                      onSelected: (section) =>
                          setState(() => _section = section),
                      onSignOut: () => context.read<AuthStore>().signOut(),
                    ),
                  Expanded(
                    child: StreamBuilder<List<ParticipantRecord>>(
                      stream: _participantsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _PortalError(error: snapshot.error);
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final participants = snapshot.data!;
                        return switch (_section) {
                          _StaffSection.overview => _OverviewView(
                            participants: participants,
                            onCreate: () =>
                                _createParticipant(context, service),
                            onOpen: (record) =>
                                _openParticipant(context, service, record),
                            onViewAll: () => setState(
                              () => _section = _StaffSection.participants,
                            ),
                            onStatusChanged: (record, status) =>
                                _changeStatus(context, service, record, status),
                          ),
                          _StaffSection.participants => _ParticipantsView(
                            participants: participants,
                            onCreate: () =>
                                _createParticipant(context, service),
                            onOpen: (record) =>
                                _openParticipant(context, service, record),
                            onStatusChanged: (record, status) =>
                                _changeStatus(context, service, record, status),
                          ),
                        };
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_busyMessage case final message?)
              BlockingLoadingOverlay(message: message),
          ],
        );
      },
    );
  }

  Future<T> _whileLoading<T>(
    String message,
    Future<T> Function() action,
  ) async {
    setState(() => _busyMessage = message);
    try {
      return await action();
    } finally {
      if (mounted) setState(() => _busyMessage = null);
    }
  }

  Future<void> _createParticipant(
    BuildContext context,
    StaffPortalService service,
  ) async {
    final request = await showDialog<_ParticipantRequest>(
      context: context,
      builder: (_) => const _CreateParticipantDialog(),
    );
    if (request == null || !context.mounted) return;
    try {
      final card = await _whileLoading(
        'Creating participant...',
        () => service.createParticipant(
          studyId: request.studyId,
          group: request.group,
          validForDays: request.validForDays,
        ),
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AccessCardDialog(card: card),
      );
    } on FunctionException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_functionError(error))));
    } on PostgrestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create participant: ${error.message}'),
        ),
      );
    }
  }

  Future<void> _openParticipant(
    BuildContext context,
    StaffPortalService service,
    ParticipantRecord record,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close participant details',
      barrierColor: Colors.black38,
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: _ParticipantDetailPanel(
          record: record,
          sessions: service.watchSessions(record.code),
          studyResponses: service.loadStudyResponses(record.code),
          onClose: () => Navigator.pop(dialogContext),
          onConsentChanged: (status) =>
              service.updateConsent(record.code, status),
          onReissueAccess: () {
            Navigator.pop(dialogContext);
            _reissueAccess(context, service, record);
          },
          onOpenFinalAssessment: () {
            Navigator.pop(dialogContext);
            _openFinalAssessment(context, service, record);
          },
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }

  Future<void> _openFinalAssessment(
    BuildContext context,
    StaffPortalService service,
    ParticipantRecord record,
  ) async {
    try {
      await _whileLoading(
        'Opening final questionnaire...',
        () => service.openFinalAssessment(record.code),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Final questionnaire opened for ${_displayCode(record.code)}.',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open questionnaire: ${error.message}'),
        ),
      );
    }
  }

  Future<void> _reissueAccess(
    BuildContext context,
    StaffPortalService service,
    ParticipantRecord record,
  ) async {
    try {
      final card = await _whileLoading(
        'Generating a new sign-in link...',
        () => service.reissueParticipantAccess(record.code),
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AccessCardDialog(card: card),
      );
    } on FunctionException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_functionError(error))));
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    StaffPortalService service,
    ParticipantRecord record,
    ParticipantStatus status,
  ) async {
    if (status == record.status) return;
    final needsConfirmation =
        status == ParticipantStatus.suspended ||
        status == ParticipantStatus.completed;
    if (needsConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${_label(status.name)} participant?'),
          content: Text(
            status == ParticipantStatus.suspended
                ? 'This participant will no longer be able to sign in until the account is reactivated.'
                : 'Mark this participant as complete? They will no longer be able to sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_label(status.name)),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await _whileLoading(
      'Updating participant status...',
      () => service.updateStatus(record.code, status),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_displayCode(record.code)} is now ${status.name}.'),
      ),
    );
  }
}

class _PortalSidebar extends StatelessWidget {
  const _PortalSidebar({
    required this.selected,
    required this.onSelected,
    required this.onSignOut,
  });

  final _StaffSection selected;
  final ValueChanged<_StaffSection> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 248,
      child: ColoredBox(
        color: scheme.surfaceContainerLowest,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.self_improvement, color: scheme.primary),
                    Gap.s,
                    const Expanded(
                      child: Text(
                        'EmbraceAI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 2),
                  child: Text(
                    'Study Portal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Gap.xl,
                _SidebarDestination(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Overview',
                  selected: selected == _StaffSection.overview,
                  onTap: () => onSelected(_StaffSection.overview),
                ),
                Gap.s,
                _SidebarDestination(
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                  label: 'Participants',
                  selected: selected == _StaffSection.participants,
                  onTap: () => onSelected(_StaffSection.participants),
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: onSignOut,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              Gap.m,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _OverviewView extends StatelessWidget {
  const _OverviewView({
    required this.participants,
    required this.onCreate,
    required this.onOpen,
    required this.onViewAll,
    required this.onStatusChanged,
  });

  final List<ParticipantRecord> participants;
  final VoidCallback onCreate;
  final ValueChanged<ParticipantRecord> onOpen;
  final VoidCallback onViewAll;
  final Future<void> Function(ParticipantRecord, ParticipantStatus)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final active = participants.where((item) => item.isActive).length;
    final sessions = participants.fold<int>(
      0,
      (total, item) => total + item.sessionCount,
    );
    final pendingConsent = participants
        .where((item) => item.consentStatus == ConsentStatus.pending)
        .length;
    final baselinePending = participants
        .where(
          (item) => item.demographicsStatus != FormCompletionStatus.submitted,
        )
        .length;
    final finalDue = participants
        .where(
          (item) =>
              item.finalAssessmentStatus == FinalAssessmentStatus.due ||
              item.finalAssessmentStatus == FinalAssessmentStatus.inProgress,
        )
        .length;
    final recent = participants.take(5).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final metricColumns = textScale > 1.4
            ? 1
            : constraints.maxWidth >= 1050
            ? 4
            : 2;
        final metricHeight = textScale > 1.6
            ? 144.0
            : textScale > 1.2
            ? 116.0
            : 96.0;
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth >= 700 ? 32 : 16,
            vertical: 24,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeader(
                      title: 'Study overview',
                      subtitle:
                          'Participant access, adherence, and consent status',
                      onCreate: onCreate,
                    ),
                    Gap.l,
                    GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: metricColumns,
                        mainAxisExtent: metricHeight,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      itemBuilder: (_, index) => <Widget>[
                        _MetricTile(
                          icon: Icons.people_outline,
                          value: participants.length.toString(),
                          label: 'Participants',
                        ),
                        _MetricTile(
                          icon: Icons.verified_user_outlined,
                          value: active.toString(),
                          label: 'Active accounts',
                          accent: Theme.of(context).colorScheme.primary,
                        ),
                        _MetricTile(
                          icon: Icons.self_improvement,
                          value: sessions.toString(),
                          label: 'Completed sessions',
                        ),
                        _MetricTile(
                          icon: Icons.fact_check_outlined,
                          value: pendingConsent.toString(),
                          label: 'Consent pending',
                          accent: Theme.of(context).colorScheme.tertiary,
                        ),
                        _MetricTile(
                          icon: Icons.badge_outlined,
                          value: baselinePending.toString(),
                          label: 'Baseline pending',
                        ),
                        _MetricTile(
                          icon: Icons.assignment_outlined,
                          value: finalDue.toString(),
                          label: 'Final assessment due',
                          accent: Theme.of(context).colorScheme.tertiary,
                        ),
                      ][index],
                    ),
                    if (pendingConsent > 0) ...[
                      Gap.m,
                      _AttentionBand(
                        count: pendingConsent,
                        onReview: onViewAll,
                      ),
                    ],
                    Gap.xl,
                    _SectionHeader(
                      title: 'Participant activity',
                      subtitle: 'Most recently provisioned study accounts',
                      actionLabel: 'View all',
                      onAction: onViewAll,
                    ),
                    Gap.m,
                    if (participants.isEmpty)
                      _EmptyParticipants(onCreate: onCreate)
                    else if (constraints.maxWidth >= 720)
                      _ParticipantTable(
                        participants: recent,
                        onOpen: onOpen,
                        onStatusChanged: onStatusChanged,
                      )
                    else
                      _ParticipantList(
                        participants: recent,
                        onOpen: onOpen,
                        onStatusChanged: onStatusChanged,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onCreate,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Gap.xs,
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        final action = FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('New participant'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, Gap.m, action],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            action,
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color),
            Gap.m,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionBand extends StatelessWidget {
  const _AttentionBand({required this.count, required this.onReview});

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
            Gap.s,
            Expanded(
              child: Text(
                '$count participant${count == 1 ? '' : 's'} awaiting consent review',
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
            TextButton(onPressed: onReview, child: const Text('Review')),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Gap.xs,
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ParticipantsView extends StatefulWidget {
  const _ParticipantsView({
    required this.participants,
    required this.onCreate,
    required this.onOpen,
    required this.onStatusChanged,
  });

  final List<ParticipantRecord> participants;
  final VoidCallback onCreate;
  final ValueChanged<ParticipantRecord> onOpen;
  final Future<void> Function(ParticipantRecord, ParticipantStatus)
  onStatusChanged;

  @override
  State<_ParticipantsView> createState() => _ParticipantsViewState();
}

class _ParticipantsViewState extends State<_ParticipantsView> {
  final _searchController = TextEditingController();
  ParticipantStatus? _status;
  ConsentStatus? _consent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ParticipantRecord> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return widget.participants
        .where((participant) {
          final matchesQuery =
              query.isEmpty ||
              participant.code.toLowerCase().contains(
                query.replaceAll('-', ''),
              ) ||
              participant.group.toLowerCase().contains(query) ||
              participant.studyId.toLowerCase().contains(query);
          return matchesQuery &&
              (_status == null || participant.status == _status) &&
              (_consent == null || participant.consentStatus == _consent);
        })
        .toList(growable: false);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _status = null;
      _consent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth >= 700 ? 32 : 16,
          vertical: 24,
        ),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    title: 'Participants',
                    subtitle:
                        'Pseudonymous study accounts and session adherence',
                    onCreate: widget.onCreate,
                  ),
                  Gap.l,
                  _ParticipantFilters(
                    controller: _searchController,
                    status: _status,
                    consent: _consent,
                    onSearchChanged: (_) => setState(() {}),
                    onStatusChanged: (value) => setState(() => _status = value),
                    onConsentChanged: (value) =>
                        setState(() => _consent = value),
                    onClear: _clearFilters,
                  ),
                  Gap.m,
                  Text(
                    '${filtered.length} of ${widget.participants.length} participants',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Gap.s,
                  if (filtered.isEmpty)
                    _NoFilterResults(onClear: _clearFilters)
                  else if (constraints.maxWidth >= 720)
                    _ParticipantTable(
                      participants: filtered,
                      onOpen: widget.onOpen,
                      onStatusChanged: widget.onStatusChanged,
                    )
                  else
                    _ParticipantList(
                      participants: filtered,
                      onOpen: widget.onOpen,
                      onStatusChanged: widget.onStatusChanged,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantFilters extends StatelessWidget {
  const _ParticipantFilters({
    required this.controller,
    required this.status,
    required this.consent,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onConsentChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ParticipantStatus? status;
  final ConsentStatus? consent;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ParticipantStatus?> onStatusChanged;
  final ValueChanged<ConsentStatus?> onConsentChanged;
  final VoidCallback onClear;

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    isDense: true,
    filled: false,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: _decoration('Search ID, study, or group', Icons.search),
        );
        final statusField = DropdownButtonFormField<ParticipantStatus?>(
          key: ValueKey(status),
          isExpanded: true,
          initialValue: status,
          decoration: _decoration('Status', Icons.toggle_on_outlined),
          items: [
            const DropdownMenuItem(value: null, child: Text('All statuses')),
            for (final item in ParticipantStatus.values)
              DropdownMenuItem(value: item, child: Text(_label(item.name))),
          ],
          onChanged: onStatusChanged,
        );
        final consentField = DropdownButtonFormField<ConsentStatus?>(
          key: ValueKey(consent),
          isExpanded: true,
          initialValue: consent,
          decoration: _decoration('Consent', Icons.fact_check_outlined),
          items: [
            const DropdownMenuItem(value: null, child: Text('All consent')),
            for (final item in ConsentStatus.values)
              DropdownMenuItem(value: item, child: Text(_label(item.name))),
          ],
          onChanged: onConsentChanged,
        );
        final clear = IconButton(
          tooltip: 'Clear filters',
          onPressed: onClear,
          icon: const Icon(Icons.filter_alt_off_outlined),
        );
        if (constraints.maxWidth < 680) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
          if (largeText) {
            return Column(
              children: [
                search,
                Gap.s,
                statusField,
                Gap.s,
                consentField,
                Align(alignment: Alignment.centerRight, child: clear),
              ],
            );
          }
          return Column(
            children: [
              search,
              Gap.s,
              Row(
                children: [
                  Expanded(child: statusField),
                  Gap.s,
                  Expanded(child: consentField),
                  clear,
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            Gap.s,
            SizedBox(width: 190, child: statusField),
            Gap.s,
            SizedBox(width: 190, child: consentField),
            clear,
          ],
        );
      },
    );
  }
}

class _ParticipantTable extends StatelessWidget {
  const _ParticipantTable({
    required this.participants,
    required this.onOpen,
    required this.onStatusChanged,
  });

  final List<ParticipantRecord> participants;
  final ValueChanged<ParticipantRecord> onOpen;
  final Future<void> Function(ParticipantRecord, ParticipantStatus)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStatePropertyAll(
                  scheme.surfaceContainerLow,
                ),
                headingTextStyle: Theme.of(context).textTheme.labelLarge,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 64,
                horizontalMargin: 16,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Participant ID')),
                  DataColumn(label: Text('Group')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Consent')),
                  DataColumn(label: Text('Sessions'), numeric: true),
                  DataColumn(label: Text('Last activity')),
                  DataColumn(label: Text('Expires')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  for (final participant in participants)
                    DataRow(
                      onSelectChanged: (_) => onOpen(participant),
                      cells: [
                        DataCell(
                          Text(
                            _displayCode(participant.code),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(participant.group)),
                        DataCell(_StatusChip(status: participant.status)),
                        DataCell(
                          _ConsentLabel(status: participant.consentStatus),
                        ),
                        DataCell(Text(participant.sessionCount.toString())),
                        DataCell(Text(_date(participant.lastActivityAt))),
                        DataCell(Text(_date(participant.expiresAt))),
                        DataCell(
                          _StatusMenu(
                            record: participant,
                            onSelected: onStatusChanged,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticipantList extends StatelessWidget {
  const _ParticipantList({
    required this.participants,
    required this.onOpen,
    required this.onStatusChanged,
  });

  final List<ParticipantRecord> participants;
  final ValueChanged<ParticipantRecord> onOpen;
  final Future<void> Function(ParticipantRecord, ParticipantStatus)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            for (var index = 0; index < participants.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                onTap: () => onOpen(participants[index]),
                title: Text(
                  _displayCode(participants[index].code),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${participants[index].studyId}  |  ${participants[index].group}',
                      ),
                      Gap.s,
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(status: participants[index].status),
                          _ConsentLabel(
                            status: participants[index].consentStatus,
                          ),
                          Text('${participants[index].sessionCount} sessions'),
                        ],
                      ),
                      Gap.xs,
                      Text(
                        'Last activity: ${_date(participants[index].lastActivityAt)}',
                      ),
                    ],
                  ),
                ),
                trailing: _StatusMenu(
                  record: participants[index],
                  onSelected: onStatusChanged,
                ),
                isThreeLine: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.record, required this.onSelected});
  final ParticipantRecord record;
  final Future<void> Function(ParticipantRecord, ParticipantStatus) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ParticipantStatus>(
      tooltip: 'Change account status',
      icon: const Icon(Icons.more_vert),
      onSelected: (status) => onSelected(record, status),
      itemBuilder: (_) => [
        for (final status in ParticipantStatus.values)
          PopupMenuItem(
            value: status,
            enabled: status != record.status,
            child: Text(_label(status.name)),
          ),
      ],
    );
  }
}

class _ConsentLabel extends StatelessWidget {
  const _ConsentLabel({required this.status});

  final ConsentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (status) {
      ConsentStatus.accepted => (Icons.check_circle_outline, scheme.primary),
      ConsentStatus.withdrawn => (Icons.block_outlined, scheme.error),
      ConsentStatus.pending => (Icons.schedule_outlined, scheme.tertiary),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        Gap.xs,
        Text(_label(status.name)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ParticipantStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      ParticipantStatus.active => scheme.primary,
      ParticipantStatus.suspended => scheme.error,
      ParticipantStatus.completed => scheme.tertiary,
      ParticipantStatus.invited => scheme.secondary,
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(_label(status.name)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 40),
            Gap.s,
            const Text('No participants match these filters.'),
            Gap.s,
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}

class _CreateParticipantDialog extends StatefulWidget {
  const _CreateParticipantDialog();

  @override
  State<_CreateParticipantDialog> createState() =>
      _CreateParticipantDialogState();
}

class _CreateParticipantDialogState extends State<_CreateParticipantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _studyController = TextEditingController(text: 'CARDIAC-MIND-01');
  String _group = 'Unassigned';
  int _validDays = 90;

  @override
  void dispose() {
    _studyController.dispose();
    super.dispose();
  }

  Widget _dropdownField<T>({
    required String label,
    required IconData leadingIcon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(leadingIcon),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New participant'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _studyController,
                decoration: const InputDecoration(
                  labelText: 'Study ID',
                  prefixIcon: Icon(Icons.science_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a study ID'
                    : null,
              ),
              Gap.m,
              _dropdownField<String>(
                label: 'Study group',
                leadingIcon: Icons.group_outlined,
                value: _group,
                items: const [
                  DropdownMenuItem(
                    value: 'Unassigned',
                    child: Text('Unassigned'),
                  ),
                  DropdownMenuItem(
                    value: 'Intervention',
                    child: Text('Intervention'),
                  ),
                  DropdownMenuItem(value: 'Control', child: Text('Control')),
                ],
                onChanged: (value) =>
                    setState(() => _group = value ?? 'Unassigned'),
              ),
              Gap.m,
              _dropdownField<int>(
                label: 'Invitation validity',
                leadingIcon: Icons.event_outlined,
                value: _validDays,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 90, child: Text('90 days')),
                  DropdownMenuItem(value: 180, child: Text('180 days')),
                ],
                onChanged: (value) => setState(() => _validDays = value ?? 90),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _ParticipantRequest(
                studyId: _studyController.text,
                group: _group,
                validForDays: _validDays,
              ),
            );
          },
          icon: const Icon(Icons.key),
          label: const Text('Generate access'),
        ),
      ],
    );
  }
}

class _AccessCardDialog extends StatelessWidget {
  const _AccessCardDialog({required this.card});
  final ParticipantAccessCard card;

  @override
  Widget build(BuildContext context) {
    final accessKey = card.accessKey;
    final invitation = buildParticipantInvitation(card);
    return AlertDialog(
      icon: const Icon(Icons.verified_user_outlined),
      title: const Text('Participant access created'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ask the participant to scan this QR code with their phone camera. '
              'The sign-in link is single use and should be shared privately.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gap.l,
            Center(
              child: Semantics(
                label: 'One-time participant sign-in QR code',
                image: true,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: card.loginUrl,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Gap.l,
            Text(
              'Participant ID',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Gap.xs,
            SelectableText(
              card.code,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (accessKey != null) ...[
              Gap.m,
              Text(
                'Manual access key',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Gap.xs,
              SelectableText(
                accessKey,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            Gap.m,
            Text(
              'Account access expires ${DateFormat.yMMMd().format(card.expiresAt)}. '
              'A new QR can be issued from the participant record.',
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: invitation));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Participant invitation copied')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy invitation'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

String buildParticipantInvitation(ParticipantAccessCard card) {
  final accessKey = card.accessKey;
  return [
    'Your EMBRACE-AI access is ready.',
    '',
    'Participant ID: ${card.code}',
    if (accessKey != null) 'Manual access key: $accessKey',
    '',
    'To sign in, tap the secure link below:',
    card.loginUrl,
    '',
    'This sign-in link can only be used once. Please do not share it with '
        'anyone else.',
    'If the link has expired or has already been opened, contact the research '
        'team for a new invitation.',
  ].join('\n');
}

class _ParticipantDetailPanel extends StatelessWidget {
  const _ParticipantDetailPanel({
    required this.record,
    required this.sessions,
    required this.studyResponses,
    required this.onClose,
    required this.onConsentChanged,
    required this.onReissueAccess,
    required this.onOpenFinalAssessment,
  });

  final ParticipantRecord record;
  final Stream<List<ParticipantSessionRecord>> sessions;
  final Future<StudyResponseSummary> studyResponses;
  final VoidCallback onClose;
  final ValueChanged<ConsentStatus> onConsentChanged;
  final VoidCallback onReissueAccess;
  final VoidCallback onOpenFinalAssessment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = math.min(560.0, MediaQuery.sizeOf(context).width);
    return Material(
      color: scheme.surface,
      elevation: 12,
      child: SafeArea(
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Participant details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close participant details',
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    Text(
                      _displayCode(record.code),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Gap.s,
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(status: record.status),
                        Text(
                          '${record.studyId}  |  ${record.group}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Gap.l,
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DetailMetric(
                          label: 'Sessions',
                          value: record.sessionCount.toString(),
                        ),
                        _DetailMetric(
                          label: 'Last activity',
                          value: _date(record.lastActivityAt),
                        ),
                        _DetailMetric(
                          label: 'Account expires',
                          value: _date(record.expiresAt),
                        ),
                      ],
                    ),
                    Gap.l,
                    DropdownButtonFormField<ConsentStatus>(
                      initialValue: record.consentStatus,
                      decoration: InputDecoration(
                        labelText: 'Consent status',
                        prefixIcon: const Icon(Icons.fact_check_outlined),
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        for (final status in ConsentStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(_label(status.name)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) onConsentChanged(value);
                      },
                    ),
                    if (record.consentRecordedAt != null) ...[
                      Gap.s,
                      Text(
                        'Recorded ${DateFormat.yMMMd().add_jm().format(record.consentRecordedAt!)}'
                        '${record.consentSource == null ? '' : ' via ${record.consentSource}'}'
                        '${record.consentVersion == null ? '' : ' | ${record.consentVersion}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    Gap.xl,
                    Text(
                      'Study measures',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.s,
                    _MeasureStatusRow(
                      label: 'Appendix A: Demographics',
                      status: _labelFormStatus(record.demographicsStatus),
                      complete:
                          record.demographicsStatus ==
                          FormCompletionStatus.submitted,
                    ),
                    Gap.s,
                    _MeasureStatusRow(
                      label: 'Appendices B-D: Final questionnaire',
                      status: _labelFinalStatus(record.finalAssessmentStatus),
                      complete:
                          record.finalAssessmentStatus ==
                          FinalAssessmentStatus.submitted,
                    ),
                    Gap.m,
                    if (record.finalAssessmentStatus !=
                        FinalAssessmentStatus.submitted)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: record.status == ParticipantStatus.active
                              ? onOpenFinalAssessment
                              : null,
                          icon: const Icon(Icons.assignment_add),
                          label: Text(
                            record.finalAssessmentStatus ==
                                        FinalAssessmentStatus.due ||
                                    record.finalAssessmentStatus ==
                                        FinalAssessmentStatus.inProgress
                                ? 'Keep final questionnaire open'
                                : 'Open final questionnaire',
                          ),
                        ),
                      ),
                    Gap.m,
                    FutureBuilder<StudyResponseSummary>(
                      future: studyResponses,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        return _StudyResponseBlock(summary: snapshot.data!);
                      },
                    ),
                    Gap.xl,
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            record.status == ParticipantStatus.invited ||
                                record.status == ParticipantStatus.active
                            ? onReissueAccess
                            : null,
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Reissue sign-in QR'),
                      ),
                    ),
                    Gap.xl,
                    Text(
                      'Recent sessions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.s,
                    StreamBuilder<List<ParticipantSessionRecord>>(
                      stream: sessions,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        final rows = snapshot.data!;
                        if (rows.isEmpty) return const _NoSessions();
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final session = rows[index];
                            final date = DateFormat.yMMMd().add_jm().format(
                              session.occurredAt,
                            );
                            final mood = session.moodAfter;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.self_improvement),
                              title: Text(date),
                              subtitle: Text(
                                mood != null
                                    ? 'Mood score: $mood/5'
                                    : 'Mood skipped',
                              ),
                            );
                          },
                        );
                      },
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

class _MeasureStatusRow extends StatelessWidget {
  const _MeasureStatusRow({
    required this.label,
    required this.status,
    required this.complete,
  });

  final String label;
  final String status;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_outline : Icons.schedule_outlined,
            color: complete ? scheme.primary : scheme.onSurfaceVariant,
          ),
          Gap.s,
          Expanded(child: Text(label)),
          Gap.s,
          Text(
            status,
            style: TextStyle(
              color: complete ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyResponseBlock extends StatelessWidget {
  const _StudyResponseBlock({required this.summary});

  final StudyResponseSummary summary;

  @override
  Widget build(BuildContext context) {
    final demographics = summary.demographics;
    final assessment = summary.finalAssessment;
    if (demographics == null && assessment == null) {
      return const SizedBox.shrink();
    }
    final premValues =
        assessment?.premResponses.whereType<int>().toList() ?? const <int>[];
    final premAverage = premValues.isEmpty
        ? null
        : premValues.reduce((a, b) => a + b) / premValues.length;
    final openAnswers =
        assessment?.openResponses
            .where((answer) => answer.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text('View collected responses'),
      leading: const Icon(Icons.visibility_outlined),
      children: [
        if (demographics != null) ...[
          _ResponseLine(
            'Age',
            demographics.ageYears?.toString() ?? 'Not answered',
          ),
          _ResponseLine('Gender', _answerLabel(demographics.gender)),
          _ResponseLine(
            'Ethnic background',
            demographics.ethnicBackground == 'other'
                ? demographics.ethnicOther ?? 'Other'
                : _answerLabel(demographics.ethnicBackground),
          ),
          _ResponseLine(
            'Country of birth',
            demographics.countryOfBirth ?? 'Not answered',
          ),
          _ResponseLine(
            'Cardiovascular diagnosis',
            demographics.cardiovascularDiagnosis ?? 'Not answered',
          ),
        ],
        if (assessment != null) ...[
          const Divider(height: 24),
          _ResponseLine(
            'GAD-2',
            assessment.gad2Score == null
                ? 'Incomplete'
                : '${assessment.gad2Score}/6',
          ),
          _ResponseLine(
            'GAD-7',
            assessment.gad7Score == null
                ? 'Incomplete'
                : '${assessment.gad7Score}/21',
          ),
          _ResponseLine(
            'Emotional well-being',
            assessment.emotionalWellbeing == null
                ? 'Not answered'
                : '${assessment.emotionalWellbeing}/5',
          ),
          _ResponseLine(
            'PREM average',
            premAverage == null
                ? 'Not answered'
                : '${premAverage.toStringAsFixed(1)}/5',
          ),
          _ResponseLine(
            'Written responses',
            '${openAnswers.length} of 4 answered',
          ),
          for (var index = 0; index < openAnswers.length; index++)
            _ResponseLine('Feedback ${index + 1}', openAnswers[index]),
        ],
      ],
    );
  }
}

class _ResponseLine extends StatelessWidget {
  const _ResponseLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Gap.s,
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _labelFormStatus(FormCompletionStatus status) => switch (status) {
  FormCompletionStatus.notStarted => 'Not started',
  FormCompletionStatus.draft => 'Draft',
  FormCompletionStatus.submitted => 'Completed',
};

String _labelFinalStatus(FinalAssessmentStatus status) => switch (status) {
  FinalAssessmentStatus.notDue => 'Not due',
  FinalAssessmentStatus.due => 'Due',
  FinalAssessmentStatus.inProgress => 'In progress',
  FinalAssessmentStatus.submitted => 'Completed',
};

String _answerLabel(String? value) {
  if (value == null || value.isEmpty) return 'Not answered';
  return value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Gap.xs,
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSessions extends StatelessWidget {
  const _NoSessions();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 36,
            color: scheme.onSurfaceVariant,
          ),
          Gap.s,
          Text(
            'No completed sessions yet.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyParticipants extends StatelessWidget {
  const _EmptyParticipants({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48),
            Gap.s,
            const Text('No participants have been provisioned.'),
            Gap.m,
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create the first participant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalError extends StatelessWidget {
  const _PortalError({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
            Gap.s,
            const Text('The participant list could not be loaded.'),
            Gap.xs,
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRequest {
  const _ParticipantRequest({
    required this.studyId,
    required this.group,
    required this.validForDays,
  });
  final String studyId;
  final String group;
  final int validForDays;
}

String _date(DateTime? date) =>
    date == null ? 'Not yet' : DateFormat.yMMMd().format(date);

String _label(String value) => '${value[0].toUpperCase()}${value.substring(1)}';

String _displayCode(String code) {
  if (code.length == 10 && code.startsWith('EA')) {
    return '${code.substring(0, 2)}-${code.substring(2, 6)}-'
        '${code.substring(6)}';
  }
  return code;
}

String _functionError(FunctionException error) {
  final details = error.details;
  if (details is Map && details['error'] is String) {
    return 'Could not create participant: ${details['error']}';
  }
  return 'Could not create participant. Please try again.';
}
