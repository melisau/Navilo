part of '../main.dart';

// Ayarlar, açılış, son ürünler ve sayfa geçişleri.
extension _AppFlow on _HomePageState {
  Future<void> loadSkinProfile() async {
    if (!widget.persistSettings) return;
    try {
      final result = await SkinTestStorage.load();
      if (mounted) {
        _update(() {
          skinResult = result;
          if (result != null) skin = result.type.label;
        });
      }
    } catch (_) {
      if (mounted) {
        _update(() => storageError = copy(
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
      _update(() {
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
        _update(() => storageError = copy(
            'Yerel kayıtlar yüklenemedi. Tarama yapabilirsin; kayıtlar için uygulamayı yeniden açmayı dene.',
            'Local records could not load. You can still scan; try reopening to access saved records.'));
      }
    } finally {
      if (mounted) _update(() => loadingSettings = false);
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
        _update(() => storageError = copy(
            'Tercihler kaydedilemedi. Bu oturumda kullanabilirsin.',
            'Preferences could not be saved. They remain available in this session.'));
      }
    }
  }

  void finishOnboarding({bool profile = false}) {
    _update(() {
      onboarding = false;
      page = profile ? 1 : 0;
    });
    persistSettings();
  }

  Future<void> refreshRecent() async {
    try {
      final recent = await (await localStore).recent(limit: null);
      if (mounted) {
        _update(() {
          libraryProducts = recent;
          recentProducts = recent.take(5).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        _update(() => storageError = copy(
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
        _update(() => storageError = copy(
            '$failed ürün internet bağlantısı bekliyor; bağlantı gelince tekrar eşitlenecek.',
            '$failed product contribution(s) are waiting for internet and will retry automatically.'));
      }
    } on FormatException {
      if (mounted) {
        _update(() => storageError = copy(
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
    reviewedNutrition = null;
    nutritionDraft = {};
    editingNutrition = false;
    scanError = null;
    matches = null;
    complete = false;
    editingReview = false;
    ingredientSectionDetected = false;
    stage = ScanStage.start;
  }

  void goHome() {
    FocusScope.of(context).unfocus();
    _update(() {
      resetProduct();
      page = 0;
    });
  }

  void backStep() {
    FocusScope.of(context).unfocus();
    _update(() =>
        stage = stage == ScanStage.result ? ScanStage.review : ScanStage.start);
  }
}
