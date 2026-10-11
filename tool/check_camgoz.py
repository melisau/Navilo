"""Local Camgoz pilot. Reads JOJ_API_KEY from environment or .env.local; never prints it."""
import json
import os
import re
from pathlib import Path
import urllib.request
import urllib.parse
import urllib.error

CODES = ['8681630799919', '8683979249261', '8690577001764', '8683979480152', '4061461279493', '8691190142261']

def exact_records(payload, code):
    if not isinstance(payload, list):
        raise ValueError('Unexpected API response; check current schema')
    return [p for p in payload if isinstance(p, dict) and str(p.get('barcode', '')) == code]

def load_key():
    key = os.environ.get('JOJ_API_KEY', '').strip()
    if not key:
        env_file = Path(__file__).resolve().parents[1] / '.env.local'
        if env_file.exists():
            for line in env_file.read_text(encoding='utf-8-sig').splitlines():
                name, sep, value = line.partition('=')
                if sep and name.strip() == 'JOJ_API_KEY':
                    key = value.strip().strip('"').strip("'")
                    break
    if not key or key == 'BURAYA_YAPISTIR':
        raise SystemExit('Open .env.local and replace BURAYA_YAPISTIR with your new JoJ key. Do not include Bearer.')
    if key.startswith('Bearer '):
        raise SystemExit('Remove the Bearer prefix from .env.local; keep only the key.')
    return key


def safe_error_details(body, key):
    # Never print raw headers, HTML, authentication data or arbitrary JSON fields.
    body = body.replace(key, '[REDACTED]')
    body = re.sub(r'jk_[A-Za-z0-9_-]+', '[REDACTED]', body)
    result = {}
    try:
        data = json.loads(body)
    except ValueError:
        data = None
    if isinstance(data, dict):
        for field in ('title', 'detail', 'message', 'error_code', 'error_name', 'ray_id', 'owner_action_required'):
            value = data.get(field)
            if isinstance(value, (str, int, bool)):
                result[field] = value[:600] if isinstance(value, str) else value
    if '1010' in body and ('cloudflare' in body.lower() or 'error code: 1010' in body.lower()):
        result['category'] = 'cloudflare_1010_client_blocked'
        result['next_step'] = 'Provider action required; do not retry or change identity to bypass.'
    elif not result:
        result['category'] = 'unclassified_http_error'
        result['next_step'] = 'Check provider request logs or send status and Cloudflare Ray ID to support.'
    return result


def main():
    key = load_key()
    for code in CODES:
        query = urllib.parse.urlencode({'query': code, 'marketPrices': 'false', 'historyPrices': 'false'})
        req = urllib.request.Request('https://camgoz.jojapi.net/api/external/search?' + query,
                                     headers={'X-JoJAPI-Key': key, 'Accept': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=15) as response:
                records = exact_records(json.load(response), code)
            print(json.dumps({'barcode': code, 'exact_matches': len(records), 'records': [
                {'name': r.get('name'), 'ingredients': r.get('ingredients'),
                 'has_ingredients': isinstance(r.get('ingredients'), str) and bool(r['ingredients'].strip())}
                for r in records]}, ensure_ascii=False))
        except urllib.error.HTTPError as error:
            body = error.read(8192).decode('utf-8', errors='replace')
            details = safe_error_details(body, key)
            ray = error.headers.get('CF-Ray')
            if ray:
                details['cf_ray'] = ray
            print(json.dumps({'barcode': code, 'http_status': error.code, 'details': details}, ensure_ascii=False))
            if error.code in (401, 403, 429):
                break
        except (urllib.error.URLError, TimeoutError, ValueError):
            print(json.dumps({'barcode': code, 'error': 'Connection or response failure'}))

if __name__ == '__main__':
    main()
