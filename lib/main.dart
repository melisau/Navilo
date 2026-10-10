import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'domain/policy.dart';

void main() => runApp(const IngredientApp());

class IngredientApp extends StatelessWidget {
  const IngredientApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Navilo',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF276653),
      scaffoldBackgroundColor: const Color(0xFFF7F8F4)),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final label = TextEditingController();
  late final Future<Policy> policy = rootBundle.loadString('assets/policy.json').then(Policy.decode);
  int page = 0;
  String category = 'food';
  String skin = 'Henüz seçilmedi';
  final Set<String> preferences = {};
  List<IngredientRule>? matches;
  bool complete = false;
  @override
  void dispose() { label.dispose(); super.dispose(); }

  Widget section(String title, String subtitle, List<Widget> children) => ListView(
    padding: const EdgeInsets.all(24), children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12), Text(subtitle), const SizedBox(height: 24), ...children,
    ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Navilo · Prototip')),
    bottomNavigationBar: NavigationBar(selectedIndex: page,
      onDestinationSelected: (value) => setState(() => page = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Değerlendir'),
        NavigationDestination(icon: Icon(Icons.tune), label: 'Profilim'),
        NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Kriterler'),
      ]),
    body: FutureBuilder<Policy>(future: policy, builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Kriterler yüklenemedi.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final data = snapshot.requireData;
      if (page == 1) return section('Seçimlerin sana ait',
        'Bu oturumdaki tercihler cihazda kalıcı kaydedilmez. Cilt anketi sonraki adımda eklenecek.', [
        DropdownButtonFormField<String>(value: skin, decoration: const InputDecoration(labelText: 'Beyan ettiğin cilt tipi'),
          items: ['Henüz seçilmedi', 'Kuru', 'Yağlı', 'Karma', 'Normal'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => skin = v!)),
        const SizedBox(height: 24), const Text('Beslenme tercihleri · Henüz ürün filtresine bağlı değil'),
        Wrap(spacing: 8, children: ['Vegan', 'Glutensiz', 'Laktozsuz', 'Şekersiz', 'İlave şekersiz', 'Rafine şekersiz', 'Az yağlı', 'Ketojenik', 'Düşük FODMAP']
          .map((v) => FilterChip(label: Text(v), selected: preferences.contains(v), onSelected: (selected) => setState(() => selected ? preferences.add(v) : preferences.remove(v)))).toList()),
        const SizedBox(height: 24), const Text('Planlanan ilgi alanları: IBS, PCOS, kalp sağlığı, menopoz ve regl döngüsü. Bu prototip sağlık önerisi üretmez.'),
      ]);
      if (page == 2) return section('Açık içerik politikası',
        'Sürüm ${data.version} · Taslak sözlük. Listeler tam değildir; bilimsel ve mevzuat incelemesi bekler.', [
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Margarin, hidrojenize yağ ve trans yağ ayrı kurallardır. Kurşun, kadmiyum ve arsenik etiket üzerinden dışlanamaz.'))),
        ...data.rules.map((r) => ExpansionTile(title: Text(r.name), subtitle: Text(r.category == 'food' ? 'Gıda · Eleme kriteri' : 'Kozmetik · Eleme kriteri'), children: [Padding(padding: const EdgeInsets.all(16), child: Text(r.aliases.join(', ')))])),
      ]);
      return section('Etiketten başlayalım',
        'Manuel metin prototipi. Kamera, OCR ve gerçek ürün kataloğu henüz bağlı değil. Doktor tavsiyesi değildir.', [
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'food', label: Text('Gıda')), ButtonSegment(value: 'cosmetic', label: Text('Kozmetik / bakım'))],
          selected: {category}, onSelectionChanged: (v) => setState(() { category = v.first; matches = null; })),
        const SizedBox(height: 20),
        TextField(controller: label, maxLines: 5, onChanged: (_) => setState(() => matches = null),
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'İçerik listesi', hintText: 'Su, maltitol, palm yağı\nMaddeleri virgül, noktalı virgül veya satırla ayır.')),
        CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('İçerik listesinin tamamını girdim'), value: complete,
          onChanged: (v) => setState(() { complete = v!; matches = null; })),
        FilledButton.icon(icon: const Icon(Icons.search), label: const Text('Kriterleri kontrol et'),
          onPressed: () { if (label.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce içerik listesini gir.'))); return; }
            setState(() => matches = data.evaluate(label.text, category)); }),
        const SizedBox(height: 20),
        if (matches != null) Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(matches!.isNotEmpty ? 'İçerik politikamıza uygun değil' : complete ? 'Listemizdeki madde tespit edilmedi' : 'Değerlendirme için bilgi eksik', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...matches!.map((r) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag_outlined), title: Text(r.name), subtitle: const Text('Uygulamanın kaçınılan içerikler listesinde.'))),
          const Text('Tam ad eşleşmesi kullanılır; bu sonuç güvenlik garantisi değildir. Bilinmeyen yazımlar kaçabilir.'),
          const Divider(),
          const Text('FODMAP: Bilgi yetersiz.\nAğır metaller: Test verisi yok; etiketle dışlanamaz.\nBeslenme belirteçleri: Doğrulanmadı.'),
          Text('Politika sürümü: ${data.version}'),
        ]))),
      ]);
    }),
  );
}
