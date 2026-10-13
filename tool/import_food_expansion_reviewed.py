"""Merge both agents' reviewed expansion batches and emit an integration ledger."""
import json
from pathlib import Path
from tool.catalog_validation import merge_reviewed

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/catalog_analysis'
INPUTS=['reviewed_food_expansion_retailer.json','research_food_expansion.json','reviewed_food_expansion_staples.json']


def main():
    path=ROOT/'assets/curated_products.json'
    existing=json.loads(path.read_text(encoding='utf-8'))
    rows=[]
    for file in INPUTS:
        rows.extend(json.loads((OUT/file).read_text(encoding='utf-8')))
    merged=merge_reviewed(existing,rows)
    path.write_text(json.dumps(merged,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    results=[dict(submitted_code='',verified_code=row['code'],status='added',name=row['name'],
                  reason='Aynı ürün/gramaj için doğrulanmış GTIN ve tam etiket içeriği ile eklendi. Alan bazlı kaynaklar kayıt üzerinde.',
                  source_url=row['source_url']) for row in rows]
    (OUT/'repair_results_expansion.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(before=len(existing),added=len(merged)-len(existing),after=len(merged),batch_rows=len(rows))))


if __name__=='__main__':
    main()
