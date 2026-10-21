part of '../main.dart';

// Sonuç ekranı ve kaynak bilgisi.
extension _ResultScreen on _HomePageState {
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
            onPressed: () => _update(() => stage = ScanStage.review),
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
}
