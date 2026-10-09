import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/countries.dart';
import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';
import '../widgets/choice_tile.dart';
import '../widgets/step_actions.dart';

/// Phụ lục A, mỗi màn hình một câu hỏi.
///
/// Một câu mỗi màn giúp người ít quen công nghệ tập trung vào đúng một việc,
/// bấm trúng dễ hơn trên điện thoại và thấy rõ còn bao nhiêu câu. Mỗi lần
/// sang câu mới, câu trả lời được lưu nháp; trang cuối cho xem lại và sửa
/// trước khi gửi. Nội dung câu hỏi giữ nguyên như bản đã duyệt.
class DemographicsScreen extends StatefulWidget {
  const DemographicsScreen({
    super.key,
    required this.service,
    required this.onSubmitted,
    required this.onSignOut,
  });

  final StudyAssessmentService service;
  final Future<void> Function() onSubmitted;
  final Future<void> Function() onSignOut;

  @override
  State<DemographicsScreen> createState() => _DemographicsScreenState();
}

enum _Question {
  age('Age in years'),
  gender('Gender'),
  ethnicity('Ethnic background'),
  country('Country of birth'),
  relationship('Relationship status'),
  diagnosis('Cardiovascular diagnosis'),
  comorbidities('Other health conditions / comorbidities');

  const _Question(this.title);
  final String title;

  bool get isHealth => this == diagnosis || this == comorbidities;
}

class _DemographicsScreenState extends State<DemographicsScreen> {
  static const _genders = {
    'female': 'Female',
    'male': 'Male',
    'prefer_not_to_say': 'Prefer not to say',
  };
  static const _ethnicities = {
    'asian': 'Asian',
    'indigenous': 'Indigenous',
    'latin_american': 'Latin American',
    'middle_eastern': 'Middle Eastern',
    'white': 'White',
    'mixed_multiple': 'Mixed / multiple backgrounds',
    'other': 'Other',
    'prefer_not_to_say': 'Prefer not to say',
  };
  static const _relationships = {
    'single': 'Single, including separated, divorced, or widowed',
    'partnered': 'In a relationship / partnered, including married',
    'prefer_not_to_say': 'Prefer not to say',
  };
  static const _questions = _Question.values;

  final _age = TextEditingController();
  final _ethnicOther = TextEditingController();
  final _diagnosis = TextEditingController();
  final _comorbidities = TextEditingController();

  String? _gender;
  String? _ethnicity;
  String? _country;
  String? _relationship;

  /// Câu đang hiện; bằng số câu hỏi nghĩa là trang xem lại.
  int _step = 0;

  /// Đang sửa một câu từ trang xem lại: xong thì quay về trang xem lại.
  bool _fromReview = false;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  /// Các lần lưu nháp chạy nối tiếp nhau; lần gửi chính thức chờ chúng xong
  /// để một bản nháp đến muộn không ghi đè lên bản đã gửi.
  Future<void> _drafts = Future.value();

  bool get _onReview => _step == _questions.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final draft = await widget.service.loadDemographics();
      if (draft != null) {
        _age.text = draft.ageYears?.toString() ?? '';
        _gender = draft.gender;
        _ethnicity = draft.ethnicBackground;
        _ethnicOther.text = draft.ethnicOther ?? '';
        _country = _countryValue(draft.countryOfBirth);
        _relationship = draft.relationshipStatus;
        _diagnosis.text = draft.cardiovascularDiagnosis ?? '';
        _comorbidities.text = draft.comorbidities ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _age.dispose();
    _ethnicOther.dispose();
    _diagnosis.dispose();
    _comorbidities.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastQuestion = _step == _questions.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About you'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_step + 1) / (_questions.length + 1),
                  ),
                  Expanded(
                    child: ListView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      children: _onReview
                          ? _review(context)
                          : _question(context, _questions[_step]),
                    ),
                  ),
                  StepActions(
                    nextLabel: _onReview
                        ? 'Save and continue'
                        : _fromReview || lastQuestion
                        ? 'Review answers'
                        : 'Next',
                    nextIcon: _onReview ? Icons.check : Icons.arrow_forward,
                    onNext: _onReview ? _submit : _next,
                    backLabel: _step == 0 && !_fromReview ? null : 'Back',
                    onBack: _back,
                    busy: _saving,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _question(BuildContext context, _Question question) {
    final theme = Theme.of(context);
    // Dòng tiến độ đứng đầu để luôn nhìn thấy, kể cả ở cỡ chữ lớn khi phần
    // giới thiệu chiếm gần hết màn hình đầu tiên.
    return [
      Text(
        'Question ${question.index + 1} of ${_questions.length}',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      Gap.s,
      if (question == _Question.age) ...[
        const _FormIntro(
          title: 'Participant information',
          body:
              'Please complete this once before beginning the program. Your record uses only your study-issued Participant ID.',
        ),
        Gap.l,
      ],
      Text(
        question.isHealth ? 'Health information' : 'Personal information',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      Gap.s,
      Semantics(
        header: true,
        child: Text(question.title, style: theme.textTheme.titleLarge),
      ),
      Gap.m,
      ..._field(context, question),
    ];
  }

  List<Widget> _field(BuildContext context, _Question question) =>
      switch (question) {
        _Question.age => [
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _next(),
            onChanged: (_) => _clearError(),
            decoration: InputDecoration(
              labelText: 'Age in years',
              prefixIcon: const Icon(Icons.cake_outlined),
              errorText: _error,
            ),
          ),
        ],
        _Question.gender => _choices(
          _genders,
          _gender,
          (value) => _gender = value,
        ),
        _Question.ethnicity => [
          ..._choices(
            _ethnicities,
            _ethnicity,
            (value) => _ethnicity = value,
            showError: _ethnicity != 'other',
          ),
          if (_ethnicity == 'other') ...[
            Gap.s,
            TextField(
              controller: _ethnicOther,
              maxLength: 200,
              onChanged: (_) => _clearError(),
              decoration: InputDecoration(
                labelText: 'Please specify',
                errorText: _error,
              ),
            ),
          ],
        ],
        _Question.country => [
          _CountryField(
            value: _country,
            error: _error,
            onChanged: (value) => setState(() {
              _country = value;
              _error = null;
            }),
          ),
        ],
        _Question.relationship => _choices(
          _relationships,
          _relationship,
          (value) => _relationship = value,
        ),
        _Question.diagnosis => [
          TextField(
            controller: _diagnosis,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _clearError(),
            decoration: InputDecoration(errorText: _error),
          ),
        ],
        _Question.comorbidities => [
          TextField(
            controller: _comorbidities,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Optional'),
          ),
          Text(
            'This question is optional.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      };

  List<Widget> _choices(
    Map<String, String> options,
    String? selected,
    ValueChanged<String> onSelect, {
    bool showError = true,
  }) {
    final theme = Theme.of(context);
    return [
      for (final option in options.entries) ...[
        ChoiceTile(
          label: option.value,
          selected: selected == option.key,
          onTap: () => setState(() {
            onSelect(option.key);
            _error = null;
          }),
        ),
        Gap.s,
      ],
      if (showError && _error != null)
        Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
    ];
  }

  List<Widget> _review(BuildContext context) => [
    const _FormIntro(
      title: 'Check your answers',
      body: 'You can change any answer before saving.',
    ),
    Gap.l,
    for (final question in _questions) ...[
      _ReviewRow(
        label: question.title,
        value: _display(question),
        onChange: () => setState(() {
          _error = null;
          _fromReview = true;
          _step = question.index;
        }),
      ),
      const Divider(height: 24),
    ],
  ];

  String _display(_Question question) {
    String text(String value) => value.trim().isEmpty ? 'Not answered' : value;
    return switch (question) {
      _Question.age => text(_age.text),
      _Question.gender => _genders[_gender] ?? 'Not answered',
      _Question.ethnicity =>
        _ethnicity == 'other'
            ? 'Other: ${_ethnicOther.text.trim()}'
            : _ethnicities[_ethnicity] ?? 'Not answered',
      _Question.country => _country ?? 'Not answered',
      _Question.relationship => _relationships[_relationship] ?? 'Not answered',
      _Question.diagnosis => text(_diagnosis.text),
      _Question.comorbidities => text(_comorbidities.text),
    };
  }

  String? _validate(_Question question) => switch (question) {
    _Question.age => switch (int.tryParse(_age.text)) {
      null => 'Enter age in years.',
      final age when age < 0 || age > 120 => 'Enter a valid age.',
      _ => null,
    },
    _Question.gender => _gender == null ? 'Select an option.' : null,
    _Question.ethnicity =>
      _ethnicity == null
          ? 'Select an option.'
          : _ethnicity == 'other' && _ethnicOther.text.trim().isEmpty
          ? 'Please describe your background.'
          : null,
    _Question.country => _country == null ? 'Select a country.' : null,
    _Question.relationship =>
      _relationship == null ? 'Select an option.' : null,
    _Question.diagnosis =>
      _diagnosis.text.trim().isEmpty ? 'This answer is required.' : null,
    _Question.comorbidities => null,
  };

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _next() {
    final error = _validate(_questions[_step]);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _saveDraft();
    setState(() {
      _error = null;
      _step = _fromReview ? _questions.length : _step + 1;
      if (_onReview) _fromReview = false;
    });
  }

  void _back() => setState(() {
    _error = null;
    if (_fromReview) {
      _fromReview = false;
      _step = _questions.length;
    } else {
      _step--;
    }
  });

  DemographicAnswers _answers() => DemographicAnswers(
    ageYears: int.tryParse(_age.text),
    gender: _gender,
    ethnicBackground: _ethnicity,
    ethnicOther: _ethnicity == 'other' ? _ethnicOther.text.trim() : null,
    countryOfBirth: _country,
    relationshipStatus: _relationship,
    cardiovascularDiagnosis: _diagnosis.text.trim(),
    comorbidities: _comorbidities.text.trim(),
  );

  void _saveDraft() {
    final answers = _answers();
    _drafts = _drafts
        .then((_) => widget.service.saveDemographics(answers, submit: false))
        .catchError((Object _) {});
  }

  Future<void> _submit() async {
    // Bản nháp cũ có thể thiếu câu: đưa người dùng về đúng câu cần sửa.
    for (final question in _questions) {
      final error = _validate(question);
      if (error != null) {
        setState(() {
          _step = question.index;
          _fromReview = true;
          _error = error;
        });
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await _drafts;
      await widget.service.saveDemographics(_answers(), submit: true);
      await widget.onSubmitted();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your information could not be saved. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _countryValue(String? value) {
    final country = value?.trim();
    if (country == null || country.isEmpty) return null;
    for (final option in countries) {
      if (option.toLowerCase() == country.toLowerCase()) return option;
    }
    return country;
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String? value;
  final String? error;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <DropdownMenuEntry<String>>[
      if (value != null && !countries.contains(value))
        DropdownMenuEntry(value: value!, label: value!),
      for (final country in countries)
        DropdownMenuEntry(value: country, label: country),
    ];
    return DropdownMenu<String>(
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 360,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      label: const Text('Country of birth'),
      hintText: 'Search or select a country',
      leadingIcon: const Icon(Icons.public),
      trailingIcon: const Icon(Icons.arrow_drop_down),
      selectedTrailingIcon: const Icon(Icons.arrow_drop_up),
      errorText: error,
      dropdownMenuEntries: entries,
      onSelected: onChanged,
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onChange,
  });

  final String label;
  final String value;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap.xs,
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        Gap.s,
        TextButton(
          onPressed: onChange,
          child: Text('Change', semanticsLabel: 'Change $label'),
        ),
      ],
    );
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap.s,
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
