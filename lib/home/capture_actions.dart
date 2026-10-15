part of '../main.dart';

// Barkod okutma, fotoğraf/OCR ve incelenen ürünü kaydetme.
extension _CaptureActions on _HomePageState {
  Future<void> linkBarcode() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(english: english)));
    if (!mounted || code == null || !RegExp(r'^\d{8,14}$').hasMatch(code)) {
      return;
    }
    _update(() {
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
    _update(() => reading = true);
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
      _update(() {
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
        _update(() => scanError = english
            ? 'Could not save. Please retry.'
            : 'Kayıt yapılamadı. Tekrar dene.');
      }
    } finally {
      if (mounted) _update(() => reading = false);
    }
  }

  Future<void> scanBarcode() async {
    if (reading) return;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => BarcodeScannerPage(english: english)),
    );
    if (barcode == null || barcode.isEmpty || !mounted) return;

    _update(() {
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
        _update(() {
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
      if (mounted) _update(() => lookupStep = 1);
      final product = await ProductRepository().find(barcode,
          english: english, category: category, onProgress: (step) {
        if (mounted) _update(() => lookupStep = step);
      });
      final loadedPolicy = await policy;
      if (!mounted) return;
      _update(() {
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
        _update(() {
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
        if (mounted) _update(() => searchingNameMatches = false);
      }
    } on FormatException {
      if (mounted) {
        _update(() {
          scanError = english
              ? 'Product or ingredients unavailable. Take a label photo below.'
              : 'Ürün veya içerik bilgisi bulunamadı. Aşağıdan etiket fotoğrafı çek veya ekle.';
          editingReview = true;
          stage = ScanStage.review;
        });
      }
    } on SocketException {
      if (mounted) {
        _update(() {
          scanError =
              'Ürün verisine erişilemedi. İnternet bağlantısını kontrol et.';
          editingReview = true;
          stage = ScanStage.review;
        });
      }
    } catch (_) {
      if (mounted) {
        _update(() {
          scanError = 'Barkod ürünü getirilemedi. Tekrar dene.';
          editingReview = true;
          stage = ScanStage.review;
        });
      }
    } finally {
      if (mounted) {
        _update(() {
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

    _update(() {
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
      _update(() {
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

      _update(() {
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
        _update(() => scanError =
            'Fotoğrafa erişilemedi veya yazı okunamadı. Kamera/galeri iznini kontrol edip tekrar dene.');
      }
    } catch (_) {
      if (mounted) {
        _update(() => scanError =
            'Fotoğraf işlenemedi. Başka bir fotoğrafla tekrar dene.');
      }
    } finally {
      await recognizer?.close();
      if (mounted) _update(() => reading = false);
    }
  }

  Future<void> scanAdditionalPhoto(ImageSource source) async {
    await scanPhoto(source, append: true);
  }

  String _extractIngredientText(String text) {
    final parsed = IngredientText.parse(text);
    rawOcrText = parsed.raw;
    ingredientSectionDetected = parsed.headingFound;
    return parsed.ingredients;
  }
}
