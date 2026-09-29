import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/countries.dart';
import '../models/study_assessment.dart';
import '../services/study_assessment_service.dart';

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

class _DemographicsScreenState extends State<DemographicsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _ethnicOther = TextEditingController();
  final _diagnosis = TextEditingController();
  final _comorbidities = TextEditingController();

  String? _gender;
  String? _ethnicity;
  String? _country;
  String? _relationship;
  bool _loading = true;
  bool _saving = false;

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
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    const _FormIntro(
                      title: 'Participant information',
                      body:
                          'Please complete this once before beginning the program. Your record uses only your study-issued Participant ID.',
                    ),
                    Gap.xl,
                    const _SectionTitle('Personal information'),
                    Gap.m,
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Age in years',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null) return 'Enter age in years.';
                        if (age < 0 || age > 120) return 'Enter a valid age.';
                        return null;
                      },
                    ),
                    Gap.m,
                    _SelectField(
                      label: 'Gender',
                      value: _gender,
                      options: const {
                        'female': 'Female',
                        'male': 'Male',
                        'prefer_not_to_say': 'Prefer not to say',
                      },
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    Gap.m,
                    _SelectField(
                      label: 'Ethnic background',
                      value: _ethnicity,
                      options: const {
                        'asian': 'Asian',
                        'indigenous': 'Indigenous',
                        'latin_american': 'Latin American',
                        'middle_eastern': 'Middle Eastern',
                        'white': 'White',
                        'mixed_multiple': 'Mixed / multiple backgrounds',
                        'other': 'Other',
                        'prefer_not_to_say': 'Prefer not to say',
                      },
                      onChanged: (value) => setState(() => _ethnicity = value),
                    ),
                    if (_ethnicity == 'other') ...[
                      Gap.m,
                      TextFormField(
                        controller: _ethnicOther,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Please specify',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Please describe your background.'
                            : null,
                      ),
                    ],
                    Gap.m,
                    _CountryField(
                      value: _country,
                      onChanged: (value) => setState(() => _country = value),
                    ),
                    Gap.m,
                    _SelectField(
                      label: 'Relationship status',
                      value: _relationship,
                      options: const {
                        'single':
                            'Single, including separated, divorced, or widowed',
                        'partnered':
                            'In a relationship / partnered, including married',
                        'prefer_not_to_say': 'Prefer not to say',
                      },
                      onChanged: (value) =>
                          setState(() => _relationship = value),
                    ),
                    Gap.xl,
                    const _SectionTitle('Health information'),
                    Gap.m,
                    TextFormField(
                      controller: _diagnosis,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Cardiovascular diagnosis',
                        alignLabelWithHint: true,
                      ),
                      validator: _required,
                    ),
                    Gap.m,
                    TextFormField(
                      controller: _comorbidities,
                      minLines: 2,
                      maxLines: 6,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Other health conditions / comorbidities',
                        hintText: 'Optional',
                        alignLabelWithHint: true,
                      ),
                    ),
                    Gap.xl,
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Save and continue'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.service.saveDemographics(
        DemographicAnswers(
          ageYears: int.parse(_age.text),
          gender: _gender,
          ethnicBackground: _ethnicity,
          ethnicOther: _ethnicOther.text,
          countryOfBirth: _country,
          relationshipStatus: _relationship,
          cardiovascularDiagnosis: _diagnosis.text,
          comorbidities: _comorbidities.text,
        ),
        submit: true,
      );
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

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This answer is required.' : null;

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
  const _CountryField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <DropdownMenuEntry<String>>[
      if (value != null && !countries.contains(value))
        DropdownMenuEntry(value: value!, label: value!),
      for (final country in countries)
        DropdownMenuEntry(value: country, label: country),
    ];
    return FormField<String>(
      key: ValueKey('country-$value'),
      initialValue: value,
      validator: (selected) => selected == null ? 'Select a country.' : null,
      builder: (field) => DropdownMenu<String>(
        initialSelection: field.value,
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
        errorText: field.errorText,
        dropdownMenuEntries: entries,
        onSelected: (selected) {
          field.didChange(selected);
          onChanged(selected);
        },
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options.entries)
          DropdownMenuItem(value: option.key, child: Text(option.value)),
      ],
      onChanged: onChanged,
      validator: (value) => value == null ? 'Select an option.' : null,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}
