part of '../main.dart';

// Topluluk katkısı ekranı.
extension _ContributionScreen on _HomePageState {
  void openContribution(Map<String, dynamic> candidate) {
    final saved =
        libraryProducts.where((p) => p.id == candidate['id']).firstOrNull;
    if (saved != null) {
      openSaved(saved);
      _update(() => contributing = true);
      return;
    }
    _update(() {
      resetProduct();
      contributing = true;
      activeLocalId = candidate['id'] as String;
      category = candidate['category'] as String;
      productName = candidate['name'] as String;
      // Open Facts knows the barcode; the user confirms it on the package.
      final barcode = candidate['candidate_barcode'];
      if (barcode is String && isValidGtin(barcode)) activeBarcode = barcode;
      page = 0;
      stage = ScanStage.review;
    });
  }

  Widget contributionScreen() => FutureBuilder<List<dynamic>>(
      future: contributionCandidates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text(copy('Katkı listesi yüklenemedi.',
                  'Could not load contribution list.')));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.requireData
            .cast<Map<String, dynamic>>()
            .where((p) => normalize(p['name'] as String)
                .contains(normalize(contributionQuery)))
            .toList();
        final updatedRecords = records
            .where((candidate) =>
                libraryProducts.any((p) => p.id == candidate['id']))
            .toList();
        final pendingRecords = records
            .where((candidate) =>
                !libraryProducts.any((p) => p.id == candidate['id']))
            .toList();
        Widget candidateSection(
            String title, String subtitle, List<Map<String, dynamic>> items,
            {required bool updated}) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                for (final candidate in items) ...[
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(candidate['name'] as String),
                      subtitle: Text(updated
                          ? copy('Bu cihazda kaydedildi · Düzenle',
                              'Saved on this device · Edit')
                          : candidate['candidate_barcode'] is String
                              ? copy(
                                  'Barkod ${candidate['candidate_barcode']} · içerik bekliyor${candidate['source_name'] is String ? ' · ${candidate['source_name']}' : ''}',
                                  'Barcode ${candidate['candidate_barcode']} · needs ingredients')
                              : copy('Barkod ve içerik bekliyor',
                                  'Needs barcode and ingredients')),
                      trailing: Icon(updated
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline),
                      onTap: () => openContribution(candidate)),
                  const Divider(height: 1),
                ],
              ]);
        }

        return pageList([
          Text(copy('Bir ürünle destek ol', 'Help with one product'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(copy(
              'Bu adayların ürün bilgileri doğrulanmadı. Elindeki ambalajdan barkod ve içerik ekleyebilirsin. Paylaşım, kaydederken ayrıca seçilir.',
              'These candidates are unverified. Add barcode and ingredients from your package. Sharing is a separate choice when saving.')),
          const SizedBox(height: 16),
          TextField(
              onChanged: (value) => _update(() => contributionQuery = value),
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: copy(
                      'Katkı listesinde ara', 'Search contribution list'))),
          const SizedBox(height: 12),
          Text(
              copy('${records.length} aday ürün',
                  '${records.length} product candidates'),
              style: Theme.of(context).textTheme.bodySmall),
          if (records.isEmpty)
            Text(copy('Eşleşen aday yok.', 'No matching candidates.')),
          candidateSection(
              copy('Güncellendi', 'Updated'),
              copy('Katkı bilgisi bu cihazda kaydedildi.',
                  'Contribution information is saved on this device.'),
              updatedRecords,
              updated: true),
          candidateSection(
              copy('İşlem yapılmadı', 'Not updated'),
              copy('Bu aday için henüz katkı yapılmadı.',
                  'No contribution has been made for this candidate yet.'),
              pendingRecords,
              updated: false),
        ]);
      });
}
