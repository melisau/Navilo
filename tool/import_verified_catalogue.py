"""Import explicit reviewed records; invalid/unverified rows go to a private ledger.

Usage: python -m tool.import_verified_catalogue reviewed.json --category food
Source priority: label_photo > manufacturer > retailer > open_food_facts.
OCR output must be reviewed against the same package before status=verified.
"""
import argparse
import json
from pathlib import Path
from datetime import datetime, timezone
from tool.catalog_validation import validate_reviewed_record, SOURCE_PRIORITY, merge_reviewed

ROOT = Path(__file__).resolve().parents[1]

def partition(rows, category):
    accepted, rejected = [], []
    for row in rows:
        try:
            validate_reviewed_record(row)
            if row.get('category') != category:
                raise ValueError('Category mismatch')
            accepted.append(row)
        except (ValueError, TypeError, AttributeError) as error:
            rejected.append({'record': row, 'status': 'unverified', 'reason': str(error)})
    # Conflicting names/formulas need a reviewer; priority cannot resolve that.
    groups = {}
    for row in accepted:
        groups.setdefault(row['code'], []).append(row)
    selected = []
    for group in groups.values():
        if len({(r['name'], r['ingredients']) for r in group}) != 1:
            rejected.extend({'record': r, 'status': 'unverified', 'reason': 'Conflicting product identity/formula'} for r in group)
        else:
            selected.append(min(group, key=lambda r: SOURCE_PRIORITY[r['source_type']]))
    return selected, rejected

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('--category', choices=['food', 'cosmetic'], required=True)
    args = parser.parse_args()
    rows = json.loads(args.input.read_text(encoding='utf-8'))
    if not isinstance(rows, list):
        raise ValueError('Expected a list of source-reviewed records')
    accepted, rejected = partition(rows, args.category)
    target = ROOT / 'assets' / ('curated_products.json' if args.category == 'food' else 'curated_cosmetics.json')
    original = json.loads(target.read_text(encoding='utf-8'))
    merged = merge_reviewed(original, accepted)
    if merged != original:
        target.write_text(json.dumps(merged, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    folder = ROOT / 'data/quarantine'
    folder.mkdir(parents=True, exist_ok=True)
    ledger = folder / ('import_rejections_' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%f') + '.json')
    ledger.write_text(json.dumps(rejected, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'added': len(merged)-len(original), 'rejected': len(rejected), 'ledger': str(ledger)}))

if __name__ == '__main__':
    main()
