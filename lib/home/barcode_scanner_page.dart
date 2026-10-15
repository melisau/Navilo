part of '../main.dart';

class BarcodeScannerPage extends StatefulWidget {
  final bool english;
  const BarcodeScannerPage({super.key, this.english = false});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool handled = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.english ? 'Scan barcode' : 'Barkod okut')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                  widget.english
                      ? 'Place the barcode in the camera view. It will be read automatically.'
                      : 'Barkodu kamera görüntüsüne al. Otomatik olarak okunacak.',
                  style: const TextStyle(fontSize: 17))),
          Expanded(child: MobileScanner(
            onDetect: (capture) {
              if (handled) return;
              final barcode = capture.barcodes
                  .map((item) => item.rawValue)
                  .whereType<String>()
                  .firstWhere((value) => RegExp(r'^\d{8,14}$').hasMatch(value),
                      orElse: () => '');
              if (barcode.isEmpty) return;
              handled = true;
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(barcode);
            },
          ))
        ]),
      );
}
