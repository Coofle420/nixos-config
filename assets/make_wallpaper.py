from PIL import Image, ImageDraw
import math

W, H = 2560, 1440
HORIZON = 900
VP = (W // 2, HORIZON)

img = Image.new("RGB", (W, H), "#000000")
px = img.load()


def lerp(a, b, t):
    return a + (b - a) * t


def lerp_color(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


SKY_TOP = (10, 2, 33)      # near-black indigo
SKY_MID = (43, 12, 79)     # deep purple
SKY_HORIZON = (120, 20, 90)  # magenta haze at horizon

for y in range(HORIZON):
    t = y / HORIZON
    if t < 0.6:
        c = lerp_color(SKY_TOP, SKY_MID, t / 0.6)
    else:
        c = lerp_color(SKY_MID, SKY_HORIZON, (t - 0.6) / 0.4)
    for x in range(0, W, 4):
        for dx in range(4):
            if x + dx < W:
                px[x + dx, y] = c

FLOOR = (12, 4, 26)
for y in range(HORIZON, H):
    for x in range(0, W, 4):
        for dx in range(4):
            if x + dx < W:
                px[x + dx, y] = FLOOR

draw = ImageDraw.Draw(img, "RGBA")

# --- Sun: horizontal band gradient with a few retro gap stripes ---
sun_cx, sun_cy, sun_r = W // 2, 760, 270
SUN_TOP = (255, 214, 92)     # warm yellow
SUN_MID = (255, 100, 92)     # coral
SUN_BOT = (255, 46, 136)     # hot pink

sun_img = Image.new("RGBA", (sun_r * 2, sun_r * 2), (0, 0, 0, 0))
sd = sun_img.load()
for yy in range(sun_r * 2):
    t = yy / (sun_r * 2)
    if t < 0.5:
        c = lerp_color(SUN_TOP, SUN_MID, t / 0.5)
    else:
        c = lerp_color(SUN_MID, SUN_BOT, (t - 0.5) / 0.5)
    for xx in range(sun_r * 2):
        dx = xx - sun_r
        dy = yy - sun_r
        if dx * dx + dy * dy <= sun_r * sun_r:
            sd[xx, yy] = (c[0], c[1], c[2], 255)

# retro gap stripes across the lower half of the sun
stripe_bands = [
    (0.55, 0.59), (0.66, 0.70), (0.76, 0.79), (0.85, 0.87), (0.92, 0.935),
]
for (a, b) in stripe_bands:
    y0, y1 = int(a * sun_r * 2), int(b * sun_r * 2)
    for yy in range(y0, min(y1, sun_r * 2)):
        for xx in range(sun_r * 2):
            dx = xx - sun_r
            dy = yy - sun_r
            if dx * dx + dy * dy <= sun_r * sun_r:
                sd[xx, yy] = (0, 0, 0, 0)

img.paste(sun_img, (sun_cx - sun_r, sun_cy - sun_r), sun_img)

# soft glow ring around sun
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for i, rad in enumerate(range(sun_r + 10, sun_r + 140, 6)):
    alpha = int(30 * (1 - i / 22))
    if alpha <= 0:
        continue
    gd.ellipse(
        [sun_cx - rad, sun_cy - rad, sun_cx + rad, sun_cy + rad],
        outline=(255, 90, 160, alpha),
        width=3,
    )
img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")
draw = ImageDraw.Draw(img, "RGBA")

# --- Perspective grid floor ---
GRID_MAG = (255, 46, 136, 160)
GRID_CYAN = (5, 217, 232, 130)

# horizontal lines, spaced with perspective (denser near horizon)
n_h = 26
for i in range(1, n_h + 1):
    t = i / n_h
    y = HORIZON + (H - HORIZON) * (t ** 2.4)
    if y >= H:
        continue
    fade = max(0, 1 - t * 0.15)
    a = int(150 * fade)
    draw.line([(0, y), (W, y)], fill=(150, 40, 200, a), width=2)

# converging vertical lines to the vanishing point
n_v = 22
span = 3200
for i in range(-n_v, n_v + 1):
    x_bottom = VP[0] + i * (span / n_v)
    draw.line([VP, (x_bottom, H)], fill=GRID_MAG, width=2)

# horizon glow line
draw.line([(0, HORIZON), (W, HORIZON)], fill=(255, 120, 180, 220), width=3)

# a few faint stars up top
import random
random.seed(42)
for _ in range(140):
    x = random.randint(0, W - 1)
    y = random.randint(0, int(HORIZON * 0.7))
    b = random.randint(120, 255)
    draw.point((x, y), fill=(b, b, min(255, b + 20)))

out_path = "/home/kenny/nixos-config/assets/synthwave-grid.png"
img.save(out_path, "PNG")
print("saved", out_path, img.size)
