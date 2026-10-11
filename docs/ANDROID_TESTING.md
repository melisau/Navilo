# Android phone testing

1. Enable Developer options on the phone (usually Settings → About phone → tap Build number seven times).
2. Enable USB debugging, connect a data-capable USB cable, unlock the phone, and approve this computer's RSA prompt.
3. From PowerShell:

```powershell
cd "C:\Users\melisa uyar\Desktop\Navilo"
C:\flutter\bin\flutter.bat devices
C:\flutter\bin\flutter.bat run -d <phone-device-id>
```

Choose the physical phone ID, not emulator-5554. If it shows unauthorized, approve the prompt on the phone. If absent, check the data cable, USB mode and manufacturer Windows USB driver. The phone needs internet for barcode lookup. Camera/OCR processes label images locally.

## APK option

```powershell
C:\flutter\bin\flutter.bat build apk --debug
```

Install `build/app/outputs/flutter-apk/app-debug.apk` on the phone. A debug APK is for testing, not store distribution. Enable installation from the specific app used to open this file if Android requests it.

## Test checklist

- Known food barcode: product, original ingredients, source URL, date and separate allergen/trace/claim fields appear.
- Unknown product, no ingredients, no internet: fallback message and camera/gallery controls remain available.
- Photograph a complete ingredient panel: review the extracted text; a heading alone must not certify completeness.
- Scan a second product: previous photo/product data must not remain in the result.
- Lactose-free product with wheat: wheat reference must remain visible.
- Negative claim plus an actual listed ingredient: positive occurrence must not be hidden.
- Switch EN/TR and retry; permission refusal and cancellation must leave the screen usable.

For pilot coverage collect 30–50 products. Record barcode, country, API presence, agreement with packaging, missing ingredients, OCR errors, and incorrect/missed flags. Do not record personal health data in this dataset.

## Current limitations

No fuzzy auto-correction. No production taxonomy synchronization, persistent cache, serving-specific FODMAP provider, or guaranteed complete OCR. Product source tags are shown as evidence; they are not automatically certified conclusions. Open Food Facts is community data under ODbL; attribution and reuse obligations apply. Food lookup does not cover cosmetic barcode databases yet.
