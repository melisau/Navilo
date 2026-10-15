"""Rebuild reviewed Watsons data from saved web-tool source captures.

Captures use public Watsons product pages. HTTP collection returns 403 in this
environment; capture exact known product URLs with web open at lines 950/1150.
No GTIN or INCI is inferred from sibling variants. All uncertain rows are audited.
"""
from pathlib import Path
import json,re,sys
from datetime import datetime,timezone
sys.path.insert(0,str(Path(__file__).resolve().parent))
from catalog_validation import valid_gtin,validate_reviewed_record
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/lip_research_20261015'
def run():
    sources={}
    for p in sorted(OUT.glob('watsons_*pages.json'))+sorted(OUT.glob('watsons_web_heads.json'))+sorted(OUT.glob('watsons_batch*.json')):
        for row in json.loads(p.read_text(encoding='utf8')):
            sources.setdefault(row['url'],[]).append(row['text'])
    good=[];audit=[]
    now=datetime.now(timezone.utc).isoformat().replace('+00:00','Z')
    for url,parts in sources.items():
        text='\n'.join(parts)
        clean=re.sub(r'L\d+: ?','',text)
        name=(re.search(r'^# (.+)$',clean,re.M) or re.search(r'^(.+) \d+ \| Watsons',clean,re.M))
        name=name.group(1).strip() if name else ''
        codes=list(dict.fromkeys(re.findall(r'^([0-9]{8}|[0-9]{13})\s*$',clean,re.M)))
        code=next((c for c in codes if valid_gtin(c)),'')
        sections=re.findall(r'Ürün İçerik Bilgisi\s+([\s\S]*?)İmalatçı Bilgisi',clean)
        inci=next((s.strip().strip('"') for s in sections if len(s.strip())>80),'')
        reason=[]
        if not name:reason.append('Product name absent from captured source')
        if not code:reason.append('No valid exact GTIN captured')
        if not inci:reason.append('Full INCI absent from retailer page/capture')
        if re.search(r'balm|balmı|balmi|dudak yağı|kalemi|kombo|seti',name,re.I):reason.append('Outside lipstick/lipgloss scope')
        if inci and (re.search(r'|\[Button|\.\.\.|…|https?://',inci) or len(inci)>4000):reason.append('INCI source looks truncated or polluted')
        if reason:audit.append({'source_url':url,'name':name,'code':code,'status':'pending','reasons':reason});continue
        low=name.lower()
        brands=['Maybelline New York',"L'Oreal Paris",'Rimmel London','Nyx Professional Makeup','Golden Rose','Revolution','Unfilter Beauty','Deborah Milano','Show By Pastel','Pastel']
        brand=next((b for b in brands if low.startswith(b.lower())),name.split()[0])
        if low.startswith('nyx '):brand='NYX Professional Makeup'
        if low.startswith('deborah '):brand='Deborah Milano'
        marker=re.search(r'[\[(]?\s*(?:\+\s*/\s*[-−]|±)',inci)
        base=inci[:marker.start()].rstrip(' ,;') if marker else inci
        optional=inci[marker.start():].strip() if marker else ''
        r={'code':code,'name':name,'brand':brand,'category':'cosmetic','subcategory':'lip_gloss' if re.search(r'gloss|parlatıcı|parlatici',name,re.I) else 'lipstick','ingredients':base,'may_contain':optional,'ingredients_original':inci,'source_url':url,'source_name':'Watsons Türkiye','barcode_source_url':url,'field_sources':{k:[url] for k in ['code','name','ingredients']},'source_type':'retailer','status':'verified','verified_at':now,'checked_at':now,'catalog_batch':'lip-research-20261015','ingredient_evidence':'full_label_transcription'}
        validate_reviewed_record(r)
        good.append(r)
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'reviewed_watsons.json').write_text(json.dumps(good,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    (OUT/'audit_watsons.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(json.dumps({'verified':len(good),'pending':len(audit)},ensure_ascii=False))
if __name__=='__main__':run()
