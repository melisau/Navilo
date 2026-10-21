part of '../main.dart';

// Cihazdaki ürün kütüphanesi.
extension _LibraryScreen on _HomePageState {
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
                    _update(() => libraryTab = values.first),
              ))));

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
          onChanged: (value) => _update(() => libraryQuery = value),
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
              onSelected: (_) => _update(() => libraryCategory = item.$1))
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
    _update(() {
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
                _update(() {
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
          _update(() {
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
        _update(resetProduct);
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
}
