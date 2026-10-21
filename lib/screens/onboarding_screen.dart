import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../services/profile_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _nameCtrl = TextEditingController();
  String _gender = '';
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _heardFrom = '';
  String _installReason = '';
  final Set<String> _focusAreas = {};
  String _skincare = '';
  String _exercise = '';

  static const _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  static const _heardOptions = [
    'TikTok / Reels',
    'Instagram',
    'YouTube',
    'Friend / word of mouth',
    'Search / Google',
    'Other',
  ];
  static const _reasons = [
    'See my facial rating / score',
    'Get tips to improve',
    'Track progress over time',
    'Compare features / learn',
    'Curiosity',
  ];
  static const _focusOptions = [
    'Nose',
    'Lips',
    'Jaw / chin',
    'Eyes',
    'Skin',
    'Hairline / forehead',
    'Cheekbones',
    'Overall harmony',
    'Height / posture',
  ];
  static const _freqOptions = [
    'Rarely or never',
    'A few times a month',
    'A few times a week',
    'Daily',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty &&
            _gender.isNotEmpty &&
            int.tryParse(_ageCtrl.text) != null;
      case 1:
        return _heardFrom.isNotEmpty && _installReason.isNotEmpty;
      case 2:
        return _focusAreas.isNotEmpty;
      case 3:
        return _skincare.isNotEmpty && _exercise.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      gender: _gender,
      age: int.tryParse(_ageCtrl.text) ?? 18,
      heightCm: double.tryParse(_heightCtrl.text),
      heardFrom: _heardFrom,
      installReason: _installReason,
      focusAreas: _focusAreas.toList(),
      skincareFrequency: _skincare,
      exerciseFrequency: _exercise,
      onboardingDone: true,
    );
    await ProfileRepository().save(profile);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepBasics(),
                  _stepWhy(),
                  _stepFocus(),
                  _stepHabits(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _back,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canContinue ? _next : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_step == 3 ? 'Finish' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBasics() {
    return _StepScaffold(
      title: 'About you',
      subtitle: 'This helps personalize your analysis and tips.',
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Gender', style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genders.map((g) {
              final selected = _gender == g;
              return ChoiceChip(
                label: Text(g),
                selected: selected,
                onSelected: (_) => setState(() => _gender = g),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepWhy() {
    return _StepScaffold(
      title: 'How did you find us?',
      subtitle: 'And what brought you here?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where did you first hear about this app?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._heardOptions.map((o) => RadioListTile<String>(
                title: Text(o),
                value: o,
                groupValue: _heardFrom,
                onChanged: (v) => setState(() => _heardFrom = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
          const SizedBox(height: 12),
          Text('Why did you install it?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._reasons.map((o) => RadioListTile<String>(
                title: Text(o),
                value: o,
                groupValue: _installReason,
                onChanged: (v) => setState(() => _installReason = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        ],
      ),
    );
  }

  Widget _stepFocus() {
    return _StepScaffold(
      title: 'What do you want to work on?',
      subtitle: 'Select everything that matters to you.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _focusOptions.map((o) {
          final selected = _focusAreas.contains(o);
          return FilterChip(
            label: Text(o),
            selected: selected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _focusAreas.add(o);
                } else {
                  _focusAreas.remove(o);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _stepHabits() {
    return _StepScaffold(
      title: 'Your habits',
      subtitle: 'Skincare, hygiene, and face-related exercise.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How often do you follow a skincare / hygiene routine?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._freqOptions.map((o) => RadioListTile<String>(
                title: Text(o),
                value: o,
                groupValue: _skincare,
                onChanged: (v) => setState(() => _skincare = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
          const SizedBox(height: 12),
          Text('How often do you train posture, jaw, or facial muscles?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._freqOptions.map((o) => RadioListTile<String>(
                title: Text(o),
                value: o,
                groupValue: _exercise,
                onChanged: (v) => setState(() => _exercise = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
