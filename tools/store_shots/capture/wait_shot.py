import sys, subprocess, time
from PIL import Image, ImageChops, ImageStat
# usage: wait_shot.py out.png ref.png platform(android|ios) [settle]
out, ref, plat = sys.argv[1], sys.argv[2], sys.argv[3]
settle = float(sys.argv[4]) if len(sys.argv) > 4 else 3
R = Image.open(ref).convert('L').resize((108, 240))
def grab(path):
    if plat == 'android':
        with open(path, 'wb') as f:
            subprocess.run(['/tmp/a', 'exec-out', 'screencap', '-p'], stdout=f)
    else:
        d = open('/tmp/iphone_id').read().strip()
        subprocess.run(['xcrun', 'simctl', 'io', d, 'screenshot', '--type=png', path], capture_output=True)
t0 = time.time()
while time.time() - t0 < 70:
    time.sleep(2)
    grab(out)
    try:
        im = Image.open(out).convert('L').resize((108, 240))
    except Exception:
        continue
    diff = ImageStat.Stat(ImageChops.difference(im, R)).mean[0]
    if diff > 12:
        time.sleep(settle)
        grab(out)
        print('ok', round(diff, 1), round(time.time() - t0)); sys.exit(0)
print('TIMEOUT'); sys.exit(1)
