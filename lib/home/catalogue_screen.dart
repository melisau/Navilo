part of '../main.dart';

// Seçilmiş ürün kataloğu.
extension _CatalogueScreen on _HomePageState {
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
                            _update(() {
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
                            _update(() => catalogueQuery = value),
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
                            onSelected: (_) => _update(() {
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
}
