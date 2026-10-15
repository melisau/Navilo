part of '../main.dart';

// Ekranlar arasında paylaşılan küçük yapı taşları.
extension _CommonWidgets on _HomePageState {
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
              : (value) => _update(() {
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
                      _update(resetProduct);
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
                    if (!retry && scanError == null) _update(resetProduct);
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
                    if (!retry && scanError == null) _update(resetProduct);
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
}
