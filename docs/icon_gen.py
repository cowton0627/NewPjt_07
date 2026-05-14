"""Generate NewPjt_07 App Icon — Moon + Sparkles on deep navy gradient."""
from PIL import Image, ImageDraw, ImageFilter
import random

W = 1024
TOP = (26, 31, 58)     # #1A1F3A
BOTTOM = (5, 9, 24)    # #050918

def gradient_bg() -> Image.Image:
    img = Image.new('RGB', (W, W))
    px = img.load()
    for y in range(W):
        t = y / (W - 1)
        r = int(TOP[0] * (1 - t) + BOTTOM[0] * t)
        g = int(TOP[1] * (1 - t) + BOTTOM[1] * t)
        b = int(TOP[2] * (1 - t) + BOTTOM[2] * t)
        for x in range(W):
            px[x, y] = (r, g, b)
    return img

def add_background_stars(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    random.seed(42)
    for _ in range(60):
        x = random.randint(0, W - 1)
        y = random.randint(0, W - 1)
        s = random.choice([1, 1, 1, 1, 2, 2, 3])
        alpha = random.randint(120, 220)
        d.ellipse((x - s, y - s, x + s, y + s), fill=(alpha, alpha, alpha))

def composite_glow(img: Image.Image, cx: int, cy: int, r: int) -> Image.Image:
    glow = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse(
        (cx - r - 100, cy - r - 100, cx + r + 100, cy + r + 100),
        fill=(255, 245, 220, 70),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))
    base = img.convert('RGBA')
    return Image.alpha_composite(base, glow).convert('RGB')

def draw_moon(img: Image.Image, cx: int, cy: int, r: int) -> None:
    d = ImageDraw.Draw(img)
    moon_color = (245, 240, 232)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=moon_color)

    crater_color = (220, 213, 200)
    craters = [
        (cx - 80, cy - 60, 35),
        (cx + 60, cy + 40, 28),
        (cx - 20, cy + 100, 22),
        (cx + 120, cy - 70, 18),
        (cx - 130, cy + 75, 16),
        (cx + 30, cy - 130, 12),
    ]
    for ox, oy, rad in craters:
        d.ellipse((ox - rad, oy - rad, ox + rad, oy + rad), fill=crater_color)

def draw_sparkle(d: ImageDraw.ImageDraw, cx: int, cy: int, size: int,
                 color=(255, 255, 255)) -> None:
    """4-point sparkle (SF Symbol 'sparkles' style)."""
    half = size / 2
    inner = size * 0.18
    pts = [
        (cx, cy - half),
        (cx + inner, cy - inner),
        (cx + half, cy),
        (cx + inner, cy + inner),
        (cx, cy + half),
        (cx - inner, cy + inner),
        (cx - half, cy),
        (cx - inner, cy - inner),
    ]
    d.polygon(pts, fill=color)

def add_sparkles_with_glow(img: Image.Image, sparkles) -> Image.Image:
    # paint sparkles on a transparent layer then blur a copy for glow
    layer = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for cx, cy, sz in sparkles:
        draw_sparkle(ld, cx, cy, sz)
    glow = layer.filter(ImageFilter.GaussianBlur(radius=8))
    base = img.convert('RGBA')
    out = Image.alpha_composite(base, glow)
    out = Image.alpha_composite(out, layer)
    return out.convert('RGB')

def build() -> Image.Image:
    img = gradient_bg()
    add_background_stars(img)

    moon_cx, moon_cy, moon_r = W // 2 - 40, W // 2 - 30, 250
    img = composite_glow(img, moon_cx, moon_cy, moon_r)
    draw_moon(img, moon_cx, moon_cy, moon_r)

    sparkles = [
        (moon_cx + moon_r + 110, moon_cy - 130, 110),  # big top right
        (moon_cx - moon_r - 90,  moon_cy + 210, 80),   # medium bot left
        (moon_cx + moon_r + 70,  moon_cy + 200, 55),   # small mid right
        (moon_cx - moon_r - 50,  moon_cy - 170, 45),   # small top left
        (moon_cx + 30,           moon_cy + moon_r + 140, 38),  # bottom
        (moon_cx + moon_r + 210, moon_cy + 290, 30),   # tiny bot right
    ]
    img = add_sparkles_with_glow(img, sparkles)
    return img

if __name__ == '__main__':
    out = build()
    out.save('/Users/chunlicheng/Desktop/NewPjt_07/docs/screenshots/app_icon_preview.png',
             optimize=True)
    print('saved preview')
