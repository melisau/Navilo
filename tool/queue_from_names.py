"""Turn 'GTIN|name as listed' lines into a coverage queue, skipping barcodes
already in the catalogue or already queued. Usage: queue_from_names.py IN OUT"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_validation import valid_gtin  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
known = set()
for f in ('assets/curated_products.json', 'assets/curated_cosmetics.json'):
    known |= {r.get('code') for r in json.loads((ROOT / f).read_text(encoding='utf-8'))}
for q in (ROOT / 'docs/new_products').glob('queue_*.json'):
    if not q.name.endswith('.report.json'):
        known |= {r['code'] for r in json.loads(q.read_text(encoding='utf-8'))}
rows, seen = [], set()
for line in Path(sys.argv[1]).read_text(encoding='utf-8').splitlines():
    if '|' not in line:
        continue
    code, name = (p.strip() for p in line.split('|', 1))
    if code in known or code in seen or not valid_gtin(code):
        continue
    seen.add(code)
    rows.append({'code': code, 'name': name, 'category': 'food'})
Path(sys.argv[2]).write_text(json.dumps(rows, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
print(len(rows), 'queued')
