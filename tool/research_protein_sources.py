"""Collect public source evidence only; never publish automatically."""
import json, re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import requests
from bs4 import BeautifulSoup

OUT = Path(__file__).resolve().parents[1] / 'docs/protein_expansion_20261015'
URLS = [
 'https://www.bigjoy.com.tr/isopro-whey-915g-cikolata',
 'https://www.bigjoy.com.tr/isoclear-whey-480g-icetea',
 'https://www.bigjoy.com.tr/bigwhey-protein-klasik-fistikli-dondurma-990g',
 'https://www.bigjoy.com.tr/bigwhey-go-68-mix',
 'https://www.bigjoy.com.tr/beef-whey-protein-1088g',
 'https://proteinocean.com/whey-protein',
 'https://proteinocean.com/whey-isolate',
 'https://proteinocean.com/pea-protein',
 'https://safnutrition.co/products/bezelye-proteini-tozu-100-gr',
 'https://safnutrition.co/products/bitkisel-protein-superfood-sports-mix-360-gr',
 'https://www.naturiga.com/products/organik-pirinc-proteini-tozu-250-gr',
 'https://www.eprotein.com.tr/dymatize-elite-100-whey-protein-2170-gr',
 'https://www.eprotein.com.tr/olimp-whey-protein-complex-700-gr',
 'https://weider.com.tr/urunler/252-weider-premium-whey-2-3-kg-muzlu',
]

def fetch(item):
 i, url = item
 try:
  r = requests.get(url, timeout=30)
  if r.status_code != 200:
   return dict(url=url, status=r.status_code)
  soup=BeautifulSoup(r.content.decode('utf-8'), 'html.parser')
  text=soup.get_text(' ',strip=True)
  OUT.joinpath(f'source_{i}.html').write_text(str(soup),encoding='utf-8')
  data=soup.find('script',id='__NEXT_DATA__')
  if data:
   product=json.loads(data.get_text())['props']['pageProps'].get('pageSpecificData')
   OUT.joinpath(f'product_{i}.json').write_text(json.dumps(product,ensure_ascii=False,indent=2),encoding='utf-8')
  codes=list(dict.fromkeys(re.findall(r'(?<!\d)(?:\d{12,14})(?!\d)', str(soup))))
  excerpts=[text[max(0,m.start()-60):m.start()+1300] for m in re.finditer(r'İçindekiler|Bileşenler:|Barkod|Ingredients',text,re.I)]
  return dict(url=url,status=200,title=soup.h1.get_text(' ',strip=True) if soup.h1 else None,codes=codes[:30],excerpts=excerpts[:8])
 except Exception as e:
  return dict(url=url,error=str(e))

if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True)
 rows=list(ThreadPoolExecutor(4).map(fetch,enumerate(URLS)))
 OUT.joinpath('source_results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
 for i,r in enumerate(rows):
  print(i,r.get('status'),r.get('title'),r.get('codes'),r.get('excerpts',[])[:1])
