part of '../main.dart';

// OCR / içerik metni inceleme ekranı.
extension _ReviewScreen on _HomePageState {
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
          onChanged: (_) => _update(() {
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
            onPressed: () => _update(() => editingReview = true),
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
      if (category == 'food') nutritionReview(),
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
                        : (value) => _update(() {
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
                  _update(() {
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
}
