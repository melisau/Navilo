"""Shared, offline validation for reviewed catalogue imports (no guessed GTINs)."""
import re
from urllib.parse import urlparse


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
    for field in ('name', 'ingredients', 'catalog_batch', 'checked_at'):
        if not isinstance(row.get(field), str) or not row[field].strip():
            raise ValueError('Missing ' + field)
    for field in ('code', 'name', 'ingredients'):
        urls = row.get('field_sources', {}).get(field, [])
        if not urls or any(urlparse(url).scheme != 'https' for url in urls):
            raise ValueError('Missing HTTPS evidence for ' + field)
    if row.get('ingredient_evidence') != 'full_label_transcription':
        raise ValueError('Incomplete ingredient evidence')


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
