import 'widgets/navilo_wordmark.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'data/local_product_store.dart';
import 'data/app_settings.dart';
import 'domain/ingredient_text.dart';
import 'data/product_repository.dart';
import 'dart:convert';
import 'l10n/strings.dart';
import 'domain/dietary.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domain/policy.dart';
import 'data/community_submission.dart';

void main() => runApp(const IngredientApp());

enum ScanStage { start, review, result }

class IngredientApp extends StatelessWidget {
  final Directory? storageDirectory;
  final bool persistSettings;
  final AppSettings? initialSettings;
  final List<LocalProduct>? initialProducts;
  final Policy? initialPolicy;
  const IngredientApp(
      {super.key,
      this.storageDirectory,
      this.persistSettings = true,
      this.initialSettings,
      this.initialProducts,
      this.initialPolicy});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Navilo',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF214D3B),
              surface: const Color(0xFFFFFFFF)),
          scaffoldBackgroundColor: const Color(0xFFFBF8EF),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8),
            titleLarge: TextStyle(
                fontSize: 20,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            bodyMedium:
                TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF53635D)),
          ),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFBF8EF),
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              elevation: 0,
              titleSpacing: 24),
          navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFD9EEE2),
              height: 76,
              labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22))),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD5DFD9)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)))),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD5DFD9)))),
          chipTheme: ChipThemeData(
              backgroundColor: const Color(0xFFF1F5F2),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          dividerTheme:
              const DividerThemeData(color: Color(0xFFE2E9E4), space: 28),
        ),
        home: HomePage(
            storageDirectory: storageDirectory,
            persistSettings: persistSettings,
            initialSettings: initialSettings,
            initialProducts: initialProducts,
            initialPolicy: initialPolicy),
      );
}

class BarcodeScannerPage extends StatefulWidget {
  final bool english;
  const BarcodeScannerPage({super.key, this.english = false});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool handled = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.english ? 'Scan barcode' : 'Barkod okut')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                  widget.english
                      ? 'Place the barcode in the camera view. It will be read automatically.'
                      : 'Barkodu kamera görüntüsüne al. Otomatik olarak okunacak.',
                  style: const TextStyle(fontSize: 17))),
          Expanded(child: MobileScanner(
            onDetect: (capture) {
              if (handled) return;
              final barcode = capture.barcodes
                  .map((item) => item.rawValue)
                  .whereType<String>()
                  .firstWhere((value) => RegExp(r'^\d{8,14}$').hasMatch(value),
                      orElse: () => '');
              if (barcode.isEmpty) return;
              handled = true;
              Navigator.of(context).pop(barcode);
            },
          ))
        ]),
      );
}

class HomePage extends StatefulWidget {
  final Directory? storageDirectory;
  final bool persistSettings;
  final AppSettings? initialSettings;
  final List<LocalProduct>? initialProducts;
  final Policy? initialPolicy;
  const HomePage(
      {super.key,
      this.storageDirectory,
      this.persistSettings = true,
      this.initialSettings,
      this.initialProducts,
      this.initialPolicy});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final label = TextEditingController();
  late final Future<Policy> policy = widget.initialPolicy == null
      ? rootBundle.loadString('assets/policy.json').then(Policy.decode)
      : Future<Policy>.value(widget.initialPolicy!);
  bool english = false;
  String tr(String text) => english ? (translations[text] ?? text) : text;
  String _dietarySubtitle(String kind) {
    if (kind == 'lactose_check') {
      return english
          ? 'Lactose-containing ingredient — check amount and product claim'
          : 'Laktoz içerebilen içerik — miktarı ve ürün beyanını kontrol et';
    }
    if (kind == 'fodmap_potential') {
      return english
          ? 'Potential FODMAP source — serving data required'
          : 'Olası FODMAP kaynağı — porsiyon verisi gerekli';
    }
    if (kind == 'oats_check') {
      return english
          ? 'Check the gluten-free claim and cross-contamination'
          : 'Glutensiz beyanını ve çapraz bulaşma bilgisini kontrol et';
    }
    return english
        ? 'Cereal/allergen reference — check claims and processing'
        : 'Tahıl/alerjen referansı — beyan ve işlem kontrolü gerekli';
  }

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
  bool searchingNameMatches = false;
  bool ingredientSectionDetected = false;
  String? productName;
  ProductRecord? productRecord;
  String? activeBarcode;
  DateTime? localReviewDate;
  late final Future<LocalProductStore> localStore = (widget.storageDirectory ==
              null
          ? getApplicationDocumentsDirectory()
          : Future.value(widget.storageDirectory!))
      .then(
          (dir) => LocalProductStore(Directory('${dir.path}/navilo_products')));

  ScanStage stage = ScanStage.start;
  bool loadingSettings = true;
  bool onboarding = true;
  String? storageError;
  List<LocalProduct> recentProducts = [];
  List<LocalProduct> libraryProducts = [];
  String libraryCategory = 'food';
  String libraryQuery = '';
  String? activeLocalId;
  late final Future<AppSettingsStore> settingsStore =
      localStore.then((store) => AppSettingsStore(store.directory.parent));

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings =
          widget.initialSettings ?? await (await settingsStore).load();
      final recent = widget.initialProducts ??
          (widget.initialSettings == null
              ? await (await localStore).recent(limit: null)
              : <LocalProduct>[]);
      if (!mounted) return;
      setState(() {
        onboarding = !settings.introSeen;
        english = settings.english;
        skin = settings.skin;
        preferences.addAll(settings.preferences);
        libraryProducts = recent;
        recentProducts = recent.take(5).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() => storageError = copy(
            'Yerel kayıtlar yüklenemedi. Tarama yapabilirsin; kayıtlar için uygulamayı yeniden açmayı dene.',
            'Local records could not load. You can still scan; try reopening to access saved records.'));
      }
    } finally {
      if (mounted) setState(() => loadingSettings = false);
    }
  }

  Future<void> persistSettings() async {
    if (!widget.persistSettings) return;
    try {
      await (await settingsStore).save(AppSettings(
          introSeen: !onboarding,
          english: english,
          skin: skin,
          preferences: preferences.toList()));
    } catch (_) {
      if (mounted) {
        setState(() => storageError = copy(
            'Tercihler kaydedilemedi. Bu oturumda kullanabilirsin.',
            'Preferences could not be saved. They remain available in this session.'));
      }
    }
  }

  void finishOnboarding({bool profile = false}) {
    setState(() {
      onboarding = false;
      page = profile ? 1 : 0;
    });
    persistSettings();
  }

  Future<void> refreshRecent() async {
    try {
      final recent = await (await localStore).recent(limit: null);
      if (mounted) {
        setState(() {
          libraryProducts = recent;
          recentProducts = recent.take(5).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => storageError = copy(
            'Kaydedilen ürünler listesi yenilenemedi.',
            'Saved products could not be refreshed.'));
      }
    }
  }

  String dateLabel(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void resetProduct() {
    label.clear();
    activeBarcode = null;
    activeLocalId = null;
    localReviewDate = null;
    productName = null;
    productRecord = null;
    photoPath = null;
    rawOcrText = '';
    scanError = null;
    matches = null;
    complete = false;
    ingredientSectionDetected = false;
    stage = ScanStage.start;
  }

  void goHome() {
    FocusScope.of(context).unfocus();
    setState(() {
      resetProduct();
      page = 0;
    });
  }

  void backStep() {
    FocusScope.of(context).unfocus();
    setState(() =>
        stage = stage == ScanStage.result ? ScanStage.review : ScanStage.start);
  }

  Future<ProductRecord?> chooseNameMatch(List<ProductRecord> candidates) async {
    return showDialog<ProductRecord>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(copy('Bu ürün mü?', 'Is this the product?')),
              content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(copy(
                        'Ürün adıyla eşleşen adaylar bulundu. Barkod farklı olabilir; yanlış ürün riskini azaltmak için adayın adını ve içeriğini ambalajla karşılaştır.',
                        'Products with a similar name were found. The barcode may differ. Compare each candidate and ingredient list with the package before choosing.')),
                    const SizedBox(height: 12),
                    for (final candidate in candidates)
                      Card(
                          child: ListTile(
                              title: Text(candidate.name.isEmpty
                                  ? copy('Ürün adı yok', 'Unnamed product')
                                  : candidate.name),
                              subtitle: Text(
                                  '${copy('Aday barkod', 'Candidate barcode')}: ${candidate.code}\n${candidate.sourceName} · ${candidate.modified == null ? copy('tarih bilinmiyor', 'date unknown') : dateLabel(candidate.modified!)}\n${candidate.ingredients}'),
                              isThreeLine: true,
                              onTap: () =>
                                  Navigator.pop(dialogContext, candidate))),
                  ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(copy('Eşleşme yok', 'None match')))
              ],
            ));
  }

  Future<void> applyNameMatch(ProductRecord candidate) async {
    if (!mounted) return;
    setState(() {
      productRecord = candidate;
      productName = candidate.name;
      label.text = candidate.ingredients;
      complete = false;
      matches = null;
      localReviewDate = null;
      ingredientSectionDetected = true;
      photoPath = null;
      rawOcrText = '';
      scanError = null;
      stage = ScanStage.review;
    });
  }

  Future<void> searchByProductName() async {
    var query = '';
    final confirmedQuery = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(copy('Ürün adıyla ara', 'Search by product name')),
              content: TextField(
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) => query = value.trim(),
                  onSubmitted: (value) =>
                      Navigator.pop(dialogContext, value.trim()),
                  decoration: InputDecoration(
                      labelText:
                          copy('Marka ve ürün adı', 'Brand and product name'))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(copy('Vazgeç', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, query),
                    child: Text(copy('Ara', 'Search')))
              ],
            ));
    if (confirmedQuery == null || confirmedQuery.trim().isEmpty || !mounted) {
      return;
    }
    setState(() {
      reading = true;
      searchingNameMatches = true;
      scanError = copy('Barkodla ürün kaydı bulunamadı.',
          'No product record matched the barcode.');
    });
    try {
      final candidates = await ProductRepository()
          .findNameCandidates(productName: confirmedQuery, english: english);
      if (!mounted) return;
      if (candidates.isEmpty) {
        setState(() => scanError = copy(
            'Bu adla içerik listesi bulunan aday ürün yok. Etiket fotoğrafı ekleyebilirsin.',
            'No candidates with ingredient lists were found. You can add a label photo.'));
      } else {
        final selected = await chooseNameMatch(candidates);
        if (selected != null) await applyNameMatch(selected);
      }
    } catch (_) {
      if (mounted) {
        setState(() => scanError = copy(
            'Ürün adı aranamadı. Bağlantıyı kontrol et veya etiketi fotoğrafla ekle.',
            'Could not search that product name. Check your connection or add a label photo.'));
      }
    } finally {
      if (mounted) {
        setState(() {
          reading = false;
          searchingNameMatches = false;
        });
      }
    }
  }

  void openSaved(LocalProduct product) {
    setState(() {
      resetProduct();
      category = product.category;
      activeBarcode = product.barcode.isEmpty ? null : product.barcode;
      activeLocalId = product.id;
      page = 0;
      productName = product.name.isEmpty ? null : product.name;
      label.text = product.ingredients;
      localReviewDate = product.reviewedAt;
      ingredientSectionDetected = true;
      stage = ScanStage.review;
    });
  }

  Future<void> deleteSavedProduct() async {
    final code = activeLocalId ?? activeBarcode;
    if (code == null) return;
    try {
      await (await localStore).remove(code, category);
      if (!mounted) return;
      setState(() => localReviewDate = null);
      await refreshRecent();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(copy('Kayıt silinemedi. Tekrar dene.',
                'Could not delete the record. Please retry.'))));
      }
    }
  }

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  Future<void> linkBarcode() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(english: english)));
    if (!mounted || code == null || !RegExp(r'^\d{8,14}$').hasMatch(code)) {
      return;
    }
    setState(() {
      activeBarcode = code;
      localReviewDate = null;
      complete = false;
      matches = null;
      stage = ScanStage.review;
    });
  }

  Future<void> saveReviewedProduct() async {
    var code = activeBarcode;
    var share = false;
    var barcodeError = false;
    final text = label.text.trim();
    final savedCategory = category;
    if (!complete || IngredientText.reviewIssues(text).isNotEmpty) return;
    var draftName = productName ?? '';
    var nameError = false;
    XFile? selectedPhoto;
    final confirmedName = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  title: Text(copy('Kütüphaneye kaydet', 'Save to library')),
                  content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(copy(
                            'Ürünün adını yaz. Kontrol ettiğin içerik bu telefonda saklanır.',
                            'Enter the product name. The reviewed ingredients are saved on this phone.')),
                        const SizedBox(height: 18),
                        TextFormField(
                            initialValue: draftName,
                            autofocus: draftName.isEmpty,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 120,
                            onChanged: (value) => draftName = value,
                            decoration: InputDecoration(
                                labelText: copy('Ürün adı', 'Product name'),
                                errorText: nameError
                                    ? copy('Ürün adını yaz.',
                                        'Enter a product name.')
                                    : null)),
                        OutlinedButton.icon(
                            onPressed: () async {
                              final image = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1200,
                                  maxHeight: 1200,
                                  imageQuality: 85);
                              if (ctx.mounted && image != null) {
                                update(() => selectedPhoto = image);
                              }
                            },
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(selectedPhoto == null
                                ? copy('Ürün görseli ekle (isteğe bağlı)',
                                    'Add product photo (optional)')
                                : copy('Görsel seçildi · Değiştir',
                                    'Photo selected · Change'))),
                        TextFormField(
                            initialValue: code ?? '',
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: copy('Barkod (yeniden bulmak için)',
                                    'Barcode (to find again)'),
                                helperText: copy(
                                    'Ambalajdaki 8–14 rakam. Barkodsuz kayıt yalnızca adla bulunur.',
                                    '8–14 package digits. Without a barcode, search by name.'),
                                errorText: barcodeError
                                    ? copy('Geçerli barkod yaz.',
                                        'Enter a valid barcode.')
                                    : null),
                            onChanged: (value) => code =
                                value.trim().isEmpty ? null : value.trim()),
                        if (ProductRepository.catalogConfigured)
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: share,
                              onChanged: (value) =>
                                  update(() => share = value ?? false),
                              title: Text(copy('Ortak kataloğa gönder',
                                  'Submit to shared catalogue')),
                              subtitle: Text(copy(
                                  'Barkod, ürün adı ve içerik metninin paylaşılmasına izin veriyorum. Onaydan sonra herkes bulabilir. Fotoğraf paylaşılmaz.',
                                  'I consent to sharing the barcode, name and ingredient text. Available to everyone after approval. Photos are not shared.'))),
                        const SizedBox(height: 12),
                        Text(copy(
                            'Aynı kaydı yeniden kaydedersen adı ve içeriği güncellenir. Herkese açık paylaşılmaz.',
                            'Saving the same record updates its name and ingredients. It is not shared publicly.')),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(copy('Vazgeç', 'Cancel'))),
                    FilledButton(
                        onPressed: () {
                          if ((code != null &&
                                  !RegExp(r'^\d{8,14}$').hasMatch(code!)) ||
                              (share && code == null)) {
                            update(() => barcodeError = true);
                            return;
                          }
                          if (draftName.trim().isEmpty) {
                            update(() => nameError = true);
                            return;
                          }
                          Navigator.pop(ctx, draftName.trim());
                        },
                        child: Text(copy('Kaydet', 'Save')))
                  ],
                )));
    if (confirmedName == null || !mounted) return;
    final recordId = activeLocalId ??
        code ??
        'local-${DateTime.now().microsecondsSinceEpoch}';
    setState(() => reading = true);
    try {
      final date = DateTime.now();
      final store = await localStore;
      final previous = await store.find(recordId, savedCategory);
      final saved = LocalProduct(
          id: recordId,
          barcode: code ?? '',
          category: savedCategory,
          name: confirmedName,
          ingredients: text,
          reviewedAt: date,
          imageFile: previous?.imageFile,
          remoteImageUrl: previous?.remoteImageUrl ?? productRecord?.imageUrl,
          imageSourceUrl: previous?.imageSourceUrl ??
              (productRecord?.imageUrl == null
                  ? null
                  : productRecord?.sourceUrl));
      await store.save(saved);
      if (selectedPhoto != null) {
        await store.attachImage(saved, File(selectedPhoto!.path));
      }
      if (!mounted) return;
      setState(() {
        localReviewDate = date;
        activeBarcode = code;
        productName = confirmedName;
        activeLocalId = recordId;
      });
      await refreshRecent();
      if (!mounted) return;
      var message = copy('Bu telefona kaydedildi.', 'Saved on this device.');
      if (share) {
        try {
          await CommunitySubmission.submit(saved,
              language: english ? 'en' : 'tr');
          message = copy('Kaydedildi. Ortak katalog için onay bekliyor.',
              'Saved. Awaiting shared catalogue approval.');
        } catch (_) {
          message = copy(
              'Telefona kaydedildi; ortak kataloğa gönderilemedi. Supabase anonim giriş ayarını ve bağlantıyı kontrol et.',
              'Saved locally; submission failed. Check Supabase anonymous sign-in and connection.');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        setState(() => scanError = english
            ? 'Could not save. Please retry.'
            : 'Kayıt yapılamadı. Tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => reading = false);
    }
  }

  Future<void> scanBarcode() async {
    if (reading) return;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => BarcodeScannerPage(english: english)),
    );
    if (barcode == null || barcode.isEmpty || !mounted) return;

    setState(() {
      reading = true;
      activeBarcode = barcode;
      activeLocalId = null;
      localReviewDate = null;
      scanError = null;
      matches = null;
      label.clear();
      productName = null;
      productRecord = null;
      complete = false;
      ingredientSectionDetected = false;
      photoPath = null;
      rawOcrText = '';
    });
    try {
      LocalProduct? saved;
      try {
        final store = await localStore;
        saved = await store.findByBarcode(barcode, category);
        // A saved barcode identifies its category, regardless of the home tab.
        saved ??= await store.findByBarcode(
            barcode, category == 'food' ? 'cosmetic' : 'food');
      } catch (_) {/* A damaged local record must not block online lookup. */}
      if (!mounted) return;
      if (saved != null) {
        final loadedPolicy = await policy;
        if (!mounted) return;
        setState(() {
          category = saved!.category;
          productName = saved.name.isEmpty ? null : saved.name;
          label.text = saved.ingredients;
          localReviewDate = saved.reviewedAt;
          activeLocalId = saved.id;
          complete = false;
          matches = loadedPolicy.evaluate(saved.ingredients, category);
          stage = ScanStage.review;
        });
        return;
      }
      final product = await ProductRepository()
          .find(barcode, english: english, category: category);
      final loadedPolicy = await policy;
      if (!mounted) return;
      setState(() {
        productRecord = product;
        productName = product.name;
        label.text = product.ingredients;
        complete = false;
        ingredientSectionDetected = true;
        matches = loadedPolicy.evaluate(product.ingredients, category);
        stage = ScanStage.review;
      });
    } on ProductLookupException catch (error) {
      if (mounted) {
        setState(() {
          scanError =
              '${english ? "Barcode" : "Barkod"}: $barcode\n${error.attempts.join("\n")}\n${english ? "Take or upload an ingredient label photo." : "İçindekiler fotoğrafı çek veya ekle."}';
          searchingNameMatches = true;
        });
      }
      try {
        final candidates = await ProductRepository()
            .findNameCandidates(barcode: barcode, english: english);
        if (!mounted) return;
        if (candidates.isNotEmpty) {
          final selected = await chooseNameMatch(candidates);
          if (selected != null) await applyNameMatch(selected);
        }
      } catch (_) {
        // Keep the original barcode lookup failure and photo fallback visible.
      } finally {
        if (mounted) setState(() => searchingNameMatches = false);
      }
    } on FormatException {
      if (mounted) {
        setState(() => scanError = english
            ? 'Product or ingredients unavailable. Take a label photo below.'
            : 'Ürün veya içerik bilgisi bulunamadı. Aşağıdan etiket fotoğrafı çek veya ekle.');
      }
    } on SocketException {
      if (mounted) {
        setState(() => scanError =
            'Ürün verisine erişilemedi. İnternet bağlantısını kontrol et.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => scanError = 'Barkod ürünü getirilemedi. Tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => reading = false);
    }
  }

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
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 3200,
        maxHeight: 5000,
        imageQuality: 100,
      );
      if (photo == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      final cropped = await ImageCropper().cropImage(
        sourcePath: photo.path,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: english
                  ? 'Select full ingredient list'
                  : 'İçindekilerin tamamını seç',
              lockAspectRatio: false),
          IOSUiSettings(
              title: english
                  ? 'Select full ingredient list'
                  : 'İçindekilerin tamamını seç'),
        ],
      );
      if (!mounted || cropped == null) return;
      setState(() {
        photoPath = cropped.path;
        localReviewDate = null;
        rawOcrText = '';
        productName = null;
        productRecord = null;
        ingredientSectionDetected = false;
        matches = null;
        complete = false;
        label.clear();
        stage = ScanStage.review;
      });
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result =
          await recognizer.processImage(InputImage.fromFilePath(cropped.path));
      if (!mounted) {
        return;
      }

      final text = _extractIngredientText(result.text);
      final correctedText = text;
      final loadedPolicy = await policy;
      if (!mounted) return;

      setState(() {
        stage = ScanStage.review;
        label.text = correctedText;
        matches = correctedText.isEmpty
            ? null
            : loadedPolicy.evaluate(correctedText, category);
        complete =
            false; // A heading does not prove that the entire list is visible.
        scanError = correctedText.isEmpty
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

  String rawOcrText = '';
  String _extractIngredientText(String text) {
    final parsed = IngredientText.parse(text);
    rawOcrText = parsed.raw;
    ingredientSectionDetected = parsed.headingFound;
    return parsed.ingredients;
  }

  Widget resultRow(String title, String status, List<String> names,
          {bool warning = false, Color? accent}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: accent != null
                ? accent.withValues(alpha: 0.06)
                : warning
                    ? const Color(0xFFFFF5E7)
                    : Colors.white,
            border: Border.all(
                color: accent ??
                    (warning
                        ? const Color(0xFFB86A13)
                        : const Color(0xFFD3DED9)),
                width: accent == null ? 1 : 2.5),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: accent ?? const Color(0xFF607269),
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(status, style: Theme.of(context).textTheme.titleLarge),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 4,
                children: names.map((name) => Chip(label: Text(name))).toList())
          ],
        ]),
      );

  void showFodmapPortionDetails({required bool simpleRice}) {
    showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (ctx) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(
                            copy('FODMAP ve porsiyon',
                                'FODMAP and serving size'),
                            style: Theme.of(ctx).textTheme.titleLarge)),
                    IconButton(
                        tooltip: copy('Kapat', 'Close'),
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                      copy('Bu ürünün doğrulanmış FODMAP porsiyonu henüz yok.',
                          'A validated FODMAP serving for this product is not available yet.'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                  if (simpleRice) ...[
                    const SizedBox(height: 20),
                    Text(
                        copy('Sade pirinç patlağı için kaynak örneği: 2 adet',
                            'Source example for plain rice cakes: 2 cakes'),
                        style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(copy(
                        'Monash’ın 2022 tarihli açıklamasında 2 adet pirinç patlağı düşük FODMAP örneği olarak veriliyor. Bu, taradığın markanın test edilmiş porsiyonu veya üst tüketim sınırı değildir. Adet büyüklüğü değiştiği için gram karşılığı tahmin edilmez.',
                        'Monash’s 2022 article uses 2 rice cakes as a low-FODMAP example. This is not a tested serving or an upper intake limit for your scanned brand. Cake sizes vary, so no gram conversion is assumed.')),
                  ],
                  const SizedBox(height: 20),
                  Text(
                      copy('Porsiyon büyürse ne olur?',
                          'What happens with a larger serving?'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(copy(
                      'Miktar arttıkça alınan FODMAP miktarı da artabilir; bazı gıdalar daha büyük porsiyonda orta veya yüksek FODMAP düzeyine geçebilir. Aynı öğündeki diğer gıdalar da toplamı etkiler. Bu ürünün kaç gramda yüksek düzeye geçtiği bilinmiyor; otomatik bir eşik hesaplamıyoruz.',
                      'Larger servings can increase FODMAP intake; some foods move to moderate or high levels at larger servings. Other foods in the same meal also affect the total. The high-FODMAP threshold in grams for this product is unknown; no threshold is calculated automatically.')),
                  const SizedBox(height: 20),
                  Text(copy('Ambalaj porsiyonu ile FODMAP porsiyonu farklıdır.',
                      'A package serving is different from a validated FODMAP serving.')),
                  const SizedBox(height: 12),
                  const SelectableText(
                      'Monash University · 2022\nhttps://www.monashfodmap.com/blog/fodmap-stacking-explained/\nhttps://monashfodmap.com/blog/serving-size-and-fodmaps-why-it-so-important/'),
                  const SizedBox(height: 20),
                ])));
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
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final json = snapshot.requireData;
          final entries = (json['entries'] as List)
              .map((e) => DietaryEntry(e as Map<String, dynamic>))
              .where((e) => reference || e.matches(label.text))
              .toList();
          final sources = json['sources'] as Map<String, dynamic>;
          final gluten = entries
              .where((e) => e.kind == 'gluten_cereal' || e.kind == 'oats_check')
              .toList();
          final lactose =
              entries.where((e) => e.kind == 'lactose_check').toList();
          final fodmap = entries
              .where((e) =>
                  e.kind == 'fodmap_potential' || e.kind == 'lactose_check')
              .toList();
          final evidence = normalize('$rawOcrText ${label.text}');
          final glutenClaim = hasGlutenFreeClaim(evidence) ||
              (productRecord?.labels.any((tag) => [
                        'en:gluten-free',
                        'tr:glutensiz',
                        'de:glutenfrei'
                      ].contains(tag)) ??
                  false);
          bool claim(List<String> words, List<String> tags) =>
              words.any((word) => RegExp(r'(?<![a-zçğöşü])' +
                      RegExp.escape(word) +
                      r'(?![a-zçğöşü])')
                  .hasMatch(evidence)) ||
              (productRecord?.labels.any(tags.contains) ?? false);
          final lactoseClaim = claim(
              ['laktozsuz', 'lactose-free', 'lactose free', 'laktosefrei'],
              ['en:lactose-free', 'tr:laktozsuz']);
          final sugarClaim = claim([
            'şekersiz',
            'sekersiz',
            'sugar-free',
            'sugar free',
            'zuckerfrei'
          ], [
            'en:sugar-free',
            'tr:şekersiz'
          ]);
          final sugarAdditions = listedSugarAdditions(label.text);
          final natural = glutenFreeIngredients(label.text, english: english);
          final simpleRice = complete && isSimpleRiceList(label.text);
          final riceGluten = simpleRice && gluten.isEmpty;
          final riceLactose = simpleRice && lactose.isEmpty;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!reference) ...[
                  resultRow(
                      'Gluten',
                      glutenClaim
                          ? (english
                              ? 'Gluten-free · label claim'
                              : 'Glutensiz · etiket beyanı')
                          : riceGluten
                              ? copy('Glutensiz · içeriklere göre',
                                  'Gluten-free · based on ingredients')
                              : gluten.isNotEmpty
                                  ? (english
                                      ? 'Ingredient requires review'
                                      : 'İçerik uyarısı var')
                                  : (english
                                      ? 'No listed gluten source detected'
                                      : 'Listelenen gluten kaynağı tespit edilmedi'),
                      gluten.map((e) => e.name(english)).toList(),
                      warning: gluten.isNotEmpty,
                      accent: glutenClaim || riceGluten
                          ? const Color(0xFF6D4ACB)
                          : null),
                  if (natural.isNotEmpty)
                    resultRow(
                        english
                            ? 'Naturally gluten-free ingredients'
                            : 'Doğal olarak glutensiz içerikler',
                        english ? 'Recognized in the text' : 'Metinde tanındı',
                        natural),
                  resultRow(
                      english ? 'Lactose' : 'Laktoz',
                      lactoseClaim
                          ? (english
                              ? 'Lactose-free · label claim'
                              : 'Laktozsuz · etiket beyanı')
                          : riceLactose
                              ? copy('Laktozsuz · içeriklere göre',
                                  'Lactose-free · based on ingredients')
                              : lactose.isNotEmpty
                                  ? (english
                                      ? 'Possible lactose source'
                                      : 'Olası laktoz kaynağı var')
                                  : (english
                                      ? 'No listed lactose source detected'
                                      : 'Listelenen laktoz kaynağı tespit edilmedi'),
                      lactose.map((e) => e.name(english)).toList(),
                      warning: !lactoseClaim && lactose.isNotEmpty,
                      accent: lactoseClaim || riceLactose
                          ? const Color(0xFF1672B8)
                          : null),
                  resultRow(
                      english ? 'Sugar' : 'Şeker',
                      sugarAdditions.isNotEmpty
                          ? copy('Listelenen şeker ilavesi tespit edildi',
                              'Listed sugar addition detected')
                          : sugarClaim
                              ? copy('Şekersiz · etiket beyanı',
                                  'Sugar-free · label claim')
                              : complete
                                  ? copy(
                                      'Listelenen şeker ilavesi tespit edilmedi',
                                      'No listed sugar addition detected')
                                  : copy('İçerik listesini kontrol et',
                                      'Review the ingredient list'),
                      sugarAdditions,
                      warning: sugarAdditions.isNotEmpty,
                      accent: sugarAdditions.isEmpty && (sugarClaim || complete)
                          ? const Color(0xFFB34572)
                          : null),
                  InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          showFodmapPortionDetails(simpleRice: simpleRice),
                      child: resultRow(
                          'FODMAP ⓘ',
                          simpleRice && fodmap.isEmpty
                              ? copy(
                                  'Düşük FODMAP içerikler · porsiyon gerekli',
                                  'Low-FODMAP ingredients · serving needed')
                              : fodmap.isNotEmpty
                                  ? (english
                                      ? 'FODMAP level undetermined'
                                      : 'FODMAP düzeyi belirlenemedi')
                                  : (english
                                      ? 'Product level unknown'
                                      : 'Ürün düzeyi belirlenemedi'),
                          fodmap.map((e) => e.name(english)).toList(),
                          warning: fodmap.isNotEmpty,
                          accent: simpleRice && fodmap.isEmpty
                              ? const Color(0xFF297A54)
                              : null)),
                  TextButton.icon(
                      onPressed: () =>
                          showFodmapPortionDetails(simpleRice: simpleRice),
                      icon: const Icon(Icons.info_outline),
                      label: Text(copy('Porsiyon miktarı ve ayrıntılar',
                          'Serving size and details'))),
                  if (simpleRice)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(copy(
                            'Pirinç ve tuz tanındı. Gluten/laktoz değerlendirmesi içeriklere dayanır; çapraz bulaşmayı doğrulamaz. Pirinç patlağında FODMAP sonucu tüketilen porsiyona bağlıdır.',
                            'Rice and salt recognized. Gluten/lactose assessment is ingredient-based and does not rule out cross-contact. Rice-cake FODMAP levels depend on the serving eaten.'))),
                ],
                ExpansionTile(
                    title: Text(english
                        ? 'Sources and assessment details'
                        : 'Kaynaklar ve değerlendirme ayrıntıları'),
                    initiallyExpanded: reference,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(english
                              ? 'Results apply to the text read. No match does not establish gluten-free or lactose-free status. Label claims are not independently verified. FODMAP classification requires serving sizes, amounts and validated data; no licensed FODMAP database is connected.'
                              : 'Sonuçlar okunan metne aittir. Eşleşme olmaması ürünün glutensiz veya laktozsuz olduğunu doğrulamaz. Etiket beyanı bağımsız olarak doğrulanmamıştır. FODMAP sınıflandırması için porsiyon, miktar ve doğrulanmış veri gerekir; lisanslı FODMAP veritabanı bağlı değildir.')),
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: SelectableText(
                              'Rice / plain rice cakes: Monash University\nhttps://monashfodmap.com/documents/192/3-step_FODMAP_Diet_2025_A4_info_sheet.pdf\nServing sizes: https://monashfodmap.com/blog/serving-size-and-fodmaps-why-it-so-important/\nNaturally gluten-free rice: https://www.coeliac.org.uk/grains/')),
                      ...entries.map((e) => ExpansionTile(
                              title: Text(e.name(english)),
                              subtitle: Text(_dietarySubtitle(e.kind)),
                              children: [
                                SelectableText(e.aliases.join(', ')),
                                Text(sources[e.source]['title'] as String),
                                SelectableText(
                                    sources[e.source]['url'] as String),
                                Text(
                                    '${english ? "Reviewed" : "Kontrol tarihi"}: ${sources[e.source]['reviewed']}')
                              ])),
                      if (natural.isNotEmpty)
                        const ListTile(
                            title: Text('Coeliac UK · Gluten-free grains'),
                            subtitle: SelectableText(
                                'https://www.coeliac.org.uk/grains/')),
                    ]),
              ]);
        },
      );

  String copy(String turkish, String en) => english ? en : turkish;

  Widget pageList(List<Widget> children, {String? title, String? subtitle}) =>
      Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                key: ValueKey('$page-$stage-$onboarding'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  if (title != null)
                    Text(title,
                        style: Theme.of(context).textTheme.headlineMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(subtitle)
                  ],
                  if (title != null) const SizedBox(height: 24),
                  ...children,
                ],
              )));

  Widget notice(String text, {bool warning = false}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: warning ? const Color(0xFFFFF1DC) : const Color(0xFFE7F0EB),
            borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(warning ? Icons.info_outline : Icons.check_circle_outline,
              color: const Color(0xFF365C4D)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: Color(0xFF243B31), height: 1.5))),
        ]),
      );

  Widget actionCard(
          {required String title,
          required String description,
          required IconData icon,
          required VoidCallback? onTap,
          bool primary = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
            button: true,
            enabled: onTap != null,
            child: Material(
              color: primary ? const Color(0xFF214D3B) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                      color: primary
                          ? const Color(0xFF214D3B)
                          : const Color(0xFFD8E2DC))),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  onTap: onTap,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: primary
                                    ? const Color(0xFF326756)
                                    : const Color(0xFFEDF3EF),
                                borderRadius: BorderRadius.circular(15)),
                            child: Icon(icon,
                                size: 28,
                                color: primary
                                    ? Colors.white
                                    : const Color(0xFF214D3B))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: primary
                                          ? Colors.white
                                          : const Color(0xFF183D30))),
                              const SizedBox(height: 5),
                              Text(description,
                                  style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: primary
                                          ? const Color(0xFFE0EEE7)
                                          : const Color(0xFF53635D))),
                            ])),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right,
                            color: primary
                                ? Colors.white
                                : const Color(0xFF365C4D)),
                      ]))),
            )),
      );

  Widget progressHeader(int step) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(copy('Adım $step / 3', 'Step $step of 3'),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF214D3B))),
        const SizedBox(height: 10),
        Row(
            children: List.generate(
                3,
                (index) => Expanded(
                    child: Container(
                        height: 5,
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        decoration: BoxDecoration(
                            color: index < step
                                ? const Color(0xFF214D3B)
                                : const Color(0xFFDCE5DF),
                            borderRadius: BorderRadius.circular(6)))))),
      ]));

  Widget categoryPicker() => Wrap(spacing: 10, runSpacing: 10, children: [
        for (final item in [
          ('food', copy('Gıda', 'Food'), Icons.restaurant_outlined),
          (
            'cosmetic',
            copy('Bakım ve kozmetik', 'Beauty & care'),
            Icons.spa_outlined
          )
        ])
          ChoiceChip(
              showCheckmark: false,
              selectedColor: const Color(0xFFD9EEE2),
              side: BorderSide(color: const Color(0xFF527565)),
              avatar: Icon(item.$3, size: 20),
              label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(item.$2)),
              selected: category == item.$1,
              onSelected: reading
                  ? null
                  : (_) => setState(() {
                        if (category != item.$1) {
                          resetProduct();
                          category = item.$1;
                        }
                      })),
      ]);

  Widget captureActions({bool retry = false}) => Column(children: [
        if (!retry)
          actionCard(
              title: copy('Barkod okut', 'Scan barcode'),
              description: copy('Ürünün barkodunu kameraya göster.',
                  'Point the camera at the product barcode.'),
              icon: Icons.qr_code_scanner,
              primary: true,
              onTap: reading
                  ? null
                  : () {
                      setState(resetProduct);
                      scanBarcode();
                    }),
        actionCard(
            title: copy('Etiket fotoğrafı çek', 'Take a label photo'),
            description: copy('İçindekilerin tamamını fotoğraflandır.',
                'Capture the entire ingredient list.'),
            icon: Icons.camera_alt_outlined,
            onTap: reading
                ? null
                : () {
                    if (!retry && scanError == null) setState(resetProduct);
                    scanPhoto(ImageSource.camera);
                  }),
        actionCard(
            title: copy('Galeriden görsel ekle', 'Choose from gallery'),
            description: copy('Telefonundaki bir etiket fotoğrafını seç.',
                'Choose an existing label photo.'),
            icon: Icons.photo_library_outlined,
            onTap: reading
                ? null
                : () {
                    if (!retry && scanError == null) setState(resetProduct);
                    scanPhoto(ImageSource.gallery);
                  }),
      ]);

  Widget scanFailure() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (searchingNameMatches)
          const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator()),
        notice(
            copy(
                'Barkodla ürün kaydı bulunamadı. Barkoda bağlı ürün adını da arıyoruz; bulamazsak marka ve ürün adını kendin aratabilirsin.',
                'No product record matched this barcode. We are also checking for its product name; if needed, search by brand and name.'),
            warning: true),
        OutlinedButton.icon(
            onPressed: reading ? null : searchByProductName,
            icon: const Icon(Icons.search),
            label: Text(copy('Ürün adıyla ara', 'Search by product name'))),
        if (activeBarcode != null)
          Text('${copy('Bağlı barkod', 'Linked barcode')}: $activeBarcode'),
        ExpansionTile(
            title: Text(copy('Hata ayrıntıları', 'Error details')),
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(tr(scanError!)))
            ]),
      ]);

  Widget welcomeScreen() => pageList([
        Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
                color: const Color(0xFFE3EEE6),
                borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.document_scanner_outlined,
                size: 70, color: Color(0xFF214D3B))),
        const SizedBox(height: 28),
        Text(
            copy('İçeriğini tanı.\nSeçimini kendin yap.',
                'Know the ingredients.\nMake your own choice.'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        Text(copy(
            'Navilo, ürün etiketlerini okuyarak içerikleri anlaşılır bir şekilde gösterir.',
            'Navilo reads product labels and makes ingredients easier to understand.')),
        const SizedBox(height: 24),
        for (final item in [
          (
            Icons.qr_code_scanner,
            copy('Barkod okut veya etiket fotoğrafı ekle.',
                'Scan a barcode or add a label photo.')
          ),
          (
            Icons.fact_check_outlined,
            copy('Okunan metni ambalajla karşılaştır.',
                'Check the text against the package.')
          ),
          (
            Icons.view_agenda_outlined,
            copy('Sonuçları kısa, ayrı kartlarda gör.',
                'See clear results in separate cards.')
          ),
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(item.$1, color: const Color(0xFF214D3B)),
                const SizedBox(width: 14),
                Expanded(child: Text(item.$2))
              ])),
        FilledButton(
            onPressed: finishOnboarding,
            child: Text(copy('Başlayalım', 'Get started'))),
        const SizedBox(height: 10),
        OutlinedButton(
            onPressed: () {
              finishOnboarding(profile: true);
            },
            child: Text(
                copy('Önce tercihlerimi seç', 'Choose preferences first'))),
        TextButton(
            onPressed: finishOnboarding,
            child: Text(copy('Tanıtımı atla', 'Skip introduction'))),
        const SizedBox(height: 12),
        Text(
            copy('Bilgilendirme amaçlıdır; doktor tavsiyesi değildir.',
                'For information only; not medical advice.'),
            textAlign: TextAlign.center),
      ]);

  Widget homeScreen() => pageList([
        Text(
            copy('Bugün neyi\ninceleyelim?',
                'What would you like\nto check today?'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(copy('Bir ürün seç. İçeriğine birlikte bakalım.',
            'Choose a product and explore its ingredients.')),
        const SizedBox(height: 24),
        categoryPicker(),
        const SizedBox(height: 24),
        if (scanError != null) scanFailure(),
        captureActions(),
        if (label.text.isNotEmpty)
          TextButton.icon(
              onPressed: () => setState(() => stage = ScanStage.review),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                  copy('Açık ürüne devam et', 'Continue current product'))),
        const SizedBox(height: 16),
        Text(copy('Telefona kaydettiklerin', 'Saved on this phone'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (recentProducts.isEmpty)
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(copy(
                  'Henüz kayıt yok. Bir ürünü inceleyip kaydettiğinde burada görünür.',
                  'No saved products yet. Review and save a product to find it here.'))),
        ...recentProducts.map((product) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
                child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    leading: productThumbnail(product, size: 48),
                    title: Text(product.name.isEmpty
                        ? copy('Kaydedilen ürün', 'Saved product')
                        : product.name),
                    subtitle: Text(
                        '${product.barcode.isEmpty ? copy('Barkodsuz kayıt', 'No barcode') : product.barcode}\n${dateLabel(product.reviewedAt)}'),
                    isThreeLine: true,
                    trailing: IconButton(
                        tooltip:
                            copy('Kütüphaneden sil', 'Delete from library'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteLibraryProduct(product)),
                    onTap: () => openSaved(product))))),
        if (storageError != null) notice(storageError!, warning: true),
        const SizedBox(height: 20),
        Text(copy('Bilgilendirme amaçlıdır; doktor tavsiyesi değildir.',
            'For information only; not medical advice.')),
      ]);

  Widget reviewScreen(Policy data) {
    final issues = IngredientText.reviewIssues(label.text);
    return pageList([
      progressHeader(2),
      Text(copy('Okunan içeriği kontrol et', 'Check the ingredient text'),
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(copy(
          'Fotoğraf veya ürün kaydı eksik olabilir. Okunan listeyi ambalajdaki içindekilerle karşılaştır.',
          'A photo or product record can be incomplete. Compare the text with the ingredient list on the package.')),
      const SizedBox(height: 20),
      if (productName != null)
        Text(productName!, style: Theme.of(context).textTheme.titleLarge),
      if (activeBarcode != null)
        Text('${copy('Barkod', 'Barcode')}: $activeBarcode'),
      if (productRecord?.nameMatched == true)
        notice(
            copy(
                'Barkod tam eşleşmedi. Taradığın barkod: $activeBarcode · bulunan kayıt: ${productRecord!.code}. Bu iki barkodun aynı ürün olduğundan emin olmadan içerik listesini kullanma.',
                'The barcode did not match exactly. Scanned: $activeBarcode · candidate record: ${productRecord!.code}. Do not use this ingredient list unless you confirm it is the same product.'),
            warning: true),
      if (localReviewDate != null)
        notice(copy(
            'Bu kayıt ${dateLabel(localReviewDate!)} tarihinde kaydedildi. Güncel ambalajı tekrar kontrol et.',
            'Saved on ${dateLabel(localReviewDate!)}. Check the current package again.')),
      if (scanError != null) scanFailure(),
      if (photoPath != null)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(photoPath!),
                    height: 220,
                    fit: BoxFit.contain,
                    semanticLabel: copy('Kontrol edilecek etiket fotoğrafı',
                        'Label photo to review')))),
      if (photoPath != null && !ingredientSectionDetected)
        notice(
            copy(
                'Başlık tanınmadı; bu, içeriklerin okunamadığı anlamına gelmez. Aşağıdaki metni etiketle karşılaştır.',
                'No ingredient heading was read. Make sure this is the ingredient list.'),
            warning: true),
      if (issues.isNotEmpty)
        notice(
            issues.contains('empty')
                ? copy('Metin okunamadı. Daha net bir etiket fotoğrafı ekle.',
                    'No text was read. Add a clearer label photo.')
                : issues.contains('parentheses')
                    ? copy(
                        'Okunan metinde açılan ve kapanan parantezler eşleşmiyor. OCR bir işareti atlamış olabilir. Etiketle karşılaştırıp eksik işareti düzelt.',
                        'A bracket is missing or out of order. Check for a cut-off list; retake the photo if needed.')
                    : copy(
                        'Okunamayan bir karakter var. Fotoğrafla karşılaştırıp düzelt veya yeniden çek.',
                        'An unreadable character was found. Correct it against the photo or retake it.'),
            warning: true),
      const SizedBox(height: 12),
      TextField(
          controller: label,
          minLines: 6,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 17, height: 1.6),
          onChanged: (_) => setState(() {
                complete = false;
                matches = null;
                localReviewDate = null;
              }),
          decoration: InputDecoration(
              labelText: copy('Okunan içindekiler', 'Ingredient text'),
              helperText: copy(
                  'Yalnızca yanlış okunan yerleri düzeltebilirsin.',
                  'Correct any text that was misread.'),
              helperMaxLines: 3)),
      if (rawOcrText.isNotEmpty)
        ExpansionTile(
            title: Text(copy('Özgün okuma metni', 'Original text read')),
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(rawOcrText))
            ]),
      const SizedBox(height: 20),
      Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: complete
                      ? const Color(0xFF214D3B)
                      : const Color(0xFFD8E2DC))),
          child: Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                  key: const ValueKey('confirm-list'),
                  contentPadding: const EdgeInsets.all(12),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(copy('Liste tam ve doğru okunmuş',
                      'The list is complete and correctly read')),
                  subtitle: Text(copy('Ambalajla karşılaştırdım.',
                      'I checked it against the package.')),
                  value: complete,
                  onChanged: issues.isNotEmpty
                      ? null
                      : (value) => setState(() => complete = value ?? false)))),
      if (!complete && issues.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(copy('Sonuca geçmek için yukarıdaki kutuyu işaretle.',
                'Tick the box above to see the results.'))),
      const SizedBox(height: 16),
      FilledButton.icon(
          key: const ValueKey('show-results'),
          onPressed: complete && issues.isEmpty
              ? () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    matches = data.evaluate(label.text, category);
                    stage = ScanStage.result;
                  });
                }
              : null,
          icon: const Icon(Icons.arrow_forward),
          label: Text(copy('Sonuçları göster', 'Show results'))),
      const SizedBox(height: 20),
      ExpansionTile(
          title: Text(copy('Yeniden fotoğraf ekle', 'Add another photo')),
          children: [
            notice(copy(
                'Yansımadan kaçın. İçindekilerin tamamını kırpma alanına al.',
                'Avoid glare. Include the entire list when cropping.')),
            captureActions(retry: true)
          ]),
    ]);
  }

  Widget productSource() => ExpansionTile(
          title: Text(copy('Ürün verisi ve kaynak', 'Product data and source')),
          children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (productRecord != null) ...[
                        Text(productRecord!.sourceName),
                        if (productRecord!.nameMatched)
                          Text(copy('Eşleşme yöntemi: ürün adıyla arama',
                              'Match method: product-name search')),
                        if (productRecord!.nameLookupSource != null)
                          Text(
                              '${copy('Ürün adı kaynağı', 'Product name source')}: ${productRecord!.nameLookupSource}'),
                        Text(
                            '${copy('Kayıt barkodu', 'Record barcode')}: ${productRecord!.code}'),
                        SelectableText(productRecord!.sourceUrl),
                        Text(
                            '${copy('Güncelleme', 'Updated')}: ${productRecord!.modified == null ? copy('Bilinmiyor', 'Unknown') : dateLabel(productRecord!.modified!)}'),
                        Text(
                            '${copy('Kayıtlı alerjenler', 'Declared allergens')}: ${productRecord!.allergens.join(', ')}'),
                        Text(
                            '${copy('İz uyarıları', 'Trace warnings')}: ${productRecord!.traces.join(', ')}'),
                        Text(
                            '${copy('Etiket beyanları', 'Label claims')}: ${productRecord!.labels.join(', ')}'),
                      ] else
                        Text(localReviewDate != null
                            ? copy('Bu telefona kaydedilmiş içerik metni.',
                                'Ingredient text saved on this phone.')
                            : copy(
                                'Fotoğraftan cihaz üzerinde okunan içerik metni.',
                                'Ingredient text read from the photo on this device.')),
                      Text(copy(
                          'Boş alanlar yokluk kanıtı değildir. Güncel ambalaj esas alınmalıdır.',
                          'Missing fields do not establish absence. Check the current package.')),
                    ]))
          ]);

  Widget sourceSummaryCard() {
    final record = productRecord;
    final source = record?.sourceName ??
        (localReviewDate == null
            ? copy('Fotoğraftan okundu', 'Read from photo')
            : copy('Telefondaki kayıt', 'Saved on this device'));
    final unverifiedCommunity = record != null &&
        (record.sourceName.startsWith('Open ') ||
            record.sourceName == 'Navilo Community');
    final updated = record?.modified ?? localReviewDate;
    return Card(
        color: const Color(0xFFF0F5F1),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.source_outlined, color: Color(0xFF214D3B)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(source,
                        style: Theme.of(context).textTheme.titleMedium))
              ]),
              if (unverifiedCommunity)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(copy('Topluluk verisi · doğrulanmadı',
                        'Community data · unverified'))),
              if (record?.nameMatched == true)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(copy('Ürün adıyla eşleşme',
                              'Matched by product name')),
                          if (record?.nameLookupSource != null)
                            Text(
                                '${copy('Ürün adı kaynağı', 'Product name source')}: ${record!.nameLookupSource}'),
                          Text(copy(
                              'Ürün ve içerik ambalajla karşılaştırılmalı.',
                              'Compare the product and ingredients with the package.'))
                        ])),
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      '${copy('Veritabanında son güncelleme', 'Database last updated')}: ${updated == null ? copy('bilinmiyor', 'unknown') : dateLabel(updated)}')),
              const SizedBox(height: 8),
              Text(copy(
                  'İçerik ve barkodu güncel ambalajla karşılaştır. Eşleşme veya kayıt, ürünün güvenli olduğunu garanti etmez.',
                  'Compare the ingredients and barcode with the current package. A match or database record does not guarantee product safety.'))
            ])));
  }

  Widget resultScreen(Policy data) => pageList([
        progressHeader(3),
        Text(productName ?? copy('İçerik özeti', 'Ingredient summary'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(copy('Kontrol ettiğin metne göre değerlendirme.',
            'Assessment of the text you reviewed.')),
        const SizedBox(height: 24),
        resultRow(
            copy('Kaçınılan içerikler', 'Avoided ingredients'),
            matches!.isEmpty
                ? tr('Listemizdeki madde tespit edilmedi')
                : copy('Listemizdeki madde tespit edildi',
                    'Listed ingredients detected'),
            matches!.map((r) => english ? r.englishName : r.name).toList(),
            warning: matches!.isNotEmpty),
        if (category == 'food') dietaryPanel(),
        const SizedBox(height: 12),
        sourceSummaryCard(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: () => setState(() => stage = ScanStage.review),
            icon: const Icon(Icons.edit_outlined),
            label: Text(copy('Okunan metni incele', 'Review the text'))),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: saveReviewedProduct,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(copy('Kütüphaneye kaydet', 'Save to library'))),
        if (activeBarcode == null)
          TextButton.icon(
              onPressed: linkBarcode,
              icon: const Icon(Icons.qr_code),
              label: Text(copy(
                  'Barkod bağla (isteğe bağlı)', 'Link barcode (optional)'))),
        if (localReviewDate != null) ...[
          notice(copy('Bu telefona kaydedildi.', 'Saved on this phone.')),
          TextButton.icon(
              onPressed: deleteSavedProduct,
              icon: const Icon(Icons.delete_outline),
              label: Text(copy('Yerel kaydı sil', 'Delete saved record'))),
        ],
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
            onPressed: goHome,
            icon: const Icon(Icons.home_outlined),
            label: Text(copy('Ana sayfaya dön · Yeni ürün tara',
                'Go home · Scan a new product'))),
        const SizedBox(height: 24),
        productSource(),
        ExpansionTile(
            title: Text(
                copy('Değerlendirmenin sınırları', 'Assessment limitations')),
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(copy(
                            'Bu sonuç güvenlik garantisi veya doktor tavsiyesi değildir. Tam ad eşleştirmesi kullanılır; yanlış okunan veya sözlükte olmayan maddeler kaçabilir.',
                            'This is not a safety guarantee or medical advice. Exact name matching can miss misread or unlisted ingredients.')),
                        const SizedBox(height: 12),
                        Text(copy(
                            'Ağır metaller: Test verisi yok; etiketle dışlanamaz.',
                            'Heavy metals cannot be ruled out from a label; no test data is available.')),
                        const SizedBox(height: 12),
                        Text(
                            '${copy('Politika sürümü', 'Policy version')}: ${data.version}'),
                      ]))
            ]),
      ]);

  Widget productThumbnail(LocalProduct product, {double size = 92}) {
    final fallback = Container(
        color: const Color(0xFFE4EFE8),
        alignment: Alignment.center,
        child: Icon(product.category == 'food'
            ? Icons.restaurant_outlined
            : Icons.spa_outlined));
    return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
            width: size,
            height: size,
            child: FutureBuilder<LocalProductStore>(
                future: localStore,
                builder: (context, snapshot) {
                  final file = snapshot.data?.imageFor(product);
                  return file == null
                      ? (ProductRecord.licensedImage(product.remoteImageUrl) ==
                              null
                          ? fallback
                          : Image.network(product.remoteImageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, error, stack) => fallback))
                      : Image.file(file,
                          fit: BoxFit.contain,
                          cacheWidth:
                              (size * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          errorBuilder: (_, error, stack) => fallback);
                })));
  }

  Future<void> changeProductPhoto(
      LocalProduct product, ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (image == null) return;
      await (await localStore).attachImage(product, File(image.path));
      await refreshRecent();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(copy('Görsel kaydedilemedi. Tekrar dene.',
                'Could not save the photo. Please retry.'))));
      }
    }
  }

  Widget libraryScreen() {
    final query = normalize(libraryQuery);
    final records = libraryProducts
        .where((product) =>
            product.category == libraryCategory &&
            (query.isEmpty ||
                normalize(product.name).contains(query) ||
                product.barcode.contains(query)))
        .toList();
    return pageList([
      TextField(
          onChanged: (value) => setState(() => libraryQuery = value),
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: copy('Ürün adı veya barkod ara',
                  'Search product name or barcode'))),
      const SizedBox(height: 18),
      Wrap(spacing: 12, runSpacing: 10, children: [
        for (final item in [
          ('food', copy('Gıda', 'Food')),
          ('cosmetic', copy('Kozmetik', 'Cosmetics'))
        ])
          ChoiceChip(
              showCheckmark: false,
              selectedColor: const Color(0xFFD9EEE2),
              side: BorderSide(color: const Color(0xFF527565)),
              label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(item.$2)),
              selected: libraryCategory == item.$1,
              onSelected: (_) => setState(() => libraryCategory = item.$1))
      ]),
      const SizedBox(height: 18),
      Text(copy('${records.length} ürün', '${records.length} products'),
          style: Theme.of(context).textTheme.titleMedium),
      if (records.isEmpty)
        notice(query.isEmpty
            ? copy(
                'Bu bölümde kayıt yok. Sonuç ekranındaki “Kütüphaneye kaydet” düğmesiyle ürün ekleyebilirsin.',
                'No records in this section. Use Save to library on a result screen.')
            : copy('Aramana uygun ürün bulunamadı.',
                'No products match your search.')),
      ...records.map((product) => Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => openLibraryProduct(product),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    productThumbnail(product),
                    const SizedBox(width: 18),
                    Expanded(
                        child: Text(
                            product.name.isEmpty
                                ? copy('Kaydedilen ürün', 'Saved product')
                                : product.name,
                            style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(width: 8),
                    IconButton(
                        tooltip:
                            copy('Kütüphaneden sil', 'Delete from library'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteLibraryProduct(product)),
                  ]))))),
      const SizedBox(height: 16),
      Text(copy(
          'Kayıtlar bu telefonda saklanır. Paylaşmak için ürünü aç, içeriğini kontrol et ve kaydederken ortak kataloğa gönder seçeneğini işaretle.',
          'Records are stored on this phone. To share, open a product, review its ingredients and select shared catalogue submission when saving.')),
      if (storageError != null) notice(storageError!, warning: true),
    ],
        title: copy('Ürün kütüphanem', 'My product library'),
        subtitle: copy('Kaydettiğin ürünlerin adı ve içeriği burada.',
            'Find the names and ingredients of your saved products.'));
  }

  Future<void> deleteLibraryProduct(LocalProduct product) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(copy('Ürünü sil?', 'Delete product?')),
              content: Text(
                  '${product.name}\n\n${copy('Ürün, içindekiler ve bu telefonda saklanan ürün fotoğrafı kütüphanenden silinecek.', 'The product, ingredients and locally saved product photo will be removed from your library.')}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(copy('Vazgeç', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(copy('Sil', 'Delete'))),
              ],
            ));
    if (confirmed != true || !mounted) return;
    try {
      await (await localStore).remove(product.id, product.category);
      if (!mounted) return;
      if (activeLocalId == product.id && category == product.category) {
        setState(resetProduct);
      }
      await refreshRecent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(copy(
              'Ürün kütüphaneden silindi.', 'Product removed from library.'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(copy('Ürün silinemedi. Tekrar dene.',
              'Could not delete product. Please retry.'))));
    }
  }

  Future<void> linkLibraryBarcode(LocalProduct product) async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(english: english)));
    if (!mounted || code == null) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title:
                  Text(copy('Barkodu ürüne bağla', 'Link barcode to product')),
              content: Text(
                  '${product.name}\n\n$code\n\n${copy('Bu barkodun bu ürüne ait olduğunu onaylıyor musun?', 'Confirm this barcode belongs to this product.')}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(copy('Vazgeç', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(copy('Bağla', 'Link'))),
              ],
            ));
    if (confirmed != true || !mounted) return;
    try {
      await (await localStore).save(LocalProduct(
          id: product.id,
          barcode: code,
          category: product.category,
          name: product.name,
          ingredients: product.ingredients,
          reviewedAt: product.reviewedAt,
          imageFile: product.imageFile,
          remoteImageUrl: product.remoteImageUrl,
          imageSourceUrl: product.imageSourceUrl));
      await refreshRecent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(copy(
              'Barkod bağlandı. Tekrar taradığında bu ürün açılacak.',
              'Barcode linked. Scan again to open this product.'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(copy('Barkod kaydedilemedi.', 'Could not save barcode.'))));
    }
  }

  void openLibraryProduct(LocalProduct product) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (ctx, scroll) => ListView(
                    controller: scroll,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                              tooltip: copy('Kapat', 'Close'),
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close))),
                      Text(
                          product.name.isEmpty
                              ? copy('Kaydedilen ürün', 'Saved product')
                              : product.name,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      if (product.barcode.isNotEmpty)
                        SelectableText(
                            '${copy('Barkod', 'Barcode')}: ${product.barcode}'),
                      if (product.barcode.isEmpty)
                        Text(copy('Barkod bağlı değil · Tarama ile bulunamaz',
                            'No linked barcode · Cannot be found by scanning')),
                      FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            openSaved(product);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(copy('İçeriği düzenle / paylaş',
                              'Edit ingredients / share'))),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            linkLibraryBarcode(product);
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(copy('Barkod bağla / düzelt',
                              'Link / correct barcode'))),
                      Text(
                          '${copy('Son kontrol', 'Last reviewed')}: ${dateLabel(product.reviewedAt)}'),
                      const SizedBox(height: 24),
                      Center(child: productThumbnail(product, size: 200)),
                      if (product.imageFile == null &&
                          product.remoteImageUrl != null) ...[
                        const SizedBox(height: 12),
                        SelectableText(
                            'Open Food Facts contributors · CC BY-SA 3.0\nhttps://creativecommons.org/licenses/by-sa/3.0/\n${product.imageSourceUrl ?? ""}'),
                      ],
                      const SizedBox(height: 12),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              changeProductPhoto(product, ImageSource.gallery);
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(copy('Görsel ekle / değiştir',
                                'Add / change photo'))),
                        OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              changeProductPhoto(product, ImageSource.camera);
                            },
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(copy(
                                'Ürün fotoğrafı çek', 'Take product photo'))),
                      ]),
                      const SizedBox(height: 24),
                      Text(copy('İçindekiler', 'Ingredients'),
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      SelectableText(product.ingredients),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            openSaved(product);
                          },
                          icon: const Icon(Icons.fact_check_outlined),
                          label: Text(copy('Kontrol et ve yeniden değerlendir',
                              'Review and assess again'))),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error),
                          onPressed: () {
                            Navigator.pop(ctx);
                            deleteLibraryProduct(product);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                              copy('Kütüphaneden sil', 'Delete from library'))),
                    ])));
  }

  Widget profileScreen() => pageList([
        notice(copy(
            'Tercihlerin bu telefona kaydedilir. Henüz ürün sonuçlarını veya önerileri değiştirmez.',
            'Preferences are saved on this phone. They do not yet change product results or recommendations.')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
            initialValue: skin,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: copy(
                    'Beyan ettiğin cilt tipi', 'Your self-reported skin type')),
            items: ['Henüz seçilmedi', 'Kuru', 'Yağlı', 'Karma', 'Normal']
                .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(tr(value),
                        maxLines: 1, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) {
              setState(() => skin = value!);
              persistSettings();
            }),
        const SizedBox(height: 28),
        Text(copy('Beslenme tercihlerin', 'Dietary preferences'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              'Vegan',
              'Glutensiz',
              'Laktozsuz',
              'Şekersiz',
              'İlave şekersiz',
              'Rafine şekersiz',
              'Az yağlı',
              'Ketojenik',
              'Düşük FODMAP'
            ]
                .map((value) => FilterChip(
                    label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(tr(value))),
                    selected: preferences.contains(value),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? preferences.add(value)
                            : preferences.remove(value);
                      });
                      persistSettings();
                    }))
                .toList()),
        const SizedBox(height: 28),
        notice(copy(
            'Cilt analizi, sağlık durumuna göre öneriler ve tarifler henüz kullanıma açık değil.',
            'Skin analysis, health-based recommendations and recipes are not available yet.')),
        if (storageError != null) notice(storageError!, warning: true),
      ],
          title: copy('Tercihlerim', 'My preferences'),
          subtitle: copy('Sana uygun seçenekler için bir başlangıç.',
              'A starting point for your choices.'));

  Widget criteriaScreen(Policy data) => pageList([
        notice(copy(
            'Taslak içerik listesi. Kapsam tam değildir ve uzman incelemesi bekler.',
            'Draft ingredient dictionary. Coverage is incomplete and pending expert review.')),
        dietaryPanel(reference: true),
        const SizedBox(height: 18),
        ...data.rules.map((rule) => Card(
                child: ExpansionTile(
                    title: Text(english ? rule.englishName : rule.name),
                    subtitle: Text(rule.category == 'food'
                        ? copy('Gıda', 'Food')
                        : copy('Bakım ve kozmetik', 'Beauty & care')),
                    children: [
                  Padding(
                      padding: const EdgeInsets.all(18),
                      child: SelectableText(rule.aliases.join(', ')))
                ]))),
      ],
          title: copy('Neye bakıyoruz?', 'What do we check?'),
          subtitle: copy('Kaçınılan içerikler ve kullanılan kaynaklar.',
              'Avoided ingredients and reference sources.'));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: stage == ScanStage.start || page != 0 || onboarding,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !reading) backStep();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: page == 0 && stage != ScanStage.start && !onboarding
                ? IconButton(
                    tooltip: copy('Geri', 'Back'),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: reading ? null : backStep)
                : null,
            title: const NaviloWordmark(),
            actions: [
              if (!onboarding && (page != 0 || stage != ScanStage.start))
                IconButton(
                    tooltip: copy('Ana sayfaya dön', 'Go home'),
                    onPressed: reading ? null : goHome,
                    icon: const Icon(Icons.home_outlined)),
              TextButton(
                  onPressed: reading
                      ? null
                      : () {
                          setState(() => english = !english);
                          if (!loadingSettings) persistSettings();
                        },
                  child: Text(english ? 'Türkçe' : 'English')),
              const SizedBox(width: 8)
            ],
          ),
          bottomNavigationBar: onboarding || stage != ScanStage.start
              ? null
              : NavigationBar(
                  selectedIndex: page,
                  onDestinationSelected:
                      reading ? null : (value) => setState(() => page = value),
                  destinations: [
                      NavigationDestination(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: copy('Ürün incele', 'Check product')),
                      NavigationDestination(
                          icon: const Icon(Icons.tune),
                          label: copy('Tercihlerim', 'Preferences')),
                      NavigationDestination(
                          icon: const Icon(Icons.fact_check_outlined),
                          label: copy('Kriterler', 'Criteria')),
                      NavigationDestination(
                          icon: const Icon(Icons.bookmarks_outlined),
                          label: copy('Kütüphane', 'Library')),
                    ]),
          body: SafeArea(
              child: loadingSettings
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(copy('Hazırlanıyor…', 'Getting ready…'))
                    ]))
                  : reading
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 24),
                                    Text(
                                        copy('Ürün bilgisi hazırlanıyor',
                                            'Preparing product information'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 12),
                                    Text(copy('Lütfen biraz bekle.',
                                        'Please wait a moment.'))
                                  ])))
                      : onboarding
                          ? welcomeScreen()
                          : FutureBuilder<Policy>(
                              future: policy,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                      child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Text(copy(
                                              'İçerik kriterleri yüklenemedi. Uygulamayı yeniden açmayı dene.',
                                              'Ingredient criteria could not load. Try reopening the app.'))));
                                }
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final data = snapshot.requireData;
                                if (page == 1) return profileScreen();
                                if (page == 2) return criteriaScreen(data);
                                if (page == 3) return libraryScreen();
                                return switch (stage) {
                                  ScanStage.start => homeScreen(),
                                  ScanStage.review => reviewScreen(data),
                                  ScanStage.result => resultScreen(data)
                                };
                              })),
        ),
      );
}
