part of '../main.dart';

// Ürün adına göre arama, web araştırması ve kayıtlı ürünü açma/silme.
extension _ProductLookup on _HomePageState {
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
    _update(() {
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
    _update(() {
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
        _update(() => scanError = copy(
            'Bu adla içerik listesi bulunan aday ürün yok. Etiket fotoğrafı ekleyebilirsin.',
            'No candidates with ingredient lists were found. You can add a label photo.'));
      } else {
        final selected = await chooseNameMatch(candidates);
        if (selected != null) await applyNameMatch(selected);
      }
    } catch (_) {
      if (mounted) {
        _update(() => scanError = copy(
            'Ürün adı aranamadı. Bağlantıyı kontrol et veya etiketi fotoğrafla ekle.',
            'Could not search that product name. Check your connection or add a label photo.'));
      }
    } finally {
      if (mounted) {
        _update(() {
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
        _update(() => scanError = copy(
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
        _update(() => scanError = copy(
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
    _update(() {
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
    _update(() {
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
      debugPrint('NAVILO-DEBUG openSaved nutrition=${product.nutrition?.count}');
      if (product.nutrition != null) {
        reviewedNutrition = product.nutrition;
        reviewedNutritionFor = nutritionKey;
      }
      stage = ScanStage.review;
    });
  }

  Future<void> deleteSavedProduct() async {
    final code = activeLocalId ?? activeBarcode;
    if (code == null) return;
    try {
      await (await localStore).remove(code, category);
      if (!mounted) return;
      _update(() => localReviewDate = null);
      await refreshRecent();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(copy('Kayıt silinemedi. Tekrar dene.',
                'Could not delete the record. Please retry.'))));
      }
    }
  }
}
