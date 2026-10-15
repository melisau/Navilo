"""Rebuild additional Watsons imports; exclude catalogue and prior researched GTINs."""
import json
import parse_watsons_lips as parser
parser.OUT=parser.ROOT/'docs/lip_research_extra_20261015'
parser.run()
known=set()
for p in [parser.ROOT/'assets/curated_cosmetics.json',parser.ROOT/'docs/lip_research_20261015/reviewed_watsons.json']:
    known.update(r['code'].zfill(14) for r in json.loads(p.read_text(encoding='utf8')))
reviewed=json.loads((parser.OUT/'reviewed_watsons.json').read_text(encoding='utf8'))
audit=json.loads((parser.OUT/'audit_watsons.json').read_text(encoding='utf8'))
new=[]
for r in reviewed:
    if r['code'] in {'8009518442281','5057566843263'}:
        reason=('Published coloured lipstick INCI stops after seven base ingredients and has no pigment declaration; completeness cannot be established' if r['code']=='8009518442281' else 'Published optional pigment list ends with an unclosed parenthesis; completeness cannot be established')
        audit.append({'code':r['code'],'name':r['name'],'source_url':r['source_url'],'status':'pending','reasons':[reason],'ingredients_original':r['ingredients_original']})
    elif r['code'].zfill(14) in known:
        audit.append({'code':r['code'],'name':r['name'],'source_url':r['source_url'],'status':'existing','reasons':['Already in catalogue or prior Watsons research batch']})
    else:
        r['catalog_batch']='lip-research-extra-20261015'
        if r['name'].startswith('Max Factor '):r['brand']='Max Factor'
        if r['name'].lower().startswith('i heart revolution '):r['brand']='I Heart Revolution'
        new.append(r)
        known.add(r['code'].zfill(14))
(parser.OUT/'reviewed_watsons.json').write_text(json.dumps(new,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(parser.OUT/'audit_watsons.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'new_unique':len(new),'audit':len(audit)}))
