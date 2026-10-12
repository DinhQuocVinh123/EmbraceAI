import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/countries.dart';
import '../data/countries_vi.dart';
import '../l10n/l10n.dart';
import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';
import '../widgets/choice_tile.dart';
import '../widgets/language_picker.dart';
import '../widgets/step_actions.dart';

/// Phụ lục A, mỗi màn hình một câu hỏi.
///
/// Một câu mỗi màn giúp người ít quen công nghệ tập trung vào đúng một việc,
/// bấm trúng dễ hơn trên điện thoại và thấy rõ còn bao nhiêu câu. Mỗi lần
/// sang câu mới, câu trả lời được lưu nháp; trang cuối cho xem lại và sửa
/// trước khi gửi. Nội dung câu hỏi giữ nguyên như bản đã duyệt; bản tiếng Việt
/// là bản dịch nháp chờ nhóm nghiên cứu duyệt. Câu trả lời lưu bằng mã (hoặc
/// tên quốc gia tiếng Anh), không phụ thuộc ngôn ngữ đang dùng.
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
  age,
  gender,
  ethnicity,
  country,
  relationship,
  diagnosis,
  comorbidities;

  String title(AppLocalizations l) => switch (this) {
    age => l.demoQuestionAge,
    gender => l.demoQuestionGender,
    ethnicity => l.demoQuestionEthnicity,
    country => l.demoQuestionCountry,
    relationship => l.demoQuestionRelationship,
    diagnosis => l.demoQuestionDiagnosis,
    comorbidities => l.demoQuestionComorbidities,
  };

  bool get isHealth => this == diagnosis || this == comorbidities;
}

class _DemographicsScreenState extends State<DemographicsScreen> {
  // Khoá là mã lưu xuống, giá trị là chữ hiện ra.
  static Map<String, String> _genders(AppLocalizations l) => {
    'female': l.genderFemale,
    'male': l.genderMale,
    'prefer_not_to_say': l.optionPreferNotToSay,
  };
  static Map<String, String> _ethnicities(AppLocalizations l) => {
    'asian': l.ethnicityAsian,
    'indigenous': l.ethnicityIndigenous,
    'latin_american': l.ethnicityLatinAmerican,
    'middle_eastern': l.ethnicityMiddleEastern,
    'white': l.ethnicityWhite,
    'mixed_multiple': l.ethnicityMixed,
    'other': l.ethnicityOther,
    'prefer_not_to_say': l.optionPreferNotToSay,
  };
  static Map<String, String> _relationships(AppLocalizations l) => {
    'single': l.relationshipSingle,
    'partnered': l.relationshipPartnered,
    'prefer_not_to_say': l.optionPreferNotToSay,
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.demoAppBar),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: l10n.homeSignOut,
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
                        ? l10n.questionSave
                        : _fromReview || lastQuestion
                        ? l10n.demoReviewAnswers
                        : l10n.commonNext,
                    nextIcon: _onReview ? Icons.check : Icons.arrow_forward,
                    onNext: _onReview ? _submit : _next,
                    backLabel: _step == 0 && !_fromReview
                        ? null
                        : l10n.commonBack,
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
    final l10n = context.l10n;
    // Dòng tiến độ đứng đầu để luôn nhìn thấy, kể cả ở cỡ chữ lớn khi phần
    // giới thiệu chiếm gần hết màn hình đầu tiên.
    return [
      Text(
        l10n.demoQuestionOf(question.index + 1, _questions.length),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      Gap.s,
      if (question == _Question.age) ...[
        _FormIntro(title: l10n.demoIntroTitle, body: l10n.demoIntroBody),
        Gap.l,
      ],
      Text(
        question.isHealth ? l10n.demoHealthInfo : l10n.demoPersonalInfo,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      Gap.s,
      Semantics(
        header: true,
        child: Text(question.title(l10n), style: theme.textTheme.titleLarge),
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
              labelText: context.l10n.demoQuestionAge,
              prefixIcon: const Icon(Icons.cake_outlined),
              errorText: _error,
            ),
          ),
        ],
        _Question.gender => _choices(
          _genders(context.l10n),
          _gender,
          (value) => _gender = value,
        ),
        _Question.ethnicity => [
          ..._choices(
            _ethnicities(context.l10n),
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
                labelText: context.l10n.demoPleaseSpecify,
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
          _relationships(context.l10n),
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
            decoration: InputDecoration(hintText: context.l10n.demoOptional),
          ),
          Text(
            context.l10n.demoOptionalNote,
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
    _FormIntro(
      title: context.l10n.demoCheckTitle,
      body: context.l10n.demoCheckBody,
    ),
    Gap.l,
    for (final question in _questions) ...[
      _ReviewRow(
        label: question.title(context.l10n),
        value: _display(context.l10n, question),
        onChange: () => setState(() {
          _error = null;
          _fromReview = true;
          _step = question.index;
        }),
      ),
      const Divider(height: 24),
    ],
  ];

  String _display(AppLocalizations l, _Question question) {
    final none = l.demoNotAnswered;
    String text(String value) => value.trim().isEmpty ? none : value;
    return switch (question) {
      _Question.age => text(_age.text),
      _Question.gender => _genders(l)[_gender] ?? none,
      _Question.ethnicity =>
        _ethnicity == 'other'
            ? l.demoOtherValue(_ethnicOther.text.trim())
            : _ethnicities(l)[_ethnicity] ?? none,
      _Question.country => switch (_country) {
        final country? => countryName(country, l.localeName),
        null => none,
      },
      _Question.relationship => _relationships(l)[_relationship] ?? none,
      _Question.diagnosis => text(_diagnosis.text),
      _Question.comorbidities => text(_comorbidities.text),
    };
  }

  String? _validate(AppLocalizations l, _Question question) =>
      switch (question) {
        _Question.age => switch (int.tryParse(_age.text)) {
          null => l.demoEnterAge,
          final age when age < 0 || age > 120 => l.demoValidAge,
          _ => null,
        },
        _Question.gender => _gender == null ? l.demoSelectOption : null,
        _Question.ethnicity =>
          _ethnicity == null
              ? l.demoSelectOption
              : _ethnicity == 'other' && _ethnicOther.text.trim().isEmpty
              ? l.demoDescribeBackground
              : null,
        _Question.country => _country == null ? l.demoSelectCountry : null,
        _Question.relationship =>
          _relationship == null ? l.demoSelectOption : null,
        _Question.diagnosis =>
          _diagnosis.text.trim().isEmpty ? l.demoRequired : null,
        _Question.comorbidities => null,
      };

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _next() {
    final error = _validate(context.l10n, _questions[_step]);
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
      final error = _validate(context.l10n, question);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.demoSaveFailed)));
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
    final l10n = context.l10n;
    // Giá trị là tên tiếng Anh (lưu xuống), nhãn theo ngôn ngữ đang dùng; xếp
    // theo nhãn đã bỏ dấu.
    final entries =
        <DropdownMenuEntry<String>>[
          for (final country in countries)
            DropdownMenuEntry(
              value: country,
              label: countryName(country, l10n.localeName),
            ),
        ]..sort(
          (a, b) => foldDiacritics(a.label).compareTo(foldDiacritics(b.label)),
        );
    if (value != null && !countries.contains(value)) {
      entries.insert(0, DropdownMenuEntry(value: value!, label: value!));
    }
    // Tìm theo cả tên đang hiện lẫn tên tiếng Anh, không phân biệt dấu.
    bool matches(DropdownMenuEntry<String> entry, String query) {
      final q = foldDiacritics(query.trim());
      return foldDiacritics(entry.label).contains(q) ||
          foldDiacritics(entry.value).contains(q);
    }

    return DropdownMenu<String>(
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 360,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      filterCallback: (entries, filter) =>
          entries.where((entry) => matches(entry, filter)).toList(),
      searchCallback: (entries, query) {
        if (query.trim().isEmpty) return null;
        final index = entries.indexWhere((entry) => matches(entry, query));
        return index < 0 ? null : index;
      },
      label: Text(l10n.demoQuestionCountry),
      hintText: l10n.demoCountryHint,
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
          child: Text(
            context.l10n.editorChange,
            semanticsLabel: context.l10n.changeSemantics(label),
          ),
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
