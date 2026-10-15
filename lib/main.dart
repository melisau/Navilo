import 'features/skin_test/skin_type.dart';
import 'features/skin_test/skin_test_service.dart';
import 'features/skin_test/skin_test_screen.dart';
import 'features/skin_test/skin_fit_evaluator.dart';
import 'widgets/navilo_wordmark.dart';
import 'widgets/ingredient_explanation.dart';
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
import 'package:url_launcher/url_launcher.dart';

import 'domain/policy.dart';
import 'data/community_submission.dart';
import 'theme/navilo_theme.dart';

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
        theme: NaviloTheme.light(),
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
              HapticFeedback.selectionClick();
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
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
  SkinTestResult? skinResult;
  final Set<String> preferences = {};
  List<IngredientRule>? matches;
  bool complete = false;
  bool editingReview = false;
  bool reading = false;
  bool barcodeSearching = false;
  int lookupStep = 0;
  String? photoPath;
  final List<String> photoPaths = [];
  String? scanError;
  bool searchingNameMatches = false;
  bool ingredientSectionDetected = false;
  String? productName;
  ProductRecord? productRecord;
  LocalProduct? activeLocalProduct;
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
  int libraryTab = 0;
  String catalogueCategory = 'food';
  String catalogueQuery = '';
  late Future<List<ProductRecord>> catalogueProducts =
      ProductRepository().listCurated(category: catalogueCategory);
  bool contributing = false;
  String contributionQuery = '';
  late final Future<List<dynamic>> contributionCandidates = rootBundle
      .loadString('assets/contribution_candidates.json')
      .then((text) => jsonDecode(text) as List<dynamic>);
  String criteriaQuery = '';
  String criteriaCategory = 'all';
  String? activeLocalId;
  late final Future<AppSettingsStore> settingsStore =
      localStore.then((store) => AppSettingsStore(store.directory.parent));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadSettings();
    loadSkinProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncPendingSubmissions();
    }
  }

  Future<void> loadSkinProfile() async {
    if (!widget.persistSettings) return;
    try {
      final result = await SkinTestStorage.load();
      if (mounted) {
        setState(() {
          skinResult = result;
          if (result != null) skin = result.type.label;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => storageError = copy(
            'Cilt profili yüklenemedi. Tercihlerden yeniden test yapabilirsin.',
            'Skin profile could not load. Retake the test in preferences.'));
      }
    }
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
        skin = skinResult?.type.label ?? settings.skin;
        preferences.addAll(settings.preferences);
        libraryProducts = recent;
        recentProducts = recent.take(5).toList();
      });
      await syncPendingSubmissions();
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

  Future<void> syncPendingSubmissions() async {
    if (!ProductRepository.catalogConfigured) return;
    try {
      final store = await localStore;
      final pending = await store.pendingSubmissions();
      var failed = 0;
      for (final item in pending) {
        try {
          await CommunitySubmission.submit(item.product,
              language: item.language);
          await store.removePendingSubmission(item);
        } catch (_) {
          failed++;
        }
      }
      if (failed > 0 && mounted) {
        setState(() => storageError = copy(
            '$failed ürün internet bağlantısı bekliyor; bağlantı gelince tekrar eşitlenecek.',
            '$failed product contribution(s) are waiting for internet and will retry automatically.'));
      }
    } on FormatException {
      if (mounted) {
        setState(() => storageError = copy(
            'Bekleyen ortak kaynak kayıtları okunamadı.',
            'Pending shared-source records could not be read.'));
      }
    }
  }

  String dateLabel(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void resetProduct() {
    contributing = false;
    barcodeSearching = false;
    lookupStep = 0;
    label.clear();
    activeBarcode = null;
    activeLocalId = null;
    activeLocalProduct = null;
    localReviewDate = null;
    productName = null;
    productRecord = null;
    photoPath = null;
    photoPaths.clear();
    rawOcrText = '';
    scanError = null;
    matches = null;
    complete = false;
    editingReview = false;
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
      editingReview = true;
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
      final candidates = await ProductRepository().findNameCandidates(
          productName: confirmedQuery, english: english, category: category);
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

  Future<void> webResearch() async {
    final identity = [
      if (productName?.trim().isNotEmpty == true) productName!.trim(),
      if (activeBarcode?.trim().isNotEmpty == true) activeBarcode!.trim(),
    ].join(' ');
    if (identity.isEmpty) {
      if (mounted) {
        setState(() => scanError = copy(
            'Web araması için ürün adı veya barkod gerekli.',
            'A product name or barcode is required for web search.'));
      }
      return;
    }
    final query = '$identity ingredients içindekiler';
    final opened = await launchUrl(
        Uri.https('www.google.com', '/search', {'q': query}),
        mode: LaunchMode.externalApplication);
    if (!opened || !mounted) {
      if (mounted) {
        setState(() => scanError = copy(
            'Web araştırması açılamadı. Bağlantıyı kontrol et veya etiketi fotoğrafla ekle.',
            'Could not open web research. Check your connection or add a label photo.'));
      }
      return;
    }
    var sourceUrl = '';
    var copiedText = '';
    final imported = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(copy('Web’den bulunan içeriği aktar',
                  'Import information found on the web')),
              content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(copy(
                            'Güvenilir sayfadaki ürün adı ve içindekiler listesini topluca kopyalayıp aşağıya yapıştır. Kaydetmeden önce tamamını okuyup onaylayabileceksin.',
                            'Copy the product name and full ingredient list from a reliable page and paste it below. You can read and approve everything before saving.')),
                        const SizedBox(height: 12),
                        TextField(
                            onChanged: (value) => sourceUrl = value.trim(),
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                                labelText: copy(
                                    'Kaynak sayfa adresi (isteğe bağlı)',
                                    'Source page URL (optional)'))),
                        const SizedBox(height: 8),
                        TextField(
                            minLines: 8,
                            maxLines: 16,
                            onChanged: (value) => copiedText = value.trim(),
                            decoration: InputDecoration(
                                alignLabelWithHint: true,
                                labelText: copy('Ürün adı ve içindekiler metni',
                                    'Product name and ingredient text'),
                                hintText: copy('Metni buraya yapıştır',
                                    'Paste the text here'))),
                      ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(copy('Vazgeç', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(
                        dialogContext, copiedText.trim().isNotEmpty),
                    child: Text(copy('Önizle', 'Preview')))
              ],
            ));
    if (imported != true || !mounted || copiedText.trim().isEmpty) return;
    final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(copy('İçeriği onayla', 'Approve information')),
              content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                      child: SelectableText(copiedText.trim()))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(copy('Düzenle', 'Edit'))),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(copy('Onayla ve kullan', 'Approve and use')))
              ],
            ));
    if (approved != true || !mounted) return;
    final lines = copiedText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final importedName = lines.isNotEmpty ? lines.first : '';
    final importedIngredients =
        lines.length > 1 ? lines.skip(1).join(' ') : copiedText.trim();
    setState(() {
      if (importedName.isNotEmpty && importedIngredients != copiedText.trim()) {
        productName = importedName;
      }
      label.text = importedIngredients;
      ingredientSectionDetected = true;
      editingReview = true;
      complete = IngredientText.reviewIssues(importedIngredients).isEmpty;
      scanError = sourceUrl.isEmpty
          ? copy('Web içeriği aktarıldı. Kaydetmeden önce kontrol et.',
              'Web information imported. Review it before saving.')
          : copy('Web içeriği aktarıldı: $sourceUrl',
              'Web information imported: $sourceUrl');
      stage = ScanStage.review;
    });
  }

  void openSaved(LocalProduct product) {
    setState(() {
      resetProduct();
      category = product.category;
      activeBarcode = product.barcode.isEmpty ? null : product.barcode;
      activeLocalId = product.id;
      activeLocalProduct = product;
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
    WidgetsBinding.instance.removeObserver(this);
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
      editingReview = true;
      matches = null;
      stage = ScanStage.review;
    });
  }

  Future<void> saveReviewedProduct() async {
    var code = activeBarcode;
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
                        const SizedBox(height: 12),
                        Text(copy(
                            'Barkodlu ve kontrol edilmiş kayıtlar ortak kaynağa gönderilir. İnternet yoksa bekletilir ve bağlantı gelince otomatik eşitlenir. Fotoğraf paylaşılmaz; kayıtlar inceleme sonrası herkes için kullanılabilir.',
                            'Reviewed barcode records are submitted to the shared source. If offline, they wait and sync automatically when online. Photos are not shared; records become available to everyone after review.')),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(copy('Vazgeç', 'Cancel'))),
                    FilledButton(
                        onPressed: () {
                          if ((code != null &&
                              !RegExp(r'^\d{8,14}$').hasMatch(code!))) {
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
                  : productRecord?.imageSourceUrl ?? productRecord?.sourceUrl));
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
      if (code != null && ProductRepository.catalogConfigured) {
        try {
          await store.queueSubmission(saved, language: english ? 'en' : 'tr');
          await CommunitySubmission.submit(saved,
              language: english ? 'en' : 'tr');
          await store.removePendingSubmission(PendingSubmission(
              product: saved, language: english ? 'en' : 'tr'));
          message = copy('Kaydedildi ve ortak kaynak incelemesine gönderildi.',
              'Saved and submitted for shared-source review.');
        } catch (_) {
          message = copy(
              'Telefona kaydedildi; internet gelince ortak kaynağa otomatik gönderilecek.',
              'Saved locally; it will be submitted to the shared source automatically when internet is available.');
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
      barcodeSearching = true;
      lookupStep = 0;
      activeBarcode = barcode;
      activeLocalId = null;
      localReviewDate = null;
      scanError = null;
      matches = null;
      label.clear();
      productName = null;
      productRecord = null;
      complete = false;
      editingReview = true;
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
          activeLocalProduct = saved;
          productName = saved.name.isEmpty ? null : saved.name;
          label.text = saved.ingredients;
          localReviewDate = saved.reviewedAt;
          activeLocalId = saved.id;
          complete = IngredientText.reviewIssues(saved.ingredients).isEmpty;
          editingReview = false;
          matches = loadedPolicy.evaluate(saved.ingredients, category);
          stage = ScanStage.review;
        });
        return;
      }
      if (mounted) setState(() => lookupStep = 1);
      final product = await ProductRepository().find(barcode,
          english: english, category: category, onProgress: (step) {
        if (mounted) setState(() => lookupStep = step);
      });
      final loadedPolicy = await policy;
      if (!mounted) return;
      setState(() {
        productRecord = product;
        productName = product.name;
        label.text = product.ingredients;
        complete = !product.nameMatched &&
            IngredientText.reviewIssues(product.ingredients).isEmpty;
        editingReview = false;
        ingredientSectionDetected = true;
        matches = loadedPolicy.evaluate(product.ingredients, category);
        stage = ScanStage.review;
      });
    } on ProductLookupException catch (error) {
      if (mounted) {
        setState(() {
          scanError =
              '${english ? "Barcode" : "Barkod"}: $barcode\n${error.attempts.join("\n")}\n${english ? "Take or upload an ingredient label photo." : "İçindekiler fotoğrafı çek veya ekle."}';
          editingReview = true;
          stage = ScanStage.review;
          searchingNameMatches = true;
        });
      }
      try {
        final candidates = await ProductRepository().findNameCandidates(
            barcode: barcode,
            productName: error.resolvedName,
            english: english,
            category: category);
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
        setState(() {
          scanError = english
              ? 'Product or ingredients unavailable. Take a label photo below.'
              : 'Ürün veya içerik bilgisi bulunamadı. Aşağıdan etiket fotoğrafı çek veya ekle.';
          editingReview = true;
          stage = ScanStage.review;
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          scanError =
              'Ürün verisine erişilemedi. İnternet bağlantısını kontrol et.';
          editingReview = true;
          stage = ScanStage.review;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          scanError = 'Barkod ürünü getirilemedi. Tekrar dene.';
          editingReview = true;
          stage = ScanStage.review;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          reading = false;
          barcodeSearching = false;
        });
      }
    }
  }

  Future<void> scanPhoto(ImageSource source, {bool append = false}) async {
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
        if (!append) photoPaths.clear();
        photoPaths.add(cropped.path);
        localReviewDate = null;
        rawOcrText = '';
        if (!contributing) productName = null;
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

      final hadHeading = ingredientSectionDetected;
      final previousRawOcr = rawOcrText;
      final text = _extractIngredientText(result.text);
      if (append) {
        ingredientSectionDetected = hadHeading || ingredientSectionDetected;
        rawOcrText = '${previousRawOcr.trim()}\n${result.text.trim()}'.trim();
      }
      final combinedText = append && label.text.trim().isNotEmpty
          ? '${label.text.trim()}\n$text'.trim()
          : text;
      final correctedText = append
          ? IngredientText.cleanOcr(combinedText)
          : IngredientText.cleanOcr(text);
      final loadedPolicy = await policy;
      if (!mounted) return;

      setState(() {
        stage = ScanStage.review;
        label.text = correctedText;
        matches = correctedText.trim().isEmpty
            ? null
            : loadedPolicy.evaluate(correctedText, category);
        complete =
            false; // A heading does not prove that the entire list is visible.
        scanError = label.text.trim().isEmpty
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

  Future<void> scanAdditionalPhoto(ImageSource source) async {
    await scanPhoto(source, append: true);
  }

  String rawOcrText = '';
  String _extractIngredientText(String text) {
    final parsed = IngredientText.parse(text);
    rawOcrText = parsed.raw;
    ingredientSectionDetected = parsed.headingFound;
    return parsed.ingredients;
  }

  List<TextSpan> highlightedIngredientSpans() {
    final source = label.text;
    final ranges = <(int, int)>[];
    for (final alias in matches!.expand((rule) => rule.aliases).toSet()) {
      if (alias.trim().length < 3) continue;
      final pattern = RegExp(RegExp.escape(alias), caseSensitive: false);
      for (final match in pattern.allMatches(source)) {
        ranges.add((match.start, match.end));
      }
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.$1 < cursor) continue;
      if (range.$1 > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, range.$1)));
      }
      spans.add(TextSpan(
          text: source.substring(range.$1, range.$2),
          style: const TextStyle(
              backgroundColor: Color(0xFFFFD36B),
              color: NaviloColors.ink,
              fontWeight: FontWeight.w700)));
      cursor = range.$2;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }
    return spans;
  }

  Widget resultRow(String title, String status, List<String> names,
      {bool warning = false, bool unknown = false, Color? accent}) {
    final indicatorColor = warning
        ? NaviloColors.warning
        : unknown
            ? NaviloColors.uncertain
            : accent ?? NaviloColors.muted;
    final indicator = warning
        ? Icons.warning_amber_rounded
        : unknown
            ? Icons.help_outline_rounded
            : Icons.remove_circle_outline_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NaviloColors.line))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(indicator, size: 21, color: indicatorColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: NaviloColors.muted,
                    letterSpacing: 1.05,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(status,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: warning ? NaviloColors.warning : NaviloColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.3)),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(names.join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: NaviloColors.muted)),
            ],
          ]),
        ),
      ]),
    );
  }

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
          final lactoseEnzyme = [
            'laktaz enzimi',
            'lactase enzyme',
            'lactase',
            'laktaz'
          ].any((alias) => containsIngredient(label.text, alias));
          final explicitlyListsLactose = lactose.any((e) => e.id == 'lactose');
          final lactoseFreeByEnzyme = lactoseEnzyme && !explicitlyListsLactose;
          final evidence = normalize(
              '$rawOcrText ${label.text} ${productName ?? ''} ${productRecord?.name ?? ''}');
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
          final fodmap = entries
              .where((e) =>
                  e.kind == 'fodmap_potential' ||
                  (e.kind == 'lactose_check' &&
                      (!lactoseClaim || explicitlyListsLactose) &&
                      !lactoseFreeByEnzyme))
              .toList();
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
          final lactoseFree = !explicitlyListsLactose &&
              (lactoseClaim || lactoseFreeByEnzyme || riceLactose);
          final milkAllergens =
              lactose.where((e) => e.id != 'lactose').toList();
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
                      lactoseFree
                          ? (english
                              ? (lactoseFreeByEnzyme
                                  ? 'Lactose-free · lactase enzyme listed'
                                  : 'Lactose-free · label claim')
                              : (lactoseFreeByEnzyme
                                  ? 'Laktozsuz · laktaz enzimi listelenmiş'
                                  : 'Laktozsuz · etiket beyanı'))
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
                      lactoseFreeByEnzyme && lactoseFree
                          ? [copy('Laktaz enzimi', 'Lactase enzyme')]
                          : lactoseFree
                              ? const <String>[]
                              : lactose.map((e) => e.name(english)).toList(),
                      warning: !lactoseFree && lactose.isNotEmpty,
                      accent: lactoseFree ? const Color(0xFF1672B8) : null),
                  if (lactoseFree && milkAllergens.isNotEmpty)
                    resultRow(
                        english ? 'Milk allergen' : 'Süt alerjeni',
                        english
                            ? 'Milk is still listed; lactose-free does not mean milk-protein-free.'
                            : 'Süt içerir; laktozsuz olması süt proteini içermediği anlamına gelmez.',
                        milkAllergens.map((e) => e.name(english)).toList(),
                        warning: true),
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
                      unknown:
                          sugarAdditions.isEmpty && !sugarClaim && !complete,
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
                          unknown: true,
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

  Widget lookupProgress() {
    final steps = [
      copy('Bu telefondaki kütüphane', 'This phone’s library'),
      copy('Ortak ürün kataloğu', 'Shared product catalog'),
      copy('Open Food Facts ve kardeş kataloglar',
          'Open Food Facts and related catalogs'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NaviloColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NaviloColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(copy('Barkod kaynakları kontrol ediliyor',
              'Checking barcode sources')),
          const SizedBox(height: 12),
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0) const SizedBox(height: 9),
            Row(children: [
              SizedBox(
                width: 22,
                height: 22,
                child: index < lookupStep
                    ? const Icon(Icons.check_circle_outline_rounded,
                        size: 19, color: NaviloColors.forest)
                    : index == lookupStep
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(Icons.radio_button_unchecked_rounded,
                            size: 19, color: NaviloColors.muted),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(steps[index])),
              if (index == 1 && !ProductRepository.catalogConfigured)
                Text(copy('Kapalı', 'Off'),
                    style: Theme.of(context).textTheme.bodySmall),
            ]),
          ],
        ],
      ),
    );
  }

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
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: 'food',
                icon: const Icon(Icons.restaurant_outlined, size: 18),
                label: Text(copy('Gıda', 'Food'))),
            ButtonSegment(
                value: 'cosmetic',
                icon: const Icon(Icons.spa_outlined, size: 18),
                label: Text(copy('Bakım ve kozmetik', 'Beauty & care'))),
          ],
          selected: {category},
          onSelectionChanged: reading
              ? null
              : (value) => setState(() {
                    if (category != value.first) {
                      resetProduct();
                      category = value.first;
                    }
                  }),
        ),
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
            title:
                copy('İçindekiler fotoğrafı çek', 'Take an ingredients photo'),
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
        OutlinedButton.icon(
            onPressed: reading ? null : webResearch,
            icon: const Icon(Icons.public),
            label: Text(copy('Web’de araştır', 'Research on the web'))),
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

  Widget scanHero() => Material(
        color: NaviloColors.forestDeep,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: reading
              ? null
              : () {
                  setState(resetProduct);
                  scanBarcode();
                },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 202),
            child: SizedBox(
              width: double.infinity,
              child: Stack(children: [
                Positioned(
                    right: 18,
                    top: 18,
                    child: Icon(Icons.center_focus_weak_rounded,
                        size: 110, color: Colors.white.withValues(alpha: .10))),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            color: Color(0xFFE9C576), size: 29),
                        const SizedBox(height: 12),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(copy('Barkod okut', 'Scan barcode'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'serif',
                                      fontSize: 23,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(
                                  copy('Ürünü hızlıca bul ve içeriğini incele',
                                      'Find the product quickly and review its ingredients'),
                                  style: const TextStyle(
                                      color: Color(0xFFD2DAD3), fontSize: 13)),
                            ]),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20)),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget homeScreen() => pageList([
        categoryPicker(),
        if (category == 'cosmetic') skinTypeCard(),
        const SizedBox(height: 18),
        Text(copy('Ürünün içeriğini keşfet', 'Explore what is inside'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(copy('Önce barkodu okut; gerekirse içindekiler fotoğrafı ekle.',
            'Scan the barcode first; add an ingredients photo if needed.')),
        const SizedBox(height: 18),
        if (scanError != null) scanFailure(),
        scanHero(),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: reading
                      ? null
                      : () {
                          if (scanError == null) setState(resetProduct);
                          scanPhoto(ImageSource.camera);
                        },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(copy('İçindekiler fotoğrafı çek',
                      'Take an ingredients photo')))),
          const SizedBox(width: 10),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: reading
                      ? null
                      : () {
                          if (scanError == null) setState(resetProduct);
                          scanPhoto(ImageSource.gallery);
                        },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(copy('Galeriden ekle', 'Choose a photo')))),
        ]),
        if (label.text.isNotEmpty)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: () => setState(() => stage = ScanStage.review),
                  icon: const Icon(Icons.arrow_forward),
                  label:
                      Text(copy('Açık ürüne devam et', 'Continue product')))),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(
              child: Text(copy('Son baktıkların', 'Recently viewed'),
                  style: Theme.of(context).textTheme.titleLarge)),
          TextButton(
              onPressed: () => setState(() => page = 3),
              child: Text(copy('Tümü', 'See all'))),
        ]),
        if (recentProducts.isEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(copy('Kaydettiğin ürünler burada görünür.',
                  'Your saved products will appear here.')))
        else
          SizedBox(
              height: 92,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final product = recentProducts[index];
                    return SizedBox(
                        width: 190,
                        child: Material(
                            color: NaviloColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => openSaved(product),
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(children: [
                                      productThumbnail(product, size: 54),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(
                                              product.name.isEmpty
                                                  ? copy('Kaydedilen ürün',
                                                      'Saved product')
                                                  : product.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall)),
                                    ])))));
                  })),
        if (storageError != null) notice(storageError!, warning: true),
        const SizedBox(height: 18),
        Text(
            copy('Bilgilendirme amaçlıdır; doktor tavsiyesi değildir.',
                'For information only; not medical advice.'),
            style: Theme.of(context).textTheme.bodySmall),
      ]);

  Widget reviewScreen(Policy data) {
    final issues = IngredientText.reviewIssues(label.text);
    final reviewReadOnly = complete && !editingReview;
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
      if (contributing || !reviewReadOnly) ...[
        if (contributing)
          Text(copy(
              'Ambalajdan barkodu okut, tam içeriği ekle ve kontrol ederek kaydet.',
              'Scan the package barcode, add the full ingredients and review before saving.')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: linkBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label:
                  Text(copy('Barkod okut / düzelt', 'Scan / correct barcode'))),
          OutlinedButton.icon(
              onPressed: () => scanPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(copy('Etiketi çek', 'Take label photo'))),
          OutlinedButton.icon(
              onPressed: () => scanPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(copy('Galeriden ekle', 'Add from gallery'))),
          OutlinedButton.icon(
              onPressed: () => scanAdditionalPhoto(ImageSource.camera),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(copy('Devamını çek', 'Capture next part'))),
          OutlinedButton.icon(
              onPressed: () => scanAdditionalPhoto(ImageSource.gallery),
              icon: const Icon(Icons.library_add_outlined),
              label: Text(copy('Devamını ekle', 'Add next part'))),
        ]),
      ],
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
      if (photoPaths.isNotEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: SizedBox(
                height: 220,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoPaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(photoPaths[index]),
                            width: 280,
                            fit: BoxFit.contain,
                            semanticLabel: copy(
                                'Kontrol edilecek etiket fotoğrafı',
                                'Label photo to review')))))),
      if (photoPaths.isNotEmpty && !ingredientSectionDetected)
        notice(
            copy(
                'Başlık tanınmadı; bu, içeriklerin okunamadığı anlamına gelmez. Aşağıdaki metni etiketle karşılaştır.',
                'No ingredient heading was read. Make sure this is the ingredient list.'),
            warning: true),
      if (issues.isNotEmpty)
        notice(
            issues.contains('empty')
                ? (contributing
                    ? copy('İçindekileri yaz veya etiket fotoğrafı ekle.',
                        'Type the ingredients or add a label photo.')
                    : copy(
                        'Metin okunamadı. Daha net bir etiket fotoğrafı ekle.',
                        'No text was read. Add a clearer label photo.'))
                : issues.contains('too_short')
                    ? copy(
                        'İçerik listesi çok kısa görünüyor. Etiketin devamını ekleyin veya metni ambalajla karşılaştırın.',
                        'The ingredient list looks too short. Add the next part or compare it with the package.')
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
          readOnly: reviewReadOnly,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 17, height: 1.6),
          onChanged: (_) => setState(() {
                complete = false;
                editingReview = true;
                matches = null;
                localReviewDate = null;
              }),
          decoration: InputDecoration(
              labelText: copy('Okunan içindekiler', 'Ingredient text'),
              helperText: copy(
                  reviewReadOnly
                      ? 'Kayıtlı içerik onaylandı. Düzenlemek için aşağıdaki düğmeyi kullan.'
                      : 'Yalnızca yanlış okunan yerleri düzeltebilirsin.',
                  reviewReadOnly
                      ? 'The saved ingredients are confirmed. Use the button below to edit.'
                      : 'Correct any text that was misread.'),
              helperMaxLines: 3)),
      if (reviewReadOnly) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: () => setState(() => editingReview = true),
            icon: const Icon(Icons.edit_outlined),
            label: Text(copy('İçeriği düzenle', 'Edit ingredients'))),
      ],
      if (productRecord?.mayContain.isNotEmpty == true)
        notice(
            copy(
                'Renge göre bulunabilecek pigmentler ayrı listelenmiştir. Kesin içerik değerlendirmesi bunları kapsamaz; güncel ambalajdaki CI kodlarını kontrol et.',
                'Possible shade pigments are listed separately. Confirmed ingredient matching excludes them; check the CI codes on your package.'),
            warning: true),
      if (rawOcrText.isNotEmpty)
        ExpansionTile(
            title: Text(copy('Özgün okuma metni', 'Original text read')),
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(rawOcrText))
            ]),
      if (!reviewReadOnly) ...[
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
                        : (value) => setState(() {
                              complete = value ?? false;
                              editingReview = true;
                            })))),
      ],
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
      if (contributing) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: complete && issues.isEmpty ? saveReviewedProduct : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(copy('Katkıyı kaydet', 'Save contribution'))),
      ],
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
                        if (productRecord!.imageUrl != null) ...[
                          Text(productRecord!.imageCredit),
                          if (productRecord!.imageCredit.contains('CC BY-SA'))
                            const SelectableText(
                                'https://creativecommons.org/licenses/by-sa/3.0/'),
                          SelectableText(productRecord!.imageSourceUrl ?? ''),
                        ],
                        if (productRecord!.nameMatched)
                          Text(copy('Eşleşme yöntemi: ürün adıyla arama',
                              'Match method: product-name search')),
                        if (productRecord!.nameLookupSource != null)
                          Text(
                              '${copy('Ürün adı kaynağı', 'Product name source')}: ${productRecord!.nameLookupSource}'),
                        Text(
                            '${copy('Kayıt barkodu', 'Record barcode')}: ${productRecord!.code}'),
                        SelectableText(productRecord!.sourceUrl),
                        if (productRecord!.mayContain.isNotEmpty) ...[
                          Text(copy('İçerebilir · renk pigmentleri',
                              'May contain · colour pigments')),
                          SelectableText(productRecord!.mayContain),
                          Text(copy(
                              'Üreticinin olası pigment listesidir; bu renkte hepsinin bulunduğu doğrulanmamıştır. Pigmentler kesin içerik eşleşmesine dahil edilmez.',
                              'Manufacturer list of possible pigments; not all are confirmed in this shade. Pigments are excluded from confirmed ingredient matching.')),
                        ],
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
              if (record?.mayContain.isNotEmpty == true)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(copy(
                        'Olası renk pigmentleri ürün kaynağı ayrıntılarında yer alır; ambalajla doğrulanmalıdır.',
                        'Possible colour pigments are shown in source details; confirm against the package.'))),
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

  Widget resultProductVisual() {
    final photo = photoPath;
    final imageUrl = productRecord?.imageUrl;
    final fallback = Container(
        color: const Color(0xFFE8E1D2),
        alignment: Alignment.center,
        child: Text(
            (productName ?? copy('Ürün', 'Product'))
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
                .join(),
            style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: NaviloColors.forest)));
    Widget localPhoto() => FutureBuilder<LocalProductStore>(
        future: localStore,
        builder: (context, snapshot) {
          final file = snapshot.data?.imageFor(activeLocalProduct!);
          return file != null && file.existsSync()
              ? Image.file(file, fit: BoxFit.cover)
              : fallback;
        });
    final Widget visual = photo != null
        ? Image.file(File(photo), fit: BoxFit.cover)
        : activeLocalProduct != null
            ? localPhoto()
            : imageUrl != null
                ? Image.network(imageUrl,
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
                : fallback;
    return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 68, height: 68, child: visual));
  }

  Widget resultDecisionHeader() {
    final found = matches!.isNotEmpty;
    final name = productName ?? copy('İçerik özeti', 'Ingredient summary');
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey('$name-$found'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: NaviloColors.forestDeep,
            borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            resultProductVisual(),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white, fontFamily: 'serif')),
                  const SizedBox(height: 5),
                  Text(
                      '${category == 'food' ? copy('Gıda', 'Food') : copy('Bakım ve kozmetik', 'Beauty & care')} · ${copy('Kontrol ettiğin metne göre', 'Based on the text you reviewed')}',
                      style: const TextStyle(
                          color: Color(0xFFD2DAD3), fontSize: 12)),
                ]))
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                  color:
                      found ? const Color(0xFFFFD36B) : const Color(0xFFE7E4DC),
                  borderRadius: BorderRadius.circular(9)),
              child: Text(
                  found
                      ? '${matches!.length} ${copy('eşleşme bulundu', 'match${matches!.length == 1 ? '' : 'es'} found')}'
                      : copy('Listede eşleşme yok · güvenlik onayı değildir',
                          'No list match · this is not a safety approval'),
                  style: TextStyle(
                      color: found ? NaviloColors.ink : const Color(0xFF454B47),
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          )
        ]),
      ),
    );
  }

  Widget ingredientEvidence() => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18, bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFFF0EBDD),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(copy('OKUNAN İÇERİK METNİ', 'READ INGREDIENT TEXT'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: NaviloColors.muted,
                letterSpacing: .9,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SelectableText.rich(TextSpan(
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NaviloColors.ink),
            children: highlightedIngredientSpans())),
        if (matches!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
              copy('Sarı vurgular eşleşen kelimelerdir.',
                  'Yellow highlights show the matched words.'),
              style: Theme.of(context).textTheme.bodySmall)
        ]
      ]));

  Widget resultScreen(Policy data) => pageList([
        resultDecisionHeader(),
        const SizedBox(height: 18),
        resultRow(
            copy('Kaçınılan içerikler', 'Avoided ingredients'),
            matches!.isEmpty
                ? tr('Listemizdeki madde tespit edilmedi')
                : copy('Listemizdeki madde tespit edildi',
                    'Listed ingredients detected'),
            matches!.map((r) => english ? r.englishName : r.name).toList(),
            warning: matches!.isNotEmpty),
        if (matches!.isNotEmpty) ingredientEvidence(),
        if (matches!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(copy('Neden dikkat edilmeli?', 'Why pay attention?'),
              style: Theme.of(context).textTheme.titleMedium),
          for (final rule in matches!)
            IngredientExplanation(
                rule: rule, english: english, ingredientText: label.text),
        ],
        if (category == 'food') dietaryPanel(),
        if (category == 'cosmetic') skinFitCard(label.text, reviewed: complete),
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
    const swatches = [
      Color(0xFFE8D7B5),
      Color(0xFFD7E1D3),
      Color(0xFFE6CFC4),
      Color(0xFFD6DBE5),
      Color(0xFFE6DEBE),
    ];
    final hash =
        product.name.runes.fold<int>(17, (value, rune) => value * 31 + rune);
    final initials = product.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final fallback = Container(
        color: swatches[hash.abs() % swatches.length],
        alignment: Alignment.center,
        child: Text(initials.isEmpty ? 'N' : initials,
            style: TextStyle(
                fontFamily: 'serif',
                fontSize: size * .31,
                fontWeight: FontWeight.w700,
                color: NaviloColors.forestDeep)));
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
                      ? (Uri.tryParse(product.remoteImageUrl ?? '')?.scheme !=
                              'https'
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

  Widget libraryTabs() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Center(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                    textStyle:
                        const TextStyle(fontFamily: 'sans-serif', fontSize: 12),
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: 0, label: Text(copy('Ürünlerim', 'My products'))),
                  ButtonSegment(
                      value: 1, label: Text(copy('Katalog', 'Catalogue'))),
                  ButtonSegment(
                      value: 2, label: Text(copy('Katkı', 'Contribute'))),
                ],
                selected: {libraryTab},
                onSelectionChanged: (values) =>
                    setState(() => libraryTab = values.first),
              ))));

  Widget catalogueThumbnail(ProductRecord product, {double size = 64}) {
    final fallback = Container(
        color: NaviloColors.line,
        alignment: Alignment.center,
        child: Text(
            product.name.isEmpty
                ? 'N'
                : product.name.characters.first.toUpperCase(),
            style:
                TextStyle(fontSize: size * .32, color: NaviloColors.forest)));
    final image = product.imageUrl;
    return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
            width: size,
            height: size,
            child: image == null
                ? fallback
                : Image.network(image,
                    fit: BoxFit.contain,
                    semanticLabel: product.name,
                    cacheWidth:
                        (size * MediaQuery.devicePixelRatioOf(context)).round(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : fallback,
                    errorBuilder: (_, error, stack) => fallback)));
  }

  Future<void> showCatalogueProduct(ProductRecord product) async {
    final selectedCategory = catalogueCategory;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => FractionallySizedBox(
            heightFactor: .88,
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Center(child: catalogueThumbnail(product, size: 180)),
                      if (product.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        Text(product.imageCredit,
                            style: Theme.of(context).textTheme.bodySmall),
                        if (product.imageCredit.contains('CC BY-SA'))
                          const SelectableText(
                              'https://creativecommons.org/licenses/by-sa/3.0/'),
                        SelectableText(product.imageSourceUrl ?? ''),
                      ],
                      const SizedBox(height: 8),
                      SelectableText(
                          '${copy('Barkod', 'Barcode')}: ${product.code}'),
                      const SizedBox(height: 20),
                      Text(copy('İçindekiler', 'Ingredients'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SelectableText(product.ingredients),
                      if (product.mayContain.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(copy('İçerebilir · renk pigmentleri',
                            'May contain · colour pigments')),
                        SelectableText(product.mayContain),
                      ],
                      const Divider(height: 32),
                      Text(product.sourceName),
                      SelectableText(product.sourceUrl),
                      if (product.modified != null)
                        Text(
                            '${copy('Kaynak kontrol tarihi', 'Source checked')}: ${dateLabel(product.modified!)}'),
                      const SizedBox(height: 16),
                      Text(copy(
                          'Güncel ambalajdaki içerikle karşılaştırarak değerlendir.',
                          'Compare with the current package before assessing.')),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              resetProduct();
                              category = selectedCategory;
                              page = 0;
                              activeBarcode = product.code;
                              productRecord = product;
                              productName = product.name;
                              label.text = product.ingredients;
                              ingredientSectionDetected = true;
                              stage = ScanStage.review;
                            });
                          },
                          icon: const Icon(Icons.fact_check_outlined),
                          label: Text(copy('İçeriği kontrol et ve değerlendir',
                              'Review and assess ingredients'))),
                    ]))));
  }

  Widget catalogueScreen() => FutureBuilder<List<ProductRecord>>(
      future: catalogueProducts,
      builder: (context, snapshot) {
        final query = normalize(catalogueQuery);
        final records = (snapshot.data ?? <ProductRecord>[])
            .where((p) =>
                query.isEmpty ||
                normalize(p.name).contains(query) ||
                p.code.contains(query))
            .toList();
        return CustomScrollView(slivers: [
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(copy('Ürün kataloğu', 'Product catalogue'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(copy(
                        'Kaynaklardan eklediğimiz ürünler. İnternet olmadan da görüntülenir.',
                        'Products added from sources. Available offline too.')),
                    const SizedBox(height: 16),
                    TextField(
                        onChanged: (value) =>
                            setState(() => catalogueQuery = value),
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            labelText: copy('Katalogda ürün veya barkod ara',
                                'Search catalogue by product or barcode'))),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      for (final item in [
                        ('food', copy('Gıda', 'Food')),
                        ('cosmetic', copy('Kozmetik', 'Cosmetics'))
                      ])
                        ChoiceChip(
                            showCheckmark: false,
                            label: Text(item.$2),
                            selected: catalogueCategory == item.$1,
                            onSelected: (_) => setState(() {
                                  catalogueCategory = item.$1;
                                  catalogueProducts = ProductRepository()
                                      .listCurated(category: item.$1);
                                })),
                    ]),
                    const SizedBox(height: 8),
                    if (snapshot.hasData)
                      Text(copy('${records.length} ürün',
                          '${records.length} products')),
                  ]))),
          if (snapshot.hasError)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(copy(
                        'Katalog yüklenemedi.', 'Could not load catalogue.'))))
          else if (!snapshot.hasData)
            const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()))
          else if (records.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(copy('Aramana uygun ürün bulunamadı.',
                        'No matching products.'))))
          else
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) return const Divider(height: 1);
                  final product = records[index ~/ 2];
                  return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: catalogueThumbnail(product),
                      title: Text(product.name,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(product.code),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showCatalogueProduct(product));
                }, childCount: records.length * 2 - 1))),
        ]);
      });

  void openContribution(Map<String, dynamic> candidate) {
    final saved =
        libraryProducts.where((p) => p.id == candidate['id']).firstOrNull;
    if (saved != null) {
      openSaved(saved);
      setState(() => contributing = true);
      return;
    }
    setState(() {
      resetProduct();
      contributing = true;
      activeLocalId = candidate['id'] as String;
      category = candidate['category'] as String;
      productName = candidate['name'] as String;
      page = 0;
      stage = ScanStage.review;
    });
  }

  Widget contributionScreen() => FutureBuilder<List<dynamic>>(
      future: contributionCandidates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text(copy('Katkı listesi yüklenemedi.',
                  'Could not load contribution list.')));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.requireData
            .cast<Map<String, dynamic>>()
            .where((p) => normalize(p['name'] as String)
                .contains(normalize(contributionQuery)))
            .toList();
        final updatedRecords = records
            .where((candidate) =>
                libraryProducts.any((p) => p.id == candidate['id']))
            .toList();
        final pendingRecords = records
            .where((candidate) =>
                !libraryProducts.any((p) => p.id == candidate['id']))
            .toList();
        Widget candidateSection(
            String title, String subtitle, List<Map<String, dynamic>> items,
            {required bool updated}) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                for (final candidate in items) ...[
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(candidate['name'] as String),
                      subtitle: Text(updated
                          ? copy('Bu cihazda kaydedildi · Düzenle',
                              'Saved on this device · Edit')
                          : copy('Barkod ve içerik bekliyor',
                              'Needs barcode and ingredients')),
                      trailing: Icon(updated
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline),
                      onTap: () => openContribution(candidate)),
                  const Divider(height: 1),
                ],
              ]);
        }

        return pageList([
          Text(copy('Bir ürünle destek ol', 'Help with one product'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(copy(
              'Bu adayların ürün bilgileri doğrulanmadı. Elindeki ambalajdan barkod ve içerik ekleyebilirsin. Paylaşım, kaydederken ayrıca seçilir.',
              'These candidates are unverified. Add barcode and ingredients from your package. Sharing is a separate choice when saving.')),
          const SizedBox(height: 16),
          TextField(
              onChanged: (value) => setState(() => contributionQuery = value),
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: copy(
                      'Katkı listesinde ara', 'Search contribution list'))),
          const SizedBox(height: 12),
          Text(
              copy('${records.length} aday ürün',
                  '${records.length} product candidates'),
              style: Theme.of(context).textTheme.bodySmall),
          if (records.isEmpty)
            Text(copy('Eşleşen aday yok.', 'No matching candidates.')),
          candidateSection(
              copy('Güncellendi', 'Updated'),
              copy('Katkı bilgisi bu cihazda kaydedildi.',
                  'Contribution information is saved on this device.'),
              updatedRecords,
              updated: true),
          candidateSection(
              copy('İşlem yapılmadı', 'Not updated'),
              copy('Bu aday için henüz katkı yapılmadı.',
                  'No contribution has been made for this candidate yet.'),
              pendingRecords,
              updated: false),
        ]);
      });

  Widget libraryScreen(Policy data) {
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
      ...records.map((product) {
        final hasMatch =
            data.evaluate(product.ingredients, product.category).isNotEmpty;
        final key = ValueKey('library-${product.category}-${product.id}');
        return Dismissible(
            key: key,
            direction: DismissDirection.endToStart,
            background: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                    color: NaviloColors.warning,
                    borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete_outline, color: Colors.white)),
            onDismissed: (_) => deferLibraryDelete(product),
            child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                    onTap: () => openLibraryProduct(product),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          productThumbnail(product, size: 76),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    product.name.isEmpty
                                        ? copy(
                                            'Kaydedilen ürün', 'Saved product')
                                        : product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 7),
                                Row(children: [
                                  Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: hasMatch
                                              ? NaviloColors.warning
                                              : NaviloColors.uncertain,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: Text(
                                          hasMatch
                                              ? copy(
                                                  'Eşleşme var', 'List match')
                                              : copy('Listede eşleşme yok',
                                                  'No list match'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall)),
                                ]),
                              ])),
                          const Icon(Icons.chevron_right_rounded,
                              color: NaviloColors.muted),
                        ])))));
      }),
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

  void deferLibraryDelete(LocalProduct product) {
    var undone = false;
    setState(() {
      libraryProducts.removeWhere((item) => item.id == product.id);
      recentProducts.removeWhere((item) => item.id == product.id);
    });
    final messenger = ScaffoldMessenger.of(context);
    final controller = messenger.showSnackBar(SnackBar(
        content: Text(copy('Ürün silinmek üzere.', 'Product will be deleted.')),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
            label: copy('Geri al', 'Undo'),
            onPressed: () {
              undone = true;
              if (mounted) {
                setState(() {
                  if (!libraryProducts.any((item) => item.id == product.id)) {
                    libraryProducts.add(product);
                    libraryProducts
                        .sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
                  }
                  recentProducts = libraryProducts.take(5).toList();
                });
              }
            })));
    controller.closed.then((reason) async {
      if (undone || reason == SnackBarClosedReason.action) return;
      try {
        await (await localStore).remove(product.id, product.category);
        if (mounted) await refreshRecent();
      } catch (_) {
        if (mounted) {
          setState(() {
            if (!libraryProducts.any((item) => item.id == product.id)) {
              libraryProducts.add(product);
              libraryProducts
                  .sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
            }
            recentProducts = libraryProducts.take(5).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(copy('Ürün silinemedi.', 'Could not delete product.'))));
        }
      }
    });
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
                            '${Uri.tryParse(product.remoteImageUrl ?? "")?.host == "images.openfoodfacts.org" ? "Open Food Facts contributors · CC BY-SA 3.0\nhttps://creativecommons.org/licenses/by-sa/3.0/" : "Görsel kaynağı"}\n${product.imageSourceUrl ?? ""}'),
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
                      if (product.category == 'cosmetic')
                        skinFitCard(product.ingredients, reviewed: true),
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

  Future<void> showSkinTypeQuiz() async {
    final result = await Navigator.push<SkinTestResult>(
        context,
        MaterialPageRoute(
            builder: (_) => SkinTestScreen(
                english: english, persist: widget.persistSettings)));
    if (result == null || !mounted) return;
    setState(() {
      skinResult = result;
      skin = result.type.label;
    });
    await persistSettings();
  }

  Widget skinFitCard(String ingredients, {required bool reviewed}) {
    final profile = skinResult;
    if (profile == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.face_outlined),
        title: Text(copy('Cildine uygun mu?', 'Does it suit your skin?')),
        subtitle: Text(copy('9 soruluk testi tamamlayarak kişiselleştir.',
            'Personalize with the 9-question skin test.')),
        trailing: const Icon(Icons.chevron_right),
        onTap: showSkinTypeQuiz,
      );
    }
    final fit = SkinFitEvaluator.evaluate(
        ingredientsText: ingredients,
        skin: profile,
        complete: reviewed,
        english: english);
    final title = switch (fit.level) {
      FitLevel.good => copy('Uygun görünüyor', 'Looks suitable'),
      FitLevel.caution => copy('Dikkat gerektiriyor', 'Take care'),
      FitLevel.unknown => copy('Uygunluk belirsiz', 'Suitability unknown'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
            fit.level == FitLevel.caution
                ? Icons.warning_amber_rounded
                : fit.level == FitLevel.unknown
                    ? Icons.help_outline
                    : Icons.spa_outlined,
            color: fit.level == FitLevel.caution
                ? Colors.orange.shade800
                : NaviloColors.forest),
        title: Text(title),
        subtitle: Text(
            '${copy('Cilt eğilimin', 'Skin tendency')}: ${english ? profile.type.name : profile.type.label}${profile.isSensitive ? copy(' · Hassasiyet', ' · Sensitivity') : ''}'),
      ),
      ...fit.cautions.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 8), child: Text('• $text'))),
      ...fit.positives.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 8), child: Text('• $text'))),
      if (fit.level == FitLevel.unknown)
        Text(copy(
            'Yeterli içerik eşleşmesi veya kontrol edilmiş tam liste yok.',
            'There are insufficient ingredient matches or no reviewed complete list.')),
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title:
              Text(copy('Bu sonuç ne anlama geliyor?', 'What does this mean?')),
          children: [
            Text(copy(
                'Bu bir içerik eşleştirmesidir; ürünün tamamının güvenli veya etkili olduğunu doğrulamaz. Oranlar, formül, kullanım şekli ve kişisel tepki bilinmiyor. Test teşhis değildir. Kaynak: American Academy of Dermatology; kurallar v1, 12.10.2026.',
                'This is ingredient matching, not proof that the whole product is safe or effective. Concentrations, formulation, use and individual response are unknown. The test is not diagnostic. Source: American Academy of Dermatology; rules v1, 2026-10-12.'))
          ]),
    ]);
  }

  Widget skinTypeCard() {
    const options = [
      ('Kuru', Icons.water_drop_outlined),
      ('Yağlı', Icons.wb_sunny_outlined),
      ('Karma', Icons.blur_on_rounded),
      ('Normal', Icons.spa_outlined),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(copy('Cilt tipin', 'Your skin type'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      InkWell(
          onTap: showSkinTypeQuiz,
          borderRadius: BorderRadius.circular(16),
          child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: NaviloColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NaviloColors.line)),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.face_retouching_natural_outlined,
                      color: NaviloColors.forest),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          skin == 'Henüz seçilmedi'
                              ? copy('Cilt tipini keşfet',
                                  'Explore your skin type')
                              : '${copy('Cilt eğilimin', 'Skin tendency')}: ${tr(skin)}',
                          style: Theme.of(context).textTheme.titleMedium)),
                  const Icon(Icons.arrow_forward_rounded,
                      color: NaviloColors.muted),
                ]),
                const SizedBox(height: 12),
                Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    children: options.map((option) {
                      final selected = skin == option.$1;
                      return Column(children: [
                        CircleAvatar(
                            radius: 20,
                            backgroundColor: selected
                                ? const Color(0xFFE8D7B5)
                                : const Color(0xFFF0ECE2),
                            child: Icon(option.$2,
                                size: 19, color: NaviloColors.forest)),
                        const SizedBox(height: 4),
                        Text(tr(option.$1),
                            style: Theme.of(context).textTheme.labelSmall),
                      ]);
                    }).toList()),
              ]))),
      if (skinResult != null) ...[
        Text(
            '${copy('Son test', 'Last test')}: ${dateLabel(skinResult!.date)}${skinResult!.isSensitive ? copy(' · Hassasiyet notu var', ' · Sensitivity noted') : ''}'),
        TextButton(
            onPressed: () async {
              try {
                if (widget.persistSettings) await SkinTestStorage.clear();
                if (!mounted) return;
                setState(() {
                  skinResult = null;
                  skin = 'Henüz seçilmedi';
                });
                await persistSettings();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(copy('Cilt profili silinemedi.',
                          'Could not remove skin profile.'))));
                }
              }
            },
            child: Text(copy('Cilt sonucunu sil', 'Delete skin result'))),
      ],
      const SizedBox(height: 6),
      Text(
          copy('9 soruluk öz değerlendirmedir; tıbbi analiz değildir.',
              'A brief self-assessment, not a medical analysis.'),
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget preferenceChips(String title, List<String> values,
          {bool singleChoice = false}) =>
      Padding(
          padding: const EdgeInsets.only(top: 18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: NaviloColors.muted,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map((value) => FilterChip(
                        showCheckmark: false,
                        label: Text(tr(value)),
                        selected: preferences.contains(value),
                        onSelected: (selected) {
                          setState(() {
                            if (singleChoice) preferences.removeAll(values);
                            if (selected) {
                              preferences.add(value);
                            } else {
                              preferences.remove(value);
                            }
                          });
                          persistSettings();
                        }))
                    .toList()),
          ]));

  Widget profileScreen() => pageList([
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(copy('Kriterler', 'Criteria')),
            subtitle: Text(copy('İncelenen maddeler ve kaynaklar',
                'Ingredients and sources we check')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => page = 2)),
        const Divider(),
        skinTypeCard(),
        const SizedBox(height: 24),
        Text(copy('Beslenme tercihlerin', 'Dietary preferences'),
            style: Theme.of(context).textTheme.titleLarge),
        preferenceChips(
            copy('Diyet', 'Diet'), ['Vegan', 'Ketojenik', 'Az yağlı']),
        preferenceChips(copy('Hassasiyetler', 'Sensitivities'),
            ['Glutensiz', 'Laktozsuz', 'Düşük FODMAP']),
        preferenceChips(copy('Şeker tercihi', 'Sugar preference'),
            ['Şekersiz', 'İlave şekersiz', 'Rafine şekersiz'],
            singleChoice: true),
        const SizedBox(height: 20),
        Text(
            copy(
                'Tercihler bu sürümde ürün sonuçlarını veya önerileri değiştirmez. Sağlık tavsiyesi değildir.',
                'Preferences do not yet change product results or recommendations. This is not medical advice.'),
            style: Theme.of(context).textTheme.bodySmall),
        if (storageError != null) notice(storageError!, warning: true),
        const Divider(height: 32),
        Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(copy('Uygulama dili', 'App language'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                  textStyle:
                      const TextStyle(fontFamily: 'sans-serif', fontSize: 12),
                  minimumSize: const Size(84, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14)),
              segments: const [
                ButtonSegment(value: false, label: Text('Türkçe')),
                ButtonSegment(value: true, label: Text('English')),
              ],
              selected: {english},
              onSelectionChanged: (value) {
                setState(() => english = value.first);
                persistSettings();
              }),
        ])),
        const SizedBox(height: 20),
      ],
          title: copy('Profil ve ayarlar', 'Profile & settings'),
          subtitle: copy('Ürünleri kendi seçimlerine göre keşfet.',
              'Explore products with your own preferences.'));

  String criterionGroup(IngredientRule rule) {
    final id = rule.id.toLowerCase();
    if (id.contains('maltitol') || id.contains('sweetener')) {
      return 'sweeteners';
    }
    if (['oil', 'fat', 'palm', 'margarine', 'hydrogenated', 'trans']
        .any(id.contains)) {
      return 'oils';
    }
    return 'additives';
  }

  Widget criteriaScreen(Policy data) {
    final rules = data.rules.where((rule) {
      if (criteriaCategory != 'all' && rule.category != criteriaCategory) {
        return false;
      }
      final query = normalize(criteriaQuery);
      return query.isEmpty ||
          normalize(
                  '${rule.name} ${rule.englishName} ${rule.aliases.join(' ')}')
              .contains(query);
    }).toList();
    final groups = [
      ('sweeteners', copy('Tatlandırıcılar', 'Sweeteners')),
      ('oils', copy('Yağlar', 'Oils and fats')),
      ('additives', copy('Katkılar ve diğerleri', 'Additives and others')),
    ];
    final visibleGroups = groups
        .map((group) => (
              group.$2,
              rules.where((rule) => criterionGroup(rule) == group.$1).toList()
            ))
        .where((group) => group.$2.isNotEmpty)
        .toList();
    return pageList([
      Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: NaviloColors.muted),
        const SizedBox(width: 6),
        Expanded(
            child: Text(
                copy('Taslak liste · uzman incelemesi bekliyor',
                    'Draft list · pending expert review'),
                style: Theme.of(context).textTheme.bodySmall)),
      ]),
      const SizedBox(height: 14),
      TextField(
          onChanged: (value) => setState(() => criteriaQuery = value),
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText:
                  copy('Madde veya eş anlam ara', 'Search ingredients'))),
      const SizedBox(height: 12),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final filter in [
              ('all', copy('Tümü', 'All')),
              ('food', copy('Gıda', 'Food')),
              ('cosmetic', copy('Kozmetik', 'Cosmetics')),
            ])
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text(filter.$2),
                      selected: criteriaCategory == filter.$1,
                      onSelected: (_) =>
                          setState(() => criteriaCategory = filter.$1))),
          ])),
      const SizedBox(height: 12),
      Text(copy('${rules.length} madde', '${rules.length} ingredients'),
          style: Theme.of(context).textTheme.bodySmall),
      for (final group in visibleGroups) ...[
        const SizedBox(height: 16),
        Text(group.$1.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: NaviloColors.muted,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700)),
        for (final rule in group.$2)
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(english ? rule.englishName : rule.name),
              subtitle: Text(rule.category == 'food'
                  ? copy('Gıda', 'Food')
                  : copy('Bakım ve kozmetik', 'Beauty & care')),
              children: [
                IngredientExplanation(rule: rule, english: english),
                Padding(
                    padding: const EdgeInsets.only(bottom: 16, right: 12),
                    child: SelectableText(rule.aliases.join(', ')))
              ]),
      ],
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(copy('Beslenme kaynakları', 'Dietary references')),
          children: [dietaryPanel(reference: true)]),
    ],
        title: copy('Neye bakıyoruz?', 'What do we check?'),
        subtitle: copy('Kaçınılan içerikler ve kullanılan kaynaklar.',
            'Avoided ingredients and reference sources.'));
  }

  Widget navigationItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Expanded(
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon,
                        size: 22,
                        color: selected
                            ? NaviloColors.forest
                            : NaviloColors.muted),
                    const SizedBox(height: 3),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? NaviloColors.forest
                                : NaviloColors.muted)),
                  ]))));

  Widget scanNavigationItem() => Expanded(
      child: Semantics(
          button: true,
          label: copy('Ana sayfa', 'Home'),
          child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() {
                    page = 0;
                    stage = ScanStage.start;
                  }),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 43,
                        height: 38,
                        decoration: BoxDecoration(
                            color: NaviloColors.forest,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.center_focus_strong_rounded,
                            color: Colors.white, size: 21)),
                    const SizedBox(height: 3),
                    Text(copy('Ana sayfa', 'Home'),
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ])))));

  Widget naviloBottomBar() => SafeArea(
      top: false,
      child: Container(
          height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 112 : 68,
          decoration: const BoxDecoration(
              color: NaviloColors.paper,
              border: Border(top: BorderSide(color: NaviloColors.line))),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            navigationItem(
                icon: Icons.bookmarks_outlined,
                label: copy('Kütüphane', 'Library'),
                selected: page == 3,
                onTap: () => setState(() => page = 3)),
            scanNavigationItem(),
            navigationItem(
                icon: Icons.tune_rounded,
                label: copy('Profilim', 'Profile'),
                selected: page == 1 || page == 2,
                onTap: () => setState(() => page = 1)),
          ])));

  @override
  Widget build(BuildContext context) => PopScope(
        canPop:
            page != 2 && (stage == ScanStage.start || page != 0 || onboarding),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !reading) {
            if (page == 2) {
              setState(() => page = 1);
            } else {
              backStep();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: page == 2
                ? IconButton(
                    tooltip: copy('Profile dön', 'Back to profile'),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => page = 1))
                : page == 0 && stage != ScanStage.start && !onboarding
                    ? IconButton(
                        tooltip: copy('Geri', 'Back'),
                        icon: const Icon(Icons.arrow_back),
                        onPressed: reading ? null : backStep)
                    : null,
            title: const NaviloWordmark(),
            actions: const [],
          ),
          bottomNavigationBar:
              onboarding || stage != ScanStage.start ? null : naviloBottomBar(),
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
                              padding: const EdgeInsets.all(24),
                              child: barcodeSearching
                                  ? lookupProgress()
                                  : Column(
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
                                if (page == 3) {
                                  return Column(children: [
                                    libraryTabs(),
                                    Expanded(
                                        child: switch (libraryTab) {
                                      1 => catalogueScreen(),
                                      2 => contributionScreen(),
                                      _ => libraryScreen(data),
                                    }),
                                  ]);
                                }
                                return switch (stage) {
                                  ScanStage.start => homeScreen(),
                                  ScanStage.review => reviewScreen(data),
                                  ScanStage.result => resultScreen(data)
                                };
                              })),
        ),
      );
}
