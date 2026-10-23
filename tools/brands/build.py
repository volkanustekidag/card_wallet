"""Builds assets/brands/brands.json from catalog.txt (target markets,
curated) plus other_regions.json (markets not curated yet).

Run from the repo root: python3 tools/brands/build.py
"""
import json, os, re, sys

HERE = os.path.dirname(__file__)
KINDS = {'grocery', 'drugstore', 'beauty', 'fashion', 'shoes', 'sports',
         'home', 'diy', 'electronics', 'books', 'pets', 'toys', 'department',
         'fuel', 'food', 'cinema', 'fitness', 'travel', 'points'}
# Entries in other_regions.json that catalog.txt now covers.
SUPERSEDED = {'Emirates Skywards', 'Etihad Guest', 'Qatar Airways Privilege Club',
              '7-Eleven', 'Uniqlo', 'Lidl Suomi', 'LATAM Pass', 'Countdown'}

def fail(msg):
    sys.exit('catalog.txt: ' + msg)

entries, seen = [], {}
for no, line in enumerate(open(os.path.join(HERE, 'catalog.txt'), encoding='utf-8'), 1):
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    parts = [p.strip() for p in line.split('|')]
    if len(parts) != 7:
        fail(f'line {no}: expected 7 fields, got {len(parts)}')
    name, domain, colour, kind, tier, regions, aliases = parts
    if not re.fullmatch(r'[a-z0-9.-]+\.[a-z]{2,}', domain):
        fail(f'line {no}: bad domain {domain!r}')
    if not re.fullmatch(r'#[0-9A-Fa-f]{6}', colour):
        fail(f'line {no}: bad colour {colour!r}')
    if kind not in KINDS:
        fail(f'line {no}: unknown kind {kind!r}')
    if tier not in ('1', '2', '3'):
        fail(f'line {no}: tier must be 1-3')
    rs = [r.strip() for r in regions.split(',') if r.strip()]
    for r in rs:
        if r != 'global' and not re.fullmatch(r'[a-z]{2}', r):
            fail(f'line {no}: bad country {r!r}')
        if r == 'uk':
            fail(f'line {no}: use gb, not uk')
    for r in rs:
        key = (name.lower(), r)
        if key in seen:
            fail(f'line {no}: {name} already listed for {r} (line {seen[key]})')
        seen[key] = no
    e = {'n': name, 'd': domain, 'c': colour.upper(), 'r': rs, 'k': kind, 'p': int(tier)}
    al = [a.strip() for a in aliases.split(';') if a.strip()]
    if al:
        e['a'] = al
    entries.append(e)

others = [e for e in json.load(open(os.path.join(HERE, 'other_regions.json'), encoding='utf-8'))
          if e['n'] not in SUPERSEDED]
for e in others:
    e['p'] = 3

out = entries + others
path = os.path.join(HERE, '..', '..', 'assets', 'brands', 'brands.json')
with open(path, 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    f.write('\n')

per = {}
for e in out:
    for r in e['r']:
        per[r] = per.get(r, 0) + 1
print(f'{len(out)} brands ({len(entries)} curated)')
print(' '.join(f'{k}:{v}' for k, v in sorted(per.items(), key=lambda kv: -kv[1])))
