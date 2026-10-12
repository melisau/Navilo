import 'package:flutter/material.dart';
import 'skin_type.dart';
import 'skin_test_questions.dart';
import 'skin_test_service.dart';

class SkinTestScreen extends StatefulWidget {
  final bool english;
  final bool persist;
  const SkinTestScreen({super.key, this.english = false, this.persist = true});
  @override
  State<SkinTestScreen> createState() => _SkinTestScreenState();
}

class _SkinTestScreenState extends State<SkinTestScreen> {
  final answers = List<int?>.filled(9, null);
  int index = 0;
  SkinTestResult? result;
  bool saving = false;
  bool allowExit = false;
  String? error;
  String c(String tr, String en) => widget.english ? en : tr;
  Future<void> finish() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (widget.persist) await SkinTestStorage.save(result!);
      if (mounted) {
        setState(() => allowExit = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, result);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = c('Kaydedilemedi. Yeniden deneyebilirsin.',
              'Could not save. Please try again.');
        });
      }
    }
  }

  void back() {
    setState(() {
      if (result != null) {
        result = null;
        index = 8;
      } else {
        index--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final q = skinQuestions[index];
    return PopScope(
      canPop: allowExit || (!saving && index == 0 && r == null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !saving) back();
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(c('Cilt tipini keşfet', 'Explore your skin type')),
            leading: IconButton(
                tooltip: c('Geri', 'Back'),
                icon: const Icon(Icons.arrow_back),
                onPressed: saving
                    ? null
                    : () {
                        if (index == 0 && r == null) {
                          Navigator.pop(context);
                        } else {
                          back();
                        }
                      })),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(c('Yanıtlarına dayalı öz değerlendirme; teşhis değildir.',
              'A self-assessment based on your answers, not a diagnosis.')),
          const SizedBox(height: 24),
          if (r == null) ...[
            Text('${index + 1} / 9',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (index + 1) / 9),
            const SizedBox(height: 24),
            Text(widget.english ? englishQuestions[index].$1 : q.text,
                style: Theme.of(context).textTheme.headlineSmall),
            if (q.hint != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(widget.english
                      ? (index == 8
                          ? 'Sensitivity is separate from skin type.'
                          : 'Think about how your skin usually feels after washing.')
                      : q.hint!)),
            const SizedBox(height: 20),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(18),
                          backgroundColor: answers[index] == i
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null),
                      onPressed: () => setState(() => answers[index] = i),
                      child: Text(widget.english
                          ? englishQuestions[index].$2[i]
                          : q.options[i].text))),
            FilledButton(
                onPressed: answers[index] == null
                    ? null
                    : () => setState(() {
                          if (index == 8) {
                            result = SkinTestEngine.evaluate(answers);
                          } else {
                            index++;
                          }
                        }),
                child: Text(index == 8
                    ? c('Sonucu gör', 'See result')
                    : c('Devam', 'Continue'))),
          ] else ...[
            const Icon(Icons.face_outlined, size: 52),
            const SizedBox(height: 16),
            Text(
                '${c('Cilt eğilimin', 'Your skin tendency')}: ${widget.english ? r.type.name : r.type.label}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(widget.english
                ? 'Your answers suggest this skin tendency. Skin can change with seasons and products.'
                : 'Yanıtların ${r.type.label.toLowerCase()} cilt eğilimine işaret ediyor. Cildin mevsime ve kullandığın ürünlere göre değişebilir.'),
            const SizedBox(height: 20),
            for (final t in SkinType.values) ...[
              Text('${widget.english ? t.name : t.label}: ${r.scores[t]} / 24'),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(value: r.scores[t]! / 24)),
            ],
            Text(c('Puanlar olasılık veya tıbbi ölçüm değildir.',
                'Scores are not probabilities or medical measurements.')),
            const SizedBox(height: 16),
            Text(r.isSensitive
                ? c('Hassasiyet notu: sık kızarıklık / yanma bildirdin. Parfümlü ürünlerde dikkatli ol.',
                    'Sensitivity note: you reported frequent redness / burning. Take care with fragranced products.')
                : c('Sık hassasiyet bildirmedin; bu, alerji olmadığı anlamına gelmez.',
                    'You did not report frequent sensitivity; this does not rule out allergy.')),
            const SizedBox(height: 16),
            for (final tip in widget.english
                ? [
                    'Choose a gentle cleanser and a moisturizer suited to your skin.',
                    'Introduce products one at a time and observe your response.'
                  ]
                : r.type.tips)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $tip')),
            Text(c(
                'Test sonucu yalnızca bu cihazda tutulur; ortak ürün kataloğuna gönderilmez.',
                'Your result stays on this device; it is not sent to the shared product catalog.')),
            if (error != null)
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: saving ? null : finish,
                child: Text(saving
                    ? c('Kaydediliyor…', 'Saving…')
                    : c('Kaydet ve tamamla', 'Save and finish'))),
            TextButton(
                onPressed: saving
                    ? null
                    : () => setState(() {
                          index = 0;
                          result = null;
                          answers.fillRange(0, 9, null);
                        }),
                child: Text(c('Testi tekrarla', 'Retake test'))),
          ],
        ])),
      ),
    );
  }
}

const englishQuestions = <(String, List<String>)>[
  (
    'How does your face feel 30–60 minutes after washing without applying a product?',
    [
      'Tight, sometimes itchy',
      'Comfortable, neither tight nor oily',
      'Oily forehead and nose, comfortable or tight cheeks',
      'Oily and shiny all over'
    ]
  ),
  (
    'Where does your face shine at midday?',
    [
      'Almost nowhere, mostly matte',
      'Only slightly',
      'Forehead, nose and chin (T-zone)',
      'Most of my face'
    ]
  ),
  (
    'What do your pores look like?',
    [
      'Visible and large all over',
      'Visible mainly around my nose',
      'Barely visible',
      'Almost invisible; skin looks matte'
    ]
  ),
  (
    'Do you get flaky or dry patches?',
    ['Often', 'Sometimes on my cheeks', 'Very rarely', 'No, mainly oiliness']
  ),
  (
    'How often do you get spots or blackheads?',
    [
      'Often, across my face',
      'Mainly in the T-zone',
      'Rarely',
      'Rarely; dryness is my main concern'
    ]
  ),
  (
    'How does your skin feel after moisturizer?',
    [
      'Quickly feels dry again',
      'Comfortable and balanced',
      'Oily T-zone, comfortable cheeks',
      'Even light creams feel heavy'
    ]
  ),
  (
    'What happens if you press blotting paper on your face at the end of the day?',
    [
      'Almost no mark',
      'A slight mark',
      'Strong marks on forehead and nose',
      'Strong marks everywhere'
    ]
  ),
  (
    'How does your skin change with seasons?',
    [
      'Dry and flaky in winter',
      'Hardly changes',
      'Oily T-zone in summer, dry cheeks in winter',
      'Oily in summer and winter'
    ]
  ),
  (
    'Do new products cause redness, burning or stinging?',
    ['Often', 'Sometimes', 'Rarely or never']
  ),
];
