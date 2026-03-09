import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/option_tile.dart';

class _Question {
  final String domain;
  final String text;
  const _Question(this.domain, this.text);
}

// Full question bank — each domain has more questions than we ever show.
// Every session randomly draws _pickCounts[domain] questions from each pool,
// so the test feels fresh every time while keeping balanced DSM-5 coverage.
const Map<String, List<String>> _questionBank = {
  'Intrusive Symptoms': [
    'I have unwanted, distressing memories or mental images of stressful events.',
    'I experience distressing dreams or nightmares related to stressful situations.',
    'Flashbacks or vivid recollections of stressful events suddenly intrude on my day.',
    'I find myself mentally replaying upsetting events even when I don\'t want to.',
    'Certain sights, sounds, or smells unexpectedly trigger stressful memories.',
    'I feel strong emotional or physical distress when reminded of past stressors.',
  ],
  'Negative Mood & Cognition': [
    'I feel persistent negative emotions such as fear, horror, anger, guilt, or shame.',
    'I have difficulty concentrating or making decisions because of stress.',
    'I feel detached or estranged from people around me.',
    'I am unable to experience positive emotions like happiness, satisfaction, or love.',
    'I tend to blame myself for things that have gone wrong in my life.',
    'I feel like nothing good will happen to me in the future.',
    'I find it hard to remember important details of stressful events.',
  ],
  'Dissociative Symptoms': [
    'I feel emotionally numb or cut off from my own thoughts and feelings.',
    'The world around me feels unreal, dreamlike, or distorted.',
    'I lose track of time and find myself in situations I don\'t remember getting into.',
    'I feel like I\'m watching myself from outside my own body.',
    'My sense of who I am feels unstable or unclear when I\'m under stress.',
  ],
  'Avoidance': [
    'I avoid thoughts, feelings, or internal reminders associated with stressful events.',
    'I avoid people, places, or situations that remind me of stress.',
    'I stay away from news, conversations, or media that could remind me of stressors.',
    'I keep myself constantly busy so I don\'t have to think about what\'s bothering me.',
    'I find it difficult to open up about stress, even with people I trust.',
  ],
  'Arousal & Reactivity': [
    'I have trouble falling or staying asleep due to stress.',
    'I feel unusually irritable or experience sudden angry outbursts.',
    'I am constantly on alert, watching for potential danger (hypervigilance).',
    'I am easily startled by unexpected noises or sudden movements.',
    'I engage in reckless or self-destructive behaviour when I\'m stressed.',
    'I feel physically tense or wound up most of the time.',
    'I have difficulty relaxing, even when I\'m objectively safe.',
  ],
  'Functional Impairment': [
    'Stress has significantly affected my work, school, or daily responsibilities.',
    'Stress has interfered with my personal relationships or social activities.',
    'I experience physical symptoms of stress such as headaches, muscle tension, or fatigue.',
    'I feel overwhelmed and unable to cope with everyday demands.',
    'Overall, stress is having a significant negative impact on my quality of life.',
    'I have been withdrawing from hobbies or activities I used to enjoy.',
    'I feel like stress is controlling my life rather than me controlling it.',
    'I have been neglecting basic self-care (eating, exercise, sleep) because of stress.',
  ],
};

// How many questions to draw from each domain per session (total = 20, max score = 80)
const Map<String, int> _pickCounts = {
  'Intrusive Symptoms': 3,
  'Negative Mood & Cognition': 4,
  'Dissociative Symptoms': 2,
  'Avoidance': 2,
  'Arousal & Reactivity': 4,
  'Functional Impairment': 5,
};

List<_Question> _generateQuestions() {
  final rng = Random();
  final result = <_Question>[];
  _questionBank.forEach((domain, pool) {
    final count = _pickCounts[domain] ?? pool.length;
    final shuffled = List<String>.from(pool)..shuffle(rng);
    for (int i = 0; i < count && i < shuffled.length; i++) {
      result.add(_Question(domain, shuffled[i]));
    }
  });
  return result;
}

const List<String> _optionLabels = [
  'Never',
  'Rarely',
  'Sometimes',
  'Often',
  'Always',
];

// Maps total score (0–80) to a DSM-5 aligned diagnosis
class _DiagnosisResult {
  final String level;
  final String dsm5Label;
  final String description;
  final String recommendation;
  final Color color;
  final IconData icon;

  const _DiagnosisResult({
    required this.level,
    required this.dsm5Label,
    required this.description,
    required this.recommendation,
    required this.color,
    required this.icon,
  });
}

_DiagnosisResult _diagnose(int score) {
  if (score <= 15) {
    return const _DiagnosisResult(
      level: 'Minimal / No Stress',
      dsm5Label: 'No Clinically Significant Stress Disorder',
      description:
          'Your responses indicate minimal stress with no significant impairment to daily functioning. '
          'This is within the normal range of human experience.',
      recommendation:
          'Continue healthy lifestyle habits: regular exercise, balanced nutrition, adequate sleep, '
          'and social connection. Periodic self-check-ins are encouraged.',
      color: Color(0xFF2E7D32),
      icon: Icons.sentiment_very_satisfied_rounded,
    );
  } else if (score <= 30) {
    return const _DiagnosisResult(
      level: 'Mild Stress',
      dsm5Label: 'Subclinical Stress / Possible Adjustment Difficulties',
      description:
          'Your responses suggest mild stress that may be causing some discomfort but has limited '
          'impact on your overall functioning. This often corresponds to normal life stressors '
          'or early-stage adjustment difficulties (DSM-5 Z-codes context).',
      recommendation:
          'Practice stress-management techniques such as mindfulness, deep breathing, or journaling. '
          'Ensure you maintain work-life balance. Consider speaking with a counsellor if symptoms persist.',
      color: Color(0xFF558B2F),
      icon: Icons.sentiment_satisfied_rounded,
    );
  } else if (score <= 50) {
    return const _DiagnosisResult(
      level: 'Moderate Stress',
      dsm5Label:
          'Possible Adjustment Disorder (DSM-5 309.xx) or Acute Stress Response',
      description:
          'Your score indicates moderate stress that is noticeably affecting multiple areas of daily life. '
          'This level is consistent with features of Adjustment Disorder (DSM-5 309.xx), '
          'characterised by emotional or behavioural symptoms in response to an identifiable stressor, '
          'with clinically significant distress or functional impairment.',
      recommendation:
          'A consultation with a licensed mental health professional is strongly recommended. '
          'Cognitive-behavioural strategies, problem-solving therapy, and social support are effective. '
          'Avoid self-medicating with alcohol or substances.',
      color: Color(0xFFF57F17),
      icon: Icons.sentiment_neutral_rounded,
    );
  } else if (score <= 65) {
    return const _DiagnosisResult(
      level: 'Severe Stress',
      dsm5Label:
          'Likely Acute Stress Disorder (DSM-5 308.3) or Adjustment Disorder with Anxiety/Mixed Features',
      description:
          'Your responses are indicative of severe stress consistent with Acute Stress Disorder '
          '(DSM-5 308.3) criteria — including intrusive, avoidance, dissociative, and arousal symptoms '
          'causing marked distress or substantial impairment in functioning. '
          'Professional evaluation is essential to rule out an emerging PTSD trajectory.',
      recommendation:
          'Please seek professional mental health support promptly. '
          'Evidence-based treatments include Trauma-Focused CBT (TF-CBT), EMDR, and crisis counselling. '
          'Inform a trusted person about your current state. If you feel unsafe, contact emergency services.',
      color: Color(0xFFE65100),
      icon: Icons.sentiment_dissatisfied_rounded,
    );
  } else {
    return const _DiagnosisResult(
      level: 'Extremely Severe Stress',
      dsm5Label:
          'High Risk – Acute Stress Disorder / PTSD Spectrum (DSM-5 308.3 / 309.81)',
      description:
          'Your score reflects an extremely high level of stress that is severely impairing your '
          'ability to function. This profile is consistent with full criteria for Acute Stress Disorder '
          '(DSM-5 308.3) or early PTSD (DSM-5 309.81), involving significant intrusive, dissociative, '
          'avoidance, and hyperarousal symptoms across multiple domains.',
      recommendation:
          'Immediate professional intervention is needed. Please contact a psychiatrist, clinical '
          'psychologist, or crisis helpline today. If you are in crisis or at risk of harming yourself '
          'or others, go to the nearest emergency department or call emergency services immediately.',
      color: Color(0xFFB71C1C),
      icon: Icons.sentiment_very_dissatisfied_rounded,
    );
  }
}

// The main page — handles question flow and shows results when done
class StressCheckPage extends StatefulWidget {
  const StressCheckPage({super.key});

  @override
  State<StressCheckPage> createState() => _StressCheckPageState();
}

class _StressCheckPageState extends State<StressCheckPage> {
  int _currentIndex = 0;
  late List<_Question> _sessionQuestions;
  late List<int> _answers; // -1 = not yet answered
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _sessionQuestions = _generateQuestions();
    _answers = List.filled(_sessionQuestions.length, -1);
  }

  int get _totalScore =>
      _answers.fold(0, (sum, v) => sum + (v == -1 ? 0 : v));

  bool get _currentAnswered => _answers[_currentIndex] != -1;

  void _goNext() {
    if (_currentIndex < _sessionQuestions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() => _submitted = true);
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _sessionQuestions = _generateQuestions(); // fresh draw every time
      _answers = List.filled(_sessionQuestions.length, -1);
      _submitted = false;
    });
  }

  // Builds the single-question view with progress and nav buttons
  Widget _buildQuestion(BuildContext context) {
    final q = _sessionQuestions[_currentIndex];
    final scheme = Theme.of(context).colorScheme;
    final progress = (_currentIndex + 1) / _sessionQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar with question counter on the right
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_currentIndex + 1} / ${_sessionQuestions.length}',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Shows which DSM-5 domain this question belongs to
        Chip(
          label: Text(q.domain,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer)),
          backgroundColor: scheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(height: 16),

        // The actual question
        Text(
          q.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'In the past month, how often has the following been true for you?',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.outline),
        ),
        const SizedBox(height: 20),

        // 0 = Never … 4 = Always
        ...List.generate(_optionLabels.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: StyledRadioTile(
              value: i,
              groupValue: _answers[_currentIndex],
              title: '${_optionLabels[i]}  ($i)',
              onChanged: (v) => setState(() => _answers[_currentIndex] = v!),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Prev / Next (or Submit on the last question)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentIndex > 0)
              OutlinedButton.icon(
                onPressed: _goPrev,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              const SizedBox(),

            ElevatedButton.icon(
              onPressed: _currentAnswered ? _goNext : null,
              icon: Icon(_currentIndex == _sessionQuestions.length - 1
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded),
              label: Text(_currentIndex == _sessionQuestions.length - 1
                  ? 'See Results'
                  : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                disabledBackgroundColor: scheme.surfaceContainerHighest,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Nudge if the user tries to move on without picking an option
        if (!_currentAnswered)
          Center(
            child: Text(
              'Please select an option to continue.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }

  // Results screen — shows diagnosis, explanation, and domain breakdown
  Widget _buildResults(BuildContext context) {
    final result = _diagnose(_totalScore);
    final scheme = Theme.of(context).colorScheme;

    // Tally scores per domain for the breakdown bars
    final domainScores = <String, int>{};
    final domainCounts = <String, int>{};
    for (int i = 0; i < _sessionQuestions.length; i++) {
      final d = _sessionQuestions[i].domain;
      domainScores[d] = (domainScores[d] ?? 0) + (_answers[i] == -1 ? 0 : _answers[i]);
      domainCounts[d] = (domainCounts[d] ?? 0) + 1;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Big summary card at the top
          Container(
            decoration: BoxDecoration(
              color: result.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: result.color.withOpacity(0.4), width: 1.5),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(result.icon, size: 64, color: result.color),
                const SizedBox(height: 12),
                Text(
                  result.level,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: result.color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: result.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Total Score: $_totalScore / 80',
                    style: TextStyle(
                        color: result.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Clinical label based on DSM-5
          _ResultSection(
            icon: Icons.local_hospital_rounded,
            title: 'DSM-5 Clinical Impression',
            body: result.dsm5Label,
            color: result.color,
          ),
          const SizedBox(height: 14),

          // Plain-English explanation of what the score means
          _ResultSection(
            icon: Icons.info_outline_rounded,
            title: 'What This Means',
            body: result.description,
            color: result.color,
          ),
          const SizedBox(height: 14),

          // Actionable next steps for the user
          _ResultSection(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Recommended Next Steps',
            body: result.recommendation,
            color: result.color,
          ),
          const SizedBox(height: 20),

          // Per-domain bars so users see where their stress is concentrated
          Text(
            'Score Breakdown by Domain',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...domainScores.entries.map((e) {
            final maxScore = (domainCounts[e.key] ?? 1) * 4;
            final pct = e.value / maxScore;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(e.key,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Text('${e.value} / $maxScore',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          pct < 0.4
                              ? const Color(0xFF2E7D32)
                              : pct < 0.7
                                  ? const Color(0xFFF57F17)
                                  : const Color(0xFFB71C1C)),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Legal/ethical disclaimer — this is a screening tool, not a diagnosis
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: scheme.outline, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This assessment is a self-report screening tool and does NOT constitute a '
                    'clinical diagnosis. It is based on DSM-5 stress-related disorder criteria for '
                    'informational purposes only. Please consult a qualified mental health professional '
                    'for an accurate diagnosis and personalised treatment plan.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.outline, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Let the user start over
          Center(
            child: ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retake Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stress Check',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        elevation: 2,
        centerTitle: true,
        actions: [
          if (!_submitted)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: TextButton(
                  onPressed: _restart,
                  child: const Text('Reset'),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: _submitted
              ? _buildResults(context)
              : _buildQuestion(context),
        ),
      ),
    );
  }
}

// Reusable card for each section on the results screen
class _ResultSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _ResultSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
