import 'dart:convert';
import 'l10n/strings.dart';
import 'domain/dietary.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domain/policy.dart';

void main() => runApp(IngredientApp());

class IngredientApp extends StatelessWidget {
  const IngredientApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Navilo',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Color(0xFF276653),
          scaffoldBackgroundColor: Color(0xFFF7F8F4),
        ),
        home: HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final label = TextEditingController();
  late final Future<Policy> policy =
      rootBundle.loadString('assets/policy.json').then(Policy.decode);
  bool english = false;
  String tr(String text) => english ? (translations[text] ?? text) : text;
  late final Future<Map<String, dynamic>> dietary = rootBundle
      .loadString('assets/dietary.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  int page = 0;
  String category = 'food';
  String skin = 'Henüz seçilmedi';
  final Set<String> preferences = {};
  List<IngredientRule>? matches;
  bool complete = false;
  bool reading = false;
  String? photoPath;
  String? scanError;

  Future<void> scanPhoto(ImageSource source) async {
    if (reading) {
      return;
    }
    setState(() {
      reading = true;
      scanError = null;
    });
    TextRecognizer? recognizer;
    try {
      final photo =
          await ImagePicker().pickImage(source: source, maxWidth: 2400);
      if (photo == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        photoPath = photo.path;
        matches = null;
        complete = false;
        label.clear();
      });
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(photo.path));
      if (!mounted) {
        return;
      }
      final heading = RegExp(
              r'(?:içindekiler|içerik(?:ler)?|ingredients)\s*[:：]?',
              caseSensitive: false)
          .firstMatch(result.text);
      var text =
          heading == null ? result.text : result.text.substring(heading.end);
      final end = RegExp(
              r'\n\s*(?:besin değer|nutrition|saklama|uyarı|kullanım|üretici|üretim|son tüketim)',
              caseSensitive: false)
          .firstMatch(text);
      if (end != null) {
        text = text.substring(0, end.start);
      }
      text = text.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
      setState(() {
        label.text = text;
        scanError = text.isEmpty
            ? 'Yazı okunamadı. İçindekiler bölümünü yakından ve net çek.'
            : null;
      });
    } on PlatformException catch (_) {
      if (mounted) {
        setState(() => scanError =
            'Fotoğrafa erişilemedi veya yazı okunamadı. Kamera/galeri iznini kontrol edip tekrar dene.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => scanError =
            'Fotoğraf işlenemedi. Başka bir fotoğrafla tekrar dene.');
      }
    } finally {
      await recognizer?.close();
      if (mounted) setState(() => reading = false);
    }
  }

  Widget dietaryPanel({bool reference = false}) =>
      FutureBuilder<Map<String, dynamic>>(
        future: dietary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(english
                ? 'Reference data unavailable.'
                : 'Kaynak verisi yüklenemedi.');
          }
          if (!snapshot.hasData) return LinearProgressIndicator();
          final json = snapshot.requireData;
          final entries = (json['entries'] as List)
              .map((e) => DietaryEntry(e as Map<String, dynamic>))
              .where((e) => reference || e.matches(label.text))
              .toList();
          final sources = json['sources'] as Map<String, dynamic>;
          return Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            english
                                ? 'Gluten & FODMAP references'
                                : 'Gluten ve FODMAP kaynakları',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(english
                            ? 'Small reference list. A match is a review flag, not a product classification. No match does not establish gluten-free or low FODMAP status.'
                            : 'Başlangıç referans listesi. Eşleşme kontrol uyarısıdır; ürün sınıflandırması değildir. Eşleşme olmaması glutensiz veya düşük FODMAP anlamına gelmez.'),
                        if (entries.isEmpty)
                          Text(english
                              ? 'No reference ingredient detected; status unknown.'
                              : 'Referans içerik tespit edilmedi; durum bilinmiyor.'),
                        ...entries.map((e) => ExpansionTile(
                                title: Text(e.name(english)),
                                subtitle: Text(e.kind == 'fodmap_potential'
                                    ? (english
                                        ? 'Potential FODMAP source — serving data required'
                                        : 'Olası FODMAP kaynağı — porsiyon verisi gerekli')
                                    : (english
                                        ? 'Cereal/allergen reference — check claims and processing'
                                        : 'Tahıl/alerjen referansı — beyan ve işlem kontrolü gerekli')),
                                children: [
                                  SelectableText(e.aliases.join(', ')),
                                  Text(sources[e.source]['title'] as String),
                                  SelectableText(
                                      sources[e.source]['url'] as String),
                                ])),
                        Text(english
                            ? 'Sources reviewed: 2026-10-10. FSA: OGL v3.0. FODMAP seed: independently authored facts from ACG; no Monash database imported.'
                            : 'Kaynak kontrolü: 10.10.2026. FSA: OGL v3.0. FODMAP: ACG kaynaklı bağımsız olgu özeti; Monash veritabanı aktarılmadı.'),
                      ])));
        },
      );

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  Widget section(String title, String subtitle, List<Widget> children) =>
      ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 12),
          Text(subtitle),
          SizedBox(height: 24),
          ...children,
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('Navilo · Prototip')), actions: [
          TextButton(
              onPressed: () => setState(() => english = !english),
              child: Text(english ? 'TR' : 'EN'))
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) => setState(() => page = value),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              label: 'Değerlendir',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Profilim'),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              label: 'Kriterler',
            ),
          ],
        ),
        body: FutureBuilder<Policy>(
          future: policy,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(tr('Kriterler yüklenemedi.')));
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final data = snapshot.requireData;
            if (page == 1) {
              return section(
                tr('Seçimlerin sana ait'),
                tr('Bu oturumdaki tercihler cihazda kalıcı kaydedilmez. Cilt anketi sonraki adımda eklenecek.'),
                [
                  DropdownButtonFormField<String>(
                    initialValue: skin,
                    decoration: InputDecoration(
                      labelText: tr('Beyan ettiğin cilt tipi'),
                    ),
                    items: [
                      'Henüz seçilmedi',
                      'Kuru',
                      'Yağlı',
                      'Karma',
                      'Normal'
                    ]
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(tr(v))))
                        .toList(),
                    onChanged: (v) => setState(() => skin = v!),
                  ),
                  SizedBox(height: 24),
                  Text(
                    tr('Beslenme tercihleri · Henüz ürün filtresine bağlı değil'),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Vegan',
                      'Glutensiz',
                      'Laktozsuz',
                      'Şekersiz',
                      'İlave şekersiz',
                      'Rafine şekersiz',
                      'Az yağlı',
                      'Ketojenik',
                      'Düşük FODMAP',
                    ]
                        .map(
                          (v) => FilterChip(
                            label: Text(tr(v)),
                            selected: preferences.contains(v),
                            onSelected: (selected) => setState(
                              () => selected
                                  ? preferences.add(v)
                                  : preferences.remove(v),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 24),
                  Text(
                    tr('Planlanan ilgi alanları: IBS, PCOS, kalp sağlığı, menopoz ve regl döngüsü. Bu prototip sağlık önerisi üretmez.'),
                  ),
                ],
              );
            }
            if (page == 2) {
              return section(
                tr('Açık içerik politikası'),
                english
                    ? 'Version ${data.version} · Draft dictionary; incomplete and pending expert review.'
                    : 'Sürüm ${data.version} · Taslak sözlük; kapsam tam değildir ve uzman incelemesi bekler.',
                [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        tr('Margarin, hidrojenize yağ ve trans yağ ayrı kurallardır. Kurşun, kadmiyum ve arsenik etiket üzerinden dışlanamaz.'),
                      ),
                    ),
                  ),
                  dietaryPanel(reference: true),
                  ...data.rules.map(
                    (r) => ExpansionTile(
                      title: Text(english ? r.englishName : r.name),
                      subtitle: Text(
                        r.category == 'food'
                            ? tr('Gıda · Eleme kriteri')
                            : tr('Kozmetik · Eleme kriteri'),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(r.aliases.join(', ')),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return section(
              tr('Etiketten başlayalım'),
              tr('İçindekiler etiketini çek veya galeriden ekle. Yazılar cihazda otomatik okunur. Doktor tavsiyesi değildir.'),
              [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'food', label: Text(tr('Gıda'))),
                    ButtonSegment(
                      value: 'cosmetic',
                      label: Text(tr('Kozmetik / bakım')),
                    ),
                  ],
                  selected: {category},
                  onSelectionChanged: (v) => setState(() {
                    category = v.first;
                    matches = null;
                  }),
                ),
                SizedBox(height: 20),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  FilledButton.icon(
                      onPressed:
                          reading ? null : () => scanPhoto(ImageSource.camera),
                      icon: Icon(Icons.camera_alt_outlined),
                      label: Text(tr('Fotoğraf çek'))),
                  OutlinedButton.icon(
                      onPressed:
                          reading ? null : () => scanPhoto(ImageSource.gallery),
                      icon: Icon(Icons.photo_library_outlined),
                      label: Text(tr('Görsel ekle'))),
                ]),
                SizedBox(height: 16),
                if (reading) LinearProgressIndicator(),
                if (scanError != null)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(tr(scanError!),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                if (photoPath != null)
                  Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(photoPath!),
                              height: 180, fit: BoxFit.contain))),
                if (photoPath != null && label.text.isNotEmpty)
                  TextField(
                    controller: label,
                    maxLines: 5,
                    onChanged: (_) => setState(() => matches = null),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText:
                          tr('Fotoğraftan okunan içerik (gerekirse düzelt)'),
                      hintText: tr(
                          'Su, maltitol, palm yağı\nMaddeleri virgül, noktalı virgül veya satırla ayır.'),
                    ),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(
                      'Okunan metnin içindekiler bölümünü tam içerdiğini kontrol ettim')),
                  value: complete,
                  onChanged: (v) => setState(() {
                    complete = v!;
                    matches = null;
                  }),
                ),
                FilledButton.icon(
                  icon: Icon(Icons.search),
                  label: Text(tr('Kriterleri kontrol et')),
                  onPressed: reading || photoPath == null || label.text.isEmpty
                      ? null
                      : () {
                          if (label.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(tr('Önce etiket fotoğrafı ekle.'))),
                            );
                            return;
                          }
                          setState(() =>
                              matches = data.evaluate(label.text, category));
                        },
                ),
                SizedBox(height: 20),
                if (matches != null && category == 'food') dietaryPanel(),
                if (matches != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(matches!.isNotEmpty
                                ? 'İçerik politikamıza uygun değil'
                                : complete
                                    ? 'Listemizdeki madde tespit edilmedi'
                                    : 'Değerlendirme için bilgi eksik'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 12),
                          ...matches!.map(
                            (r) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.flag_outlined),
                              title: Text(english ? r.englishName : r.name),
                              subtitle: Text(
                                tr('Uygulamanın kaçınılan içerikler listesinde.'),
                              ),
                            ),
                          ),
                          Text(
                            tr('Tam ad eşleşmesi kullanılır; bu sonuç güvenlik garantisi değildir. Bilinmeyen yazımlar kaçabilir.'),
                          ),
                          Divider(),
                          Text(
                            tr('FODMAP: Bilgi yetersiz.\nAğır metaller: Test verisi yok; etiketle dışlanamaz.\nBeslenme belirteçleri: Doğrulanmadı.'),
                          ),
                          Text(
                              '${english ? "Policy version" : "Politika sürümü"}: ${data.version}'),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
