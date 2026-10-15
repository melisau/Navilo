part of '../main.dart';

// Karşılama ve ana sayfa ekranları.
extension _HomeScreen on _HomePageState {
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
                  _update(resetProduct);
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
                          if (scanError == null) _update(resetProduct);
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
                          if (scanError == null) _update(resetProduct);
                          scanPhoto(ImageSource.gallery);
                        },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(copy('Galeriden ekle', 'Choose a photo')))),
        ]),
        if (label.text.isNotEmpty)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: () => _update(() => stage = ScanStage.review),
                  icon: const Icon(Icons.arrow_forward),
                  label:
                      Text(copy('Açık ürüne devam et', 'Continue product')))),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(
              child: Text(copy('Son baktıkların', 'Recently viewed'),
                  style: Theme.of(context).textTheme.titleLarge)),
          TextButton(
              onPressed: () => _update(() => page = 3),
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
}
