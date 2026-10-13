"""Shared, offline validation for reviewed catalogue imports (no guessed GTINs)."""
import re
from datetime import datetime, timezone
from urllib.parse import urlparse
from pathlib import Path
import json
import math

def excluded_codes():
    folder = Path(__file__).resolve().parents[1] / 'data/quarantine'
    codes = {'8690527021149'}
    for name in ['processed_meat_150.json', 'source_review_pending.json']:
        path = folder / name
        if path.exists():
            codes.update(row['code'] for row in json.loads(path.read_text(encoding='utf-8')) if row.get('code'))
    return codes

SOURCE_PRIORITY = {'label_photo': 0, 'manufacturer': 1, 'retailer': 2, 'open_food_facts': 3}

def valid_source(url):
    if not isinstance(url, str):
        return False
    uri = urlparse(url)
    return uri.scheme == 'https' and bool(uri.hostname) and not uri.username

def validate_provenance(row):
    if row.get('code') in excluded_codes():
        raise ValueError('Quarantined submission code')
    if row.get('status') != 'verified':
        raise ValueError('Record is unverified')
    if row.get('catalog_batch') == 'processed-meat-20261013':
        raise ValueError('Quarantined submission batch')
    if row.get('source_type') not in SOURCE_PRIORITY or not valid_source(row.get('source_url')):
        raise ValueError('Missing source evidence')
    try:
        verified = datetime.fromisoformat(row['verified_at'].replace('Z', '+00:00'))
        if verified.tzinfo is None or verified > datetime.now(timezone.utc):
            raise ValueError('Invalid verification date')
    except (KeyError, TypeError, AttributeError, ValueError) as error:
        raise ValueError('Missing or invalid verified_at') from error

def preferred_reviewed(candidates):
    """Only reviewed evidence is eligible; OCR output is never self-verifying."""
    eligible = []
    for row in candidates:
        try:
            validate_reviewed_record(row)
            eligible.append(row)
        except ValueError:
            continue
    return min(eligible, key=lambda row: SOURCE_PRIORITY[row['source_type']]) if eligible else None

def validate_fodmap_servings(row):
    """Optional independent portion evidence; never infer a higher-dose result."""
    servings = row.get('fodmap_servings', [])
    if not isinstance(servings, list):
        raise ValueError('FODMAP serving evidence must be a list')
    for serving in servings:
        if not isinstance(serving, dict):
            raise ValueError('Invalid FODMAP serving evidence')
        validate_provenance({**serving, 'code': row['code']})
        if serving.get('level') not in {'low', 'moderate', 'high'}:
            raise ValueError('Unknown FODMAP serving level')
        minimum, maximum = serving.get('grams_min'), serving.get('grams_max')
        if minimum is None and maximum is None:
            raise ValueError('FODMAP requires a source-backed gram range')
        for amount in (minimum, maximum):
            if amount is not None and (isinstance(amount, bool) or not isinstance(amount, (int,float)) or not math.isfinite(amount) or amount < 0):
                raise ValueError('Invalid FODMAP gram amount')
        if minimum is not None and maximum is not None and minimum > maximum:
            raise ValueError('Reversed FODMAP gram range')
        if serving.get('evidence_basis') != 'source_reported_serving_assessment':
            raise ValueError('Ingredient text alone cannot establish a FODMAP threshold')


def valid_gtin(code):
    if not isinstance(code, str) or not re.fullmatch(r'(?:[0-9]{8}|[0-9]{12}|[0-9]{13}|[0-9]{14})', code):
        return False
    total = sum(int(digit) * (3 if i % 2 == 0 else 1)
                for i, digit in enumerate(reversed(code[:-1])))
    return (total + int(code[-1])) % 10 == 0


def validate_reviewed_record(row):
    """Require explicit field evidence and a complete reviewed ingredient field."""
    if not valid_gtin(row.get('code')):
        raise ValueError('Invalid GTIN; never manufacture a replacement check digit')
    validate_provenance(row)
    for field in ('name', 'ingredients', 'catalog_batch', 'checked_at'):
        if not isinstance(row.get(field), str) or not row[field].strip():
            raise ValueError('Missing ' + field)
    for field in ('code', 'name', 'ingredients'):
        urls = row.get('field_sources', {}).get(field, [])
        if not urls or any(not valid_source(url) for url in urls):
            raise ValueError('Missing HTTPS evidence for ' + field)
    if row.get('ingredient_evidence') != 'full_label_transcription':
        raise ValueError('Incomplete ingredient evidence')
    validate_fodmap_servings(row)


def merge_reviewed(existing, reviewed):
    """Append idempotently; refuse to silently replace a different existing row."""
    result = list(existing)
    by_code = {row['code']: row for row in existing}
    if len(by_code) != len(existing):
        raise ValueError('Existing catalogue has duplicate GTINs')
    for row in reviewed:
        validate_reviewed_record(row)
        previous = by_code.get(row['code'])
        if previous is not None:
            if previous != row:
                raise ValueError('Existing barcode conflict: ' + row['code'])
            continue
        result.append(row)
        by_code[row['code']] = row
    return result
