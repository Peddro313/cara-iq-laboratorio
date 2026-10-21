import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../services/profile_repository.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _step = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

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
    'Friend',
    'Google',
    'Other',
  ];
  static const _reasons = [
    'See my rating',
    'Get improvement tips',
    'Track progress',
    'Learn about features',
    'Just curious',
  ];
  static const _focusOptions = [
    'Nose',
    'Lips',
    'Jaw / chin',
    'Eyes',
    'Skin',
    'Hairline',
    'Cheekbones',
    'Harmony',
    'Height / posture',
  ];
  static const _freqOptions = [
    'Rarely',
    'Few times / month',
    'Few times / week',
    'Daily',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    await _fadeCtrl.reverse();
    setState(() => _step = step);
    _pageController.jumpToPage(step);
    _fadeCtrl.forward();
  }

  void _next() {
    if (_step < 4) {
      _goTo(_step + 1);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) _goTo(_step - 1);
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return true; // welcome
      case 1:
        return _nameCtrl.text.trim().isNotEmpty &&
            _gender.isNotEmpty &&
            int.tryParse(_ageCtrl.text) != null;
      case 2:
        return _heardFrom.isNotEmpty && _installReason.isNotEmpty;
      case 3:
        return _focusAreas.isNotEmpty;
      case 4:
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
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: List.generate(5, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _step ? AppTheme.primary : AppTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _welcome(),
                    _aboutYou(),
                    _whyHere(),
                    _focus(),
                    _habits(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _back,
                      child: const Text('Back',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _canContinue ? 1 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: FilledButton(
                      onPressed: _canContinue ? _next : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(150, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_step == 0
                          ? 'Get started'
                          : _step == 4
                              ? 'Enter app'
                              : 'Continue'),
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

  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primarySoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to\nCara IQ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'A few quick questions so we can personalize\nyour scores and tips.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _aboutYou() {
    return _ScrollBody(
      title: 'About you',
      subtitle: 'Just the basics.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.text),
            decoration: const InputDecoration(hintText: 'Your name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text('Gender', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _genders.map((g) {
              final selected = _gender == g;
              return _SelectChip(
                label: g,
                selected: selected,
                onTap: () => setState(() => _gender = g),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(hintText: 'Age'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(hintText: 'Height cm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _whyHere() {
    return _ScrollBody(
      title: 'How did you find us?',
      subtitle: 'And what are you here for?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('First heard from', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          ..._heardOptions.map((o) => _OptionTile(
                label: o,
                selected: _heardFrom == o,
                onTap: () => setState(() => _heardFrom = o),
              )),
          const SizedBox(height: 20),
          const Text('Main goal', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          ..._reasons.map((o) => _OptionTile(
                label: o,
                selected: _installReason == o,
                onTap: () => setState(() => _installReason = o),
              )),
        ],
      ),
    );
  }

  Widget _focus() {
    return _ScrollBody(
      title: 'What bothers you most?',
      subtitle: 'Pick as many as you want.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _focusOptions.map((o) {
          final selected = _focusAreas.contains(o);
          return _SelectChip(
            label: o,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _focusAreas.remove(o);
                } else {
                  _focusAreas.add(o);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _habits() {
    return _ScrollBody(
      title: 'Your habits',
      subtitle: 'Skincare and training frequency.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skincare / hygiene', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          ..._freqOptions.map((o) => _OptionTile(
                label: o,
                selected: _skincare == o,
                onTap: () => setState(() => _skincare = o),
              )),
          const SizedBox(height: 20),
          const Text('Posture / jaw / face training',
              style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          ..._freqOptions.map((o) => _OptionTile(
                label: o,
                selected: _exercise == o,
                onTap: () => setState(() => _exercise = o),
              )),
        ],
      ),
    );
  }
}

class _ScrollBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ScrollBody({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: selected ? AppTheme.primarySoft : AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppTheme.primarySoft.withOpacity(0.45) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppTheme.primary : AppTheme.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
