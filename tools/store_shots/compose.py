"""Store screenshots, Apple creative assets and the Play feature graphic.

Raw captures (from the simulators / emulators, see README.md) go in RAW;
the finished files land in the fastlane folders:

  fastlane/screenshots/<App Store locale>/          6 x 1290x2796 (6.9" slot)
  fastlane/creative_assets/<App Store locale>/      header 5244x2950, search 3840x1646
  fastlane/metadata/android/<Play locale>/images/   phoneScreenshots 6 x 1080x1920,
                                                     featureGraphic 1024x500,
  fastlane/alt/android/<Play locale>/4_without_wear.png   frame 4 until Wear OS ships
  fastlane/later/wear/<Play locale>/                round Wear OS screenshots

Usage: python3 tools/store_shots/compose.py [RAW_DIR]
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.dirname(os.path.abspath(__file__))
RAW = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, '.context', 'store_raw')
FONTS = os.path.join(RAW, 'fonts')
CAPS = json.load(open(os.path.join(HERE, 'captions.json'), encoding='utf-8'))

MARKETS = ['us', 'de', 'tr', 'fr', 'es', 'it', 'nl', 'pl', 'br']
APPSTORE_LOCALE = {'us': 'en-US', 'de': 'de-DE', 'tr': 'tr', 'fr': 'fr-FR', 'es': 'es-ES',
                   'it': 'it', 'nl': 'nl-NL', 'pl': 'pl', 'br': 'pt-BR'}
PLAY_LOCALE = {'us': 'en-US', 'de': 'de-DE', 'tr': 'tr-TR', 'fr': 'fr-FR', 'es': 'es-ES',
               'it': 'it-IT', 'nl': 'nl-NL', 'pl': 'pl-PL', 'br': 'pt-BR'}
# First card of each market: checkout background and glows.
BRAND = {'us': '#006241', 'de': '#CC071E', 'tr': '#FF6600', 'fr': '#004E9F', 'es': '#00873D',
         'it': '#1E6CB5', 'nl': '#00ADE6', 'pl': '#00A651', 'br': '#00843D'}
NO_IBAN = {'us', 'br'}

INK = (14, 15, 18)
LIGHT = (246, 246, 243)
DARK = (11, 12, 15)
TANGERINE = (255, 90, 31)

# Parts lifted out of the screen, in raw screenshot pixels.
BOXES = {
    'ios': {'upnext': (48, 534, 1272, 770), 'barcode': (54, 740, 1266, 1730),
            'ibancard': (54, 558, 1266, 2348), 'confirmcard': (54, 1276, 1266, 1804),
            'tiles': [(56, 948, 640, 1320), (680, 948, 1264, 1320), (56, 1360, 640, 1728),
                      (680, 1360, 1264, 1728), (56, 1764, 640, 2132), (680, 1764, 1264, 2132)]},
    'android': {'upnext': (48, 432, 1032, 634), 'barcode': (48, 612, 1032, 1476),
                'ibancard': (48, 520, 1032, 1964), 'confirmcard': (48, 1032, 1032, 1490),
                'tiles': [(48, 800, 524, 1092), (556, 800, 1032, 1092), (48, 1132, 524, 1424),
                          (556, 1132, 1032, 1424), (48, 1464, 524, 1756), (556, 1464, 1032, 1756)]},
}


def font(weight, size):
    return ImageFont.truetype(os.path.join(FONTS, f'InstrumentSans-{weight}.ttf'), int(size))


def hex_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def draw_tracked(d, xy, text, f, fill, track):
    x, y = xy
    for i, ch in enumerate(text):
        d.text((x + f.getlength(text[:i]) + i * track, y), ch, font=f, fill=fill)


def tracked_width(text, f, track):
    return f.getlength(text) + max(0, len(text) - 1) * track


def wrap(text, f, width):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if f.getlength(t) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def caption(img, u, lines, sub, color, top=None, left=None, max_w=None, title_size=31, sub_size=12.5):
    """Title + subtitle in the template's type; returns the bottom y."""
    d = ImageDraw.Draw(img)
    left = 22 * u if left is None else left
    max_w = img.width - 2 * left if max_w is None else max_w
    size = title_size * u
    while True:
        f = font('Bold', size)
        track = -0.02 * size
        if all(tracked_width(l, f, track) <= max_w for l in lines) or size < 18 * u:
            break
        size *= 0.95
    y = 34 * u if top is None else top
    for l in lines:
        draw_tracked(d, (left, y), l, f, color, track)
        y += size * 1.05
    fs = font('Regular', sub_size * u)
    y += 8 * u
    sub_color = tuple(int(c * 0.72 + b * 0.28) for c, b in zip(color, img.getpixel((2, 2))[:3]))
    for l in wrap(sub, fs, min(max_w, 256 * u)):
        d.text((left, y), l, font=fs, fill=sub_color)
        y += sub_size * u * 1.35
    return y


def rounded(im, r):
    m = Image.new('L', im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, im.width - 1, im.height - 1), int(r), fill=255)
    out = im.convert('RGBA')
    out.putalpha(m)
    return out


def shadow(base, box, r, blur, alpha, offset):
    sh = Image.new('RGBA', base.size, (0, 0, 0, 0))
    x0, y0, x1, y1 = box
    ImageDraw.Draw(sh).rounded_rectangle((x0, y0 + offset, x1, y1 + offset), int(r), fill=(0, 0, 0, int(255 * alpha)))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh)


def phone(base, u, shot, top, shift=0.0, src_top=0, dim=False, left=None, width=None):
    """The template's phone: black bezel, screenshot inside, runs off the bottom."""
    left = 31 * u if left is None else left
    width = 238 * u if width is None else width
    border = 6 * u
    inner_w = int(width - 2 * border)
    raw = Image.open(shot).convert('RGB')
    if src_top:
        raw = raw.crop((0, src_top, raw.width, raw.height))
    scale = inner_w / raw.width
    scr = raw.resize((inner_w, int(raw.height * scale)), Image.LANCZOS)
    off = int(shift * inner_w)
    vis_h = int(base.height - top - border + 60 * u)
    screen = Image.new('RGB', (inner_w, vis_h), (17, 17, 17))
    screen.paste(scr, (0, -off))
    if dim:
        screen = Image.blend(screen, Image.new('RGB', screen.size, (10, 11, 14)), 0.34)
    body_h = vis_h + 2 * border
    shadow(base, (left, top, left + width, top + body_h), 30 * u, 20 * u, 0.25, 18 * u)
    body = Image.new('RGBA', (int(width), int(body_h)), (17, 17, 17, 255))
    body.alpha_composite(rounded(screen, 24 * u), (int(border), int(border)))
    base.alpha_composite(rounded(body, 30 * u), (int(left), int(top)))
    return {'left': left + border, 'top': top + border - off, 'scale': scale, 'src_top': src_top}


def pop(base, u, shot, box, geo, k=1.16, r=None):
    x0, y0, x1, y1 = box
    raw = Image.open(shot).convert('RGB').crop(box)
    s = geo['scale'] * k
    w, h = int((x1 - x0) * s), int((y1 - y0) * s)
    part = rounded(raw.resize((w, h), Image.LANCZOS), (r or 14 * u) * k)
    cx = geo['left'] + (x0 + x1) / 2 * geo['scale']
    cy = geo['top'] + ((y0 + y1) / 2 - geo['src_top']) * geo['scale']
    px, py = int(cx - w / 2), int(cy - h / 2)
    shadow(base, (px, py, px + w, py + h), 14 * u, 14 * u, 0.30, 12 * u)
    base.alpha_composite(part, (px, py))


def background(size, color, glow=None):
    img = Image.new('RGBA', size, color + (255,))
    if glow:
        g = Image.new('RGBA', size, (0, 0, 0, 0))
        w, h = size
        ImageDraw.Draw(g).ellipse((w * 0.25, -h * 0.15, w * 1.35, h * 0.45), fill=glow + (110,))
        img.alpha_composite(g.filter(ImageFilter.GaussianBlur(w * 0.18)))
    return img


def text_color(bg):
    return INK if sum(bg) > 600 else (255, 255, 255)


# --------------------------------------------------------------------------
# The six frames
# --------------------------------------------------------------------------

def frame(platform, m, i, size, wear=True):
    W, H = size
    u = W / 300
    c = CAPS[m]
    raw = os.path.join(RAW, platform)
    shot = lambda k: os.path.join(raw, f'{m}_{k}.png')
    bx = BOXES[platform]
    brand = hex_rgb(BRAND[m])
    bgs = {1: LIGHT, 2: brand, 3: LIGHT, 4: DARK, 5: DARK, 6: LIGHT}
    bg = bgs[i]
    img = background(size, bg, glow=brand if i == 4 else None)
    fg = text_color(bg)
    title, sub = c[f'f{i}'], c.get(f's{i}')
    if i == 4:
        title, sub = (c['f4'], c[f's4_{platform}']) if wear else (c['f4_nowear'], c['s4_nowear'])
    bottom = caption(img, u, title, sub, fg)
    top = max(182 * u, bottom + 18 * u)
    if i == 1:
        g = phone(img, u, shot('home'), top, dim=True)
        pop(img, u, shot('home'), bx['upnext'], g)
    elif i == 2:
        g = phone(img, u, shot('checkout'), top, dim=True)
        pop(img, u, shot('checkout'), bx['barcode'], g)
    elif i == 3:
        if m in NO_IBAN:
            phone(img, u, shot('grid'), top)
        else:
            g = phone(img, u, shot('iban'), top, shift=0.62, dim=True)
            pop(img, u, shot('iban'), bx['ibancard'], g, k=1.03, r=18 * u)
    elif i == 4:
        if platform == 'ios':
            watch_and_widgets_ios(img, u, m, top)
        else:
            widgets_android(img, u, m, top, wear=wear)
    elif i == 5:
        g = phone(img, u, shot('confirm'), top, shift=0.62, dim=m in NO_IBAN)
        if m in NO_IBAN:
            pop(img, u, shot('confirm'), bx['confirmcard'], g)
    elif i == 6:
        phone(img, u, shot('bank'), top)
    return img.convert('RGB')


def watch_ios(base, u, m, x, y, w):
    """Apple Watch: rounded body, the real watch screenshot, 9:41 on top."""
    scr = Image.open(os.path.join(RAW, 'watch', f'{m}.png')).convert('RGB')
    d = ImageDraw.Draw(scr)
    # The simulator clock can't be overridden; paint 9:41 over it.
    tile = scr.crop((250, 20, 410, 85)).resize((1, 1)).getpixel((0, 0))
    d.rounded_rectangle((250, 22, 405, 82), 8, fill=tile)
    f = font('SemiBold', 44)
    d.text((395 - f.getlength('9:41'), 28), '9:41', font=f, fill=(255, 255, 255))
    sw = int(w * 0.86)
    sh = int(scr.height * sw / scr.width)
    bezel = int((w - sw) / 2)
    h = sh + 2 * bezel
    shadow(base, (x, y, x + w, y + h), w * 0.24, 18 * u, 0.35, 10 * u)
    body = Image.new('RGBA', (w, h), (22, 22, 24, 255))
    ImageDraw.Draw(body).rounded_rectangle((0, 0, w - 1, h - 1), int(w * 0.24), outline=(70, 70, 76), width=max(2, int(u)))
    body.alpha_composite(rounded(scr.resize((sw, sh), Image.LANCZOS), sw * 0.2), (bezel, bezel))
    crown = Image.new('RGBA', (int(w * 0.06), int(h * 0.16)), (60, 60, 64, 255))
    base.alpha_composite(rounded(crown, crown.width / 2), (int(x + w - crown.width / 3), int(y + h * 0.26)))
    base.alpha_composite(rounded(body, w * 0.24), (x, y))


def watch_and_widgets_ios(img, u, m, top):
    W = img.width
    wdir = os.path.join(RAW, 'widgets')
    left = int(22 * u)
    full = W - 2 * left
    # Lock screen: big clock, the rectangular widget under it.
    panel_h = int(full * 0.52)
    brand = hex_rgb(BRAND[m])
    panel = Image.new('RGBA', (full, panel_h), (0, 0, 0, 255))
    pd = ImageDraw.Draw(panel)
    for yy in range(panel_h):
        t = yy / panel_h
        col = tuple(int(b * (0.55 - 0.35 * t) + 12 * t) for b in brand)
        pd.line((0, yy, full, yy), fill=col + (255,))
    f = font('SemiBold', panel_h * 0.36)
    tw = f.getlength('9:41')
    pd.text(((full - tw) / 2, panel_h * 0.06), '9:41', font=f, fill=(255, 255, 255, 235))
    lock = Image.open(os.path.join(wdir, f'{m}_lock.png')).convert('RGBA')
    lw = int(full * 0.46)
    lock = lock.resize((lw, int(lock.height * lw / lock.width)), Image.LANCZOS)
    panel.alpha_composite(lock, (int((full - lw) / 2), int(panel_h * 0.58)))
    shadow(img, (left, top, left + full, top + panel_h), 26 * u, 16 * u, 0.3, 10 * u)
    img.alpha_composite(rounded(panel, 26 * u), (left, int(top)))
    # Home screen: the medium widget, then the small one beside the watch.
    y = int(top + panel_h + 14 * u)
    med = Image.open(os.path.join(wdir, f'{m}_medium.png')).convert('RGBA')
    med = med.resize((full, int(med.height * full / med.width)), Image.LANCZOS)
    shadow(img, (left, y, left + full, y + med.height), 22 * u, 14 * u, 0.3, 8 * u)
    img.alpha_composite(med, (left, y))
    y2 = int(y + med.height + 14 * u)
    sm = Image.open(os.path.join(wdir, f'{m}_small.png')).convert('RGBA')
    sw = int(full * 0.47)
    sm = sm.resize((sw, sw), Image.LANCZOS)
    shadow(img, (left, y2, left + sw, y2 + sw), 22 * u, 14 * u, 0.3, 8 * u)
    img.alpha_composite(sm, (left, y2))
    watch_ios(img, u, m, int(left + full - full * 0.47), int(y2 - 4 * u), int(full * 0.47))


def widgets_android(img, u, m, top, wear=True):
    raw = os.path.join(RAW, 'android', f'{m}_widget.png')
    # Start below the launcher's date line (system language, not the market's).
    phone(img, u, raw, top, src_top=420)
    if not wear:
        return
    wear = Image.open(os.path.join(RAW, 'wear', f'{m}_card.png')).convert('RGBA')
    dia = int(150 * u)
    ring = int(12 * u)
    x = int(img.width - dia - 2 * ring - 10 * u)
    y = int(img.height - dia - 2 * ring - 24 * u)
    shadow(img, (x, y, x + dia + 2 * ring, y + dia + 2 * ring), (dia + 2 * ring) / 2, 16 * u, 0.4, 10 * u)
    body = Image.new('RGBA', (dia + 2 * ring, dia + 2 * ring), (0, 0, 0, 0))
    ImageDraw.Draw(body).ellipse((0, 0, body.width - 1, body.height - 1), fill=(24, 24, 26, 255), outline=(80, 80, 86, 255), width=max(2, int(u)))
    face = wear.resize((dia, dia), Image.LANCZOS)
    mask = Image.new('L', face.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, dia - 1, dia - 1), fill=255)
    face.putalpha(mask)
    body.alpha_composite(face, (ring, ring))
    img.alpha_composite(body, (x, y))


# --------------------------------------------------------------------------
# Apple creative assets and the Play feature graphic
# --------------------------------------------------------------------------

def tiles(platform, m, n=6):
    shot = os.path.join(RAW, platform, f'{m}_grid.png')
    im = Image.open(shot).convert('RGB')
    return [im.crop(b) for b in BOXES[platform]['tiles'][:n]]


def hero(size, platform, m, headline, sub, wordmark=True):
    """Dark stage: wordmark + headline on the left, the market's real cards fanned
    on the right and the checkout screen in front of them."""
    W, H = size
    brand = hex_rgb(BRAND[m])
    img = background(size, DARK, glow=brand)
    u = H / 300
    left = int(W * 0.08)
    ty = H * 0.26
    if wordmark:
        fw = font('Bold', 22 * u)
        ImageDraw.Draw(img).text((left, ty - 34 * u), 'Deckard', font=fw, fill=TANGERINE)
    bottom = caption(img, u, headline, sub, (255, 255, 255), top=ty, left=left,
                     max_w=W * 0.42, title_size=40, sub_size=13)
    # Cards fanned behind the phone.
    cards = tiles(platform, m)
    cw = int(H * 0.40)
    cx0 = int(W * 0.54)
    for k, t in enumerate(reversed(cards[:5])):
        card = rounded(t.resize((cw, int(t.height * cw / t.width)), Image.LANCZOS), cw * 0.07)
        ang = [-22, -11, 0, 11, 22][k]
        rot = card.rotate(ang, expand=True, resample=Image.BICUBIC)
        x = int(cx0 + k * cw * 0.22)
        y = int(H * 0.22 + abs(ang) * u * 0.9)
        img.alpha_composite(rot, (x, y))
    # Checkout in front, lower right, cropped to the barcode panel.
    shot = os.path.join(RAW, platform, f'{m}_checkout.png')
    raw = Image.open(shot).convert('RGB')
    pw = int(H * 0.40)
    ph = int(H * 0.82)
    scr = raw.resize((pw, int(raw.height * pw / raw.width)), Image.LANCZOS).crop((0, 0, pw, ph))
    bez = int(pw * 0.03)
    px = int(W * 0.80 - pw / 2)
    py = int(H * 0.30)
    shadow(img, (px, py, px + pw + 2 * bez, py + ph + 2 * bez), pw * 0.12, 20 * u, 0.45, 12 * u)
    body = Image.new('RGBA', (pw + 2 * bez, ph + 2 * bez), (17, 17, 17, 255))
    body.alpha_composite(rounded(scr, pw * 0.1), (bez, bez))
    img.alpha_composite(rounded(body, pw * 0.12), (px, py))
    return img.convert('RGB')


def main():
    for m in MARKETS:
        c = CAPS[m]
        a_loc, p_loc = APPSTORE_LOCALE[m], PLAY_LOCALE[m]
        ios_dir = os.path.join(ROOT, 'fastlane', 'screenshots', a_loc)
        ca_dir = os.path.join(ROOT, 'fastlane', 'creative_assets', a_loc)
        play_dir = os.path.join(ROOT, 'fastlane', 'metadata', 'android', p_loc, 'images')
        alt_dir = os.path.join(ROOT, 'fastlane', 'alt', 'android', p_loc)
        wear_dir = os.path.join(ROOT, 'fastlane', 'later', 'wear', p_loc)
        for d in (ios_dir, ca_dir, os.path.join(play_dir, 'phoneScreenshots'), alt_dir, wear_dir):
            os.makedirs(d, exist_ok=True)
        for i in range(1, 7):
            frame('ios', m, i, (1290, 2796)).save(os.path.join(ios_dir, f'iPhone69_{i}.png'), optimize=True)
            frame('android', m, i, (1080, 1920)).save(os.path.join(play_dir, 'phoneScreenshots', f'{i}.png'), optimize=True)
        frame('android', m, 4, (1080, 1920), wear=False).save(os.path.join(alt_dir, '4_without_wear.png'), optimize=True)
        hero((5244, 2950), 'ios', m, c['f1'], c['s1']).save(os.path.join(ca_dir, 'header_5244x2950.png'), optimize=True)
        hero((3840, 1646), 'ios', m, c['f1'], c['s1']).save(os.path.join(ca_dir, 'search_3840x1646.png'), optimize=True)
        hero((1024, 500), 'android', m, c['f1'], c['s1']).save(os.path.join(play_dir, 'featureGraphic.png'), optimize=True)
        src = os.path.join(RAW, 'wear', f'{m}_card.png')
        if os.path.exists(src):
            Image.open(src).convert('RGB').save(os.path.join(wear_dir, '1.png'))
        print('done', m)


if __name__ == '__main__':
    main()
