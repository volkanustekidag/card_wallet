# App Store search position of Deckard per term and country, from the public iTunes Search API (a proxy for
# the App Store's own results, not identical to them). Run: python3 -I tools/aso/rank.py
import json, urllib.request, urllib.parse, time
APP = 6755343533
Q = {
 "us": ["deckard", "loyalty card", "loyalty card wallet", "rewards card", "membership card", "card wallet", "barcode wallet", "store card", "points card", "gym card"],
 "gb": ["loyalty card", "loyalty card wallet", "card wallet", "reward cards"],
 "de": ["kundenkarten", "kundenkarten app", "bonuskarten", "treuekarte", "karten wallet"],
 "tr": ["sadakat kartı", "kart cüzdanı", "üyelik kartı", "iban"],
 "fr": ["carte de fidélité", "cartes de fidélité"],
 "nl": ["klantenkaart", "klantenkaarten"],
}
for cc, qs in Q.items():
    for q in qs:
        url = "https://itunes.apple.com/search?" + urllib.parse.urlencode({"term": q, "country": cc, "entity": "software", "limit": 200})
        try:
            d = json.load(urllib.request.urlopen(url, timeout=20))
            ids = [r["trackId"] for r in d["results"]]
            pos = ids.index(APP) + 1 if APP in ids else None
            top = ", ".join(r["trackName"][:22] for r in d["results"][:3])
            print(f"{cc} | {q} | {pos if pos else '>200'} | {len(ids)} | {top}")
        except Exception as e:
            print(cc, q, "ERR", e)
        time.sleep(1.2)
