# Photo review and local product records

Implemented 2026-10-11 for Android/iOS:

1. Scan a barcode. A reviewed local record for this barcode/category is checked before the online provider; it works without an internet request.
2. If online ingredients are missing, use the camera/gallery buttons while the linked barcode remains visible. For a different product, unlink the barcode or scan the new barcode first.
3. The crop/rotate editor opens before ML Kit recognition. Select the complete list; cancellation keeps the previous result. Additional camera or gallery images can be added for long, curved or split labels; each image is cropped and OCR'd separately, then combined in order.
4. The cropped photos and original OCR text remain visible. Heading detection is not proof of completeness. Very short OCR output, unbalanced parentheses and replacement characters are review warnings and prevent confirming/saving.
5. Review the extracted text and confirm completeness. Editing text resets the confirmation. There is no automatic ingredient-name guessing or medical classification.
6. Save the reviewed product with explicit barcode association confirmation. Records contain original reviewed text, category and review timestamp; they are local to the app documents directory, not uploaded. Only reviewed text is stored, not temporary photos or OCR diagnostics.
7. Rescanning recalls the record and re-evaluates it with the current policy. Packaging must be checked again before confirming; formulas can change. Saved records can be deleted or replaced. Uninstalling/removing app data removes records.

## Verification

`dart run tool/check_local_flow.dart` exercises persistence after reopening the store, category isolation, overwrite/delete, invalid input rejection, Turkish uppercase heading detection, partial-text warnings and line-wrapped ingredient matching. Static analysis is also required. Native crop/camera behavior and OCR accuracy must still be tested on the physical phone; synthetic text tests do not establish photo recognition accuracy.

OCR deliberately applies only typography-safe cleanup: whitespace normalization, soft-hyphen removal and line-break hyphen joining. It does not guess ingredient names. Low light, glare and curved packaging should be captured as multiple close crops; the review screen keeps every crop visible so the user can compare the combined text with the package.

## Phone acceptance checks

- Cancel crop: previous result remains unchanged.
- Hazelnut spread photo: after crop, milk powder and chicory should survive extraction and produce review flags if OCR reads them correctly.
- Flour: include the entire last line. No FODMAP match is not a low-FODMAP classification.
- Save only after confirming the barcode and complete text. Close/reopen the app, disable internet, and rescan that barcode; the local record and review date should appear.
- Edit recalled text: confirmation must clear; overwrite only after review.
- Switch food/cosmetic: previous barcode and scan state must clear.
- Delete the local record; next scan should use the online provider again.
