"""Explicit user-approved transcription fixes; never fuzzy-match ingredients."""
FIXES = {
    10: [('deksitroz', 'dekstroz')],
    79: [('deksitroz', 'dekstroz')],
    97: [('süt proteni', 'süt proteini')],
    115: [('hindistan cevizi cevizi (muskat)', 'muskat')],
}

def normalize_submitted(row):
    result = dict(row)
    original = row.get('ingredients_original', row['ingredients'])
    text = original
    changes = []
    for old, new in FIXES.get(row['no'], []):
        if old in text:
            text = text.replace(old, new)
            changes.append({'from': old, 'to': new, 'basis': 'user_requested_transcription_fix'})
    if changes:
        result.update(ingredients=text, ingredients_original=original, text_corrections=changes)
    return result
