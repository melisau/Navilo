import unittest
from tool.catalog_validation import preferred_reviewed, validate_reviewed_record
from tool.import_verified_catalogue import partition

def row(**changes):
    value = dict(code='036000291452', name='Sample', ingredients='Water', category='food',
        catalog_batch='test', checked_at='2026-10-12T00:00:00Z',
        source_type='retailer', source_url='https://example.org/product',
        verified_at='2026-10-12T00:00:00Z', status='verified',
        ingredient_evidence='full_label_transcription',
        field_sources={k: ['https://example.org/product'] for k in ['code','name','ingredients']})
    value.update(changes)
    return value

class SourceReviewTests(unittest.TestCase):
    def test_unresolved_sources_cannot_be_reimported_as_verified(self):
        for code in ['8697471727219','8691520104198','8696024317020']:
            with self.assertRaisesRegex(ValueError, 'Quarantined'):
                validate_reviewed_record(row(code=code))

    def test_quantity_is_optional_for_ingredient_assessment(self):
        validate_reviewed_record(row())

    def test_fodmap_cannot_use_an_unsourced_threshold(self):
        with self.assertRaisesRegex(ValueError, 'unverified'):
            validate_reviewed_record(row(fodmap_servings=[{'status':'unverified', 'grams_max': 30, 'level':'low'}]))
        with self.assertRaisesRegex(ValueError, 'gram range'):
            validate_reviewed_record(row(fodmap_servings=[{
                'status':'verified', 'source_type':'manufacturer',
                'source_url':'https://example.org/serving-evidence',
                'verified_at':'2026-10-12T00:00:00Z', 'level':'low',
                'evidence_basis':'source_reported_serving_assessment'}]))

    def test_transcription_corrections_preserve_quarantine_and_original(self):
        from tool.submitted_text_normalization import normalize_submitted
        original = dict(no=97, ingredients='süt proteni', status='unverified', verified_at=None)
        corrected = normalize_submitted(original)
        self.assertEqual(corrected['ingredients'], 'süt proteini')
        self.assertEqual(corrected['ingredients_original'], 'süt proteni')
        self.assertEqual(corrected['status'], 'unverified')
        self.assertIsNone(corrected['verified_at'])
        self.assertEqual(normalize_submitted(corrected), corrected)

    def test_import_rejects_bad_barcode_and_missing_source_metadata(self):
        candidates = [row(code='12345678'), row(status='unverified'), row(source_url=''),
            row(source_type=None), row(verified_at=None), row(verified_at='2099-01-01T00:00:00Z'),
            row(code='8690623223010'), row(code='8690527021149')]
        accepted, rejected = partition(candidates, 'food')
        self.assertEqual(accepted, [])
        self.assertEqual(len(rejected), len(candidates))

    def test_priority_and_ocr_needs_review(self):
        candidates = [row(source_type=t) for t in ['open_food_facts','retailer','manufacturer','label_photo']]
        self.assertEqual(preferred_reviewed(candidates)['source_type'], 'label_photo')
        candidates[-1]['status'] = 'unverified'
        self.assertEqual(preferred_reviewed(candidates)['source_type'], 'manufacturer')
        candidates[-2]['status'] = 'unverified'
        self.assertEqual(preferred_reviewed(candidates)['source_type'], 'retailer')

    def test_conflicting_formula_is_not_resolved_by_priority(self):
        accepted, rejected = partition([row(), row(source_type='label_photo', ingredients='Different')], 'food')
        self.assertEqual(accepted, [])
        self.assertEqual(len(rejected), 2)

if __name__ == '__main__':
    unittest.main()
