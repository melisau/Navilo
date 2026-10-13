"""Import a manually reviewed source batch; safe to rerun, never invent aliases."""
import json
from pathlib import Path

try:
    from .catalog_validation import merge_reviewed
except ImportError:
    from catalog_validation import merge_reviewed

ROOT = Path(__file__).resolve().parents[1]


def main():
    batch = ROOT / 'docs/catalog_analysis/reviewed_food_repair.json'
    path = ROOT / 'assets/curated_products.json'
    existing = json.loads(path.read_text(encoding='utf-8'))
    reviewed = json.loads(batch.read_text(encoding='utf-8'))
    merged = merge_reviewed(existing, reviewed)
    path.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'before': len(existing), 'added': len(merged) - len(existing),
                      'after': len(merged)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
