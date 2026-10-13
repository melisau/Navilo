import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from unittest.mock import Mock

from tool.catalog_validation import merge_reviewed, valid_gtin, validate_reviewed_record
from tool import collect_harras

ROOT = Path(__file__).resolve().parents[1]


class CatalogueValidationTests(unittest.TestCase):
    def test_real_gtin_lengths_and_bad_digits(self):
        for code in ('86920124', '036000291452', '8690504034032', '10012345000017'):
            self.assertTrue(valid_gtin(code), code)
            wrong = code[:-1] + str((int(code[-1]) + 1) % 10)
            self.assertFalse(valid_gtin(wrong), wrong)
        for code in ('8690526013334', '8690504116439', '1234', '８６９２０１２４', None):
            self.assertFalse(valid_gtin(code), code)

    def test_reviewed_import_preserves_existing_and_rejects_conflicts(self):
        rows = json.loads((ROOT / 'docs/catalog_analysis/reviewed_food_repair.json').read_text(encoding='utf-8'))
        sentinel = {'code': '036000291452', 'name': 'Keep every original field', 'other': [1, 2]}
        merged = merge_reviewed([sentinel], rows)
        self.assertEqual(merged[0], sentinel)
        self.assertEqual(merge_reviewed(merged, rows), merged)
        changed = copy.deepcopy(rows[0])
        changed['ingredients'] = 'A different formula'
        with self.assertRaisesRegex(ValueError, 'conflict'):
            merge_reviewed(merged, [changed])
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            merge_reviewed([sentinel, sentinel], [])

    def test_missing_field_evidence_and_incomplete_formulas_are_blocked(self):
        original = json.loads((ROOT / 'docs/catalog_analysis/reviewed_food_repair.json').read_text(encoding='utf-8'))[0]
        for field in ('code', 'name', 'ingredients'):
            row = copy.deepcopy(original)
            del row['field_sources'][field]
            with self.assertRaisesRegex(ValueError, 'evidence'):
                validate_reviewed_record(row)
        row = copy.deepcopy(original)
        row['ingredient_evidence'] = 'marketing_summary'
        with self.assertRaisesRegex(ValueError, 'Incomplete'):
            validate_reviewed_record(row)

    def test_invalid_submitted_gtin_never_calls_provider(self):
        with patch.object(collect_harras.requests, 'get') as get:
            result = collect_harras.collect({'code': '8690526013334'})
        self.assertEqual(result['status'], 'invalid_gtin_not_imported')
        get.assert_not_called()

    def test_cached_gtin8_survives_without_network(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            (out / 'sources').mkdir()
            payload = {'status': 1, 'code': '86920124', 'product': {'code': '86920124', 'product_name': 'Eti Puf'}}
            (out / 'sources/86920124.json').write_text(json.dumps(payload), encoding='utf-8')
            with patch.object(collect_harras, 'OUT', out), patch.object(collect_harras.requests, 'get') as get:
                result = collect_harras.collect({'code': '86920124'})
            get.assert_not_called()
            self.assertEqual(result['status'], 'source_candidate_pending_review')

    def test_rate_limit_is_actionable_and_not_cached_as_missing_product(self):
        response = Mock(status_code=429, headers={'Retry-After': '120'})
        with tempfile.TemporaryDirectory() as folder:
            with patch.object(collect_harras, 'OUT', Path(folder)), patch.object(collect_harras.requests, 'get', return_value=response) as get:
                result = collect_harras.collect({'code': '86920124'})
            self.assertEqual(get.call_count, 1)
            self.assertEqual(result['retry_after'], '120')
            self.assertIn('RATE_LIMIT:', result['error'])
            self.assertFalse((Path(folder) / 'sources/86920124.json').exists())

    def test_bad_schema_is_not_a_not_found_result(self):
        response = Mock(status_code=200)
        response.json.return_value = {'unexpected': 'provider changed schema'}
        with tempfile.TemporaryDirectory() as folder:
            with patch.object(collect_harras, 'OUT', Path(folder)), patch.object(collect_harras.requests, 'get', return_value=response):
                result = collect_harras.collect({'code': '86920124'})
            self.assertEqual(result['status'], 'source_unavailable_not_imported')
            self.assertIn('SOURCE_SCHEMA:', result['error'])
            self.assertFalse((Path(folder) / 'sources/86920124.json').exists())


if __name__ == '__main__':
    unittest.main()
