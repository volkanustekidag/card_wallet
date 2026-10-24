"""Builds the fastlane store metadata for both stores, every locale.

Sources:
  tools/store_listing/aso.json            name, subtitle, keywords, Play title and
                                          short description, Premium paragraph
  docs/store/release/listing.md           promotional text and full descriptions
  docs/store/release/whats_new.md         release notes

Output (what `fastlane ios metadata` / `fastlane android metadata` upload):
  fastlane/metadata/ios/<App Store locale>/*.txt
  fastlane/metadata/android/<Play locale>/*.txt, changelogs/<versionCode>.txt

Fails when a field is over its store limit or a rule is broken.
Usage: python3 tools/store_listing/build.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.dirname(os.path.abspath(__file__))
ASO = json.load(open(os.path.join(HERE, 'aso.json'), encoding='utf-8'))
LISTING = open(os.path.join(ROOT, 'docs/store/release/listing.md'), encoding='utf-8').read()
WHATS_NEW = open(os.path.join(ROOT, 'docs/store/release/whats_new.md'), encoding='utf-8').read()
PRIVACY_URL = 'https://olkan.dev/privacy/cardwallet'

# Competitor apps never appear in store text (App Store 2.3.7, Play metadata policy).
BANNED = ['stocard', 'klarna', 'catima', 'fidme', 'supercards', 'barcodes app']
# The paragraph about plans; rewritten from aso.json (no weekly plan, lifetime added).
PLAN_WORDS = re.compile(r'week|wöchent|wochen|hafta|hebdo|semanal|settiman|wekelijk|week-|tygodn', re.I)


def section(text, lang):
    m = re.search(r'\n## ' + re.escape(lang) + r'\n(.*?)(?=\n## [a-z]{2}-[A-Z]{2}\n|\Z)', text, re.S)
    if not m:
        sys.exit(f'{lang}: section missing')
    return m.group(1)


def field(body, name):
    m = re.search(r'#### ' + re.escape(name) + r'[^\n]*\n\n```text\n(.*?)\n```', body, re.S)
    if not m:
        sys.exit(f'field missing: {name}')
    return m.group(1).strip()


def replace_plans(desc, paragraph, lang):
    parts = desc.split('\n\n')
    hits = [i for i, p in enumerate(parts) if PLAN_WORDS.search(p)]
    if len(hits) != 1:
        sys.exit(f'{lang}: expected one plan paragraph, found {len(hits)}')
    parts[hits[0]] = paragraph
    return '\n\n'.join(parts)


def fix_counts(text):
    # 596 brands in the catalogue (assets/brands/brands.json).
    return re.sub(r'(?<=\D)700(?=\D)', '500', text)


def check(lang, name, value, limit, unit='chars'):
    n = len(value.encode('utf-8')) if unit == 'bytes' else len(value)
    if n > limit:
        sys.exit(f'{lang} {name}: {n} > {limit} {unit}')
    low = value.lower()
    for b in BANNED:
        if b in low:
            sys.exit(f'{lang} {name}: mentions "{b}"')
    return n


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text.strip() + '\n')


def version_code():
    pub = open(os.path.join(ROOT, 'pubspec.yaml'), encoding='utf-8').read()
    return re.search(r'^version:\s*[\d.]+\+(\d+)', pub, re.M).group(1)


def main():
    code = version_code()
    report = []
    for lang, a in ASO.items():
        if 'texts' in a:
            # Written for this locale (tools/store_listing/texts/<locale>.json).
            t = json.load(open(os.path.join(HERE, 'texts', a['texts'] + '.json'), encoding='utf-8'))
            promo, ios_desc, play_desc = t['promo'], t['desc_ios'], t['desc_play']
            ios_notes, play_notes = t['notes_ios'], t['notes_play']
        else:
            # Another locale's text, adapted (en-GB spelling, Mexican Spanish).
            src = a.get('base', lang)
            body = section(LISTING, src)
            notes = section(WHATS_NEW, src)
            ios_desc = fix_counts(replace_plans(field(body, 'App Store — Description'), a['premium_appstore'], lang))
            play_desc = fix_counts(replace_plans(field(body, 'Google Play — Full description'), a['premium_play'], lang))
            promo = field(body, 'App Store — Promotional Text')
            ios_notes = fix_counts(field(notes, "App Store — What's New"))
            play_notes = fix_counts(field(notes, "Google Play — What's new"))
            for old_word, new_word in a.get('replace', []):
                ios_desc, play_desc, promo, ios_notes, play_notes = (
                    re.sub(r'\b' + re.escape(old_word) + r'\b', new_word, x)
                    for x in (ios_desc, play_desc, promo, ios_notes, play_notes))
        # Keywords must not repeat what the name and subtitle already index.
        indexed = set(re.findall(r'\w+', (a['name'] + ' ' + a['subtitle']).lower()))
        dup = [k for k in a['keywords'].split(',') if k.lower() in indexed]
        if dup:
            sys.exit(f'{lang}: keywords repeat name/subtitle: {dup}')
        if ', ' in a['keywords']:
            sys.exit(f'{lang}: keywords need no space after commas')
        rows = {
            'name': check(lang, 'name', a['name'], 30),
            'subtitle': check(lang, 'subtitle', a['subtitle'], 30),
            'keywords': check(lang, 'keywords', a['keywords'], 100, 'bytes'),
            'promo': check(lang, 'promotional_text', promo, 170),
            'description': check(lang, 'description', ios_desc, 4000),
            'release_notes': check(lang, 'release_notes', ios_notes, 4000),
            'play_title': check(lang, 'play title', a['play_title'], 30),
            'play_short': check(lang, 'play short', a['play_short'], 80),
            'play_full': check(lang, 'play full', play_desc, 4000),
            'play_notes': check(lang, 'play changelog', play_notes, 500),
        }
        ios = os.path.join(ROOT, 'fastlane/metadata/ios', a['appstore_locale'])
        write(f'{ios}/name.txt', a['name'])
        write(f'{ios}/subtitle.txt', a['subtitle'])
        write(f'{ios}/keywords.txt', a['keywords'])
        write(f'{ios}/promotional_text.txt', promo)
        write(f'{ios}/description.txt', ios_desc)
        write(f'{ios}/release_notes.txt', ios_notes)
        write(f'{ios}/privacy_url.txt', PRIVACY_URL)
        play = os.path.join(ROOT, 'fastlane/metadata/android', a.get('play_locale', lang))
        write(f'{play}/title.txt', a['play_title'])
        write(f'{play}/short_description.txt', a['play_short'])
        write(f'{play}/full_description.txt', play_desc)
        write(f'{play}/changelogs/{code}.txt', play_notes)
        report.append((lang, rows))
    w = max(len(k) for k in report[0][1])
    for lang, rows in report:
        print(lang, '  '.join(f'{k}={v}' for k, v in rows.items()))
    print(f'ok: {len(report)} locales, versionCode {code}')


if __name__ == '__main__':
    main()
