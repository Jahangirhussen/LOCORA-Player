"""Generate a simple geometric logo for LOCORA Player — no AI needed.
Dark rounded-square background, single accent-colored mark: a play-button
merged with a folder tab, representing unified media + files.
"""
from PIL import Image, ImageDraw
import os

SIZE = 512
BG = (10, 10, 10, 255)
ACCENT = (61, 139, 253, 255)
BORDER = (42, 42, 42, 255)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# Rounded square background
radius = 96
d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=radius, fill=BG, outline=BORDER, width=4)

# Folder-tab notch at top-left (file/media library motif)
tab_w, tab_h = 150, 40
d.rounded_rectangle([56, 70, 56 + tab_w, 70 + tab_h], radius=14, fill=(22, 22, 22, 255))

# Centered play triangle in accent color (media playback motif)
cx, cy = SIZE // 2, SIZE // 2 + 20
tri_size = 130
points = [
    (cx - tri_size * 0.45, cy - tri_size * 0.62),
    (cx - tri_size * 0.45, cy + tri_size * 0.62),
    (cx + tri_size * 0.62, cy),
]
d.polygon(points, fill=ACCENT)

out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "logo.png")
img.save(out_path)
print(f"saved {out_path}")
