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
import 'domain/allergens.dart';
import 'domain/barcode.dart';
import 'domain/dietary_analysis.dart';
import 'domain/nutrition.dart';
import 'domain/preference_fit.dart';
import 'data/community_submission.dart';
import 'theme/navilo_theme.dart';

part 'home/app_flow.dart';
part 'home/barcode_scanner_page.dart';
part 'home/bottom_bar.dart';
part 'home/capture_actions.dart';
part 'home/catalogue_screen.dart';
part 'home/common_widgets.dart';
part 'home/contribution_screen.dart';
part 'home/criteria_screen.dart';
part 'home/dietary_panel.dart';
part 'home/home_screen.dart';
part 'home/library_screen.dart';
part 'home/nutrition_review.dart';
part 'home/product_lookup.dart';
part 'home/profile_screen.dart';
part 'home/result_screen.dart';
part 'home/review_screen.dart';

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
  late final Future<List<VeganEntry>> veganEntries = rootBundle
      .loadString('assets/vegan.json')
      .then(VeganEntry.decodeAll);
  late final Future<List<AllergenEntry>> allergenEntries = rootBundle
      .loadString('assets/allergens.json')
      .then(AllergenEntry.decodeAll);
  late final Future<PreferenceReference> preferenceReference = Future.wait(
          [dietary, veganEntries, allergenEntries])
      .then((values) => PreferenceReference(
          ((values[0] as Map<String, dynamic>)['entries'] as List)
              .map((e) => DietaryEntry(e as Map<String, dynamic>))
              .toList(),
          values[1] as List<VeganEntry>,
          allergens: values[2] as List<AllergenEntry>));
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
  bool hideConflicting = false;
  final Map<String, List<PreferenceVerdict>> catalogueConflictCache = {};
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
  String rawOcrText = '';
  // Nutrition values the user checked on the review screen, valid only for
  // the label text and product they were checked against.
  NutritionFacts? reviewedNutrition;
  String reviewedNutritionFor = '';
  Map<String, String> nutritionDraft = {};
  String nutritionDraftFor = '';
  bool editingNutrition = false;
  late final Future<AppSettingsStore> settingsStore =
      localStore.then((store) => AppSettingsStore(store.directory.parent));

  /// Part dosyalarındaki extension'lar `setState`'i doğrudan çağıramaz
  /// (protected üye), bu yüzden bu küçük köprüyü kullanırlar.
  void _update(VoidCallback fn) => setState(fn);

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    label.dispose();
    super.dispose();
  }

  String copy(String turkish, String en) => english ? en : turkish;

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
