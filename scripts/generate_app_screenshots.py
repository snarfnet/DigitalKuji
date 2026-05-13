from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path("MarketingAssets/Screenshots")

SIZES = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "ipad129": (2048, 2732),
}

RED = (214, 37, 37)
DARK_RED = (128, 12, 12)
BG = (248, 248, 250)
TEXT = (24, 24, 27)
SUB = (108, 108, 114)
LINE = (226, 226, 232)
PANEL = (255, 255, 255)


def font(size, weight="regular"):
    candidates = {
        "bold": [
            r"C:\Windows\Fonts\YuGothB.ttc",
            r"C:\Windows\Fonts\meiryob.ttc",
            r"C:\Windows\Fonts\arialbd.ttf",
        ],
        "regular": [
            r"C:\Windows\Fonts\YuGothM.ttc",
            r"C:\Windows\Fonts\YuGothR.ttc",
            r"C:\Windows\Fonts\meiryo.ttc",
            r"C:\Windows\Fonts\arial.ttf",
        ],
    }
    for path in candidates[weight]:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def text_size(draw, text, fnt):
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def centered(draw, xy, text, fnt, fill=TEXT):
    x, y = xy
    w, h = text_size(draw, text, fnt)
    draw.text((x - w / 2, y - h / 2), text, font=fnt, fill=fill)


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def app_canvas(size):
    img = Image.new("RGB", size, BG)
    draw = ImageDraw.Draw(img)
    w, h = size
    top = int(h * 0.035)
    draw.text((w * 0.08, top), "9:41", font=font(int(w * 0.035), "bold"), fill=TEXT)
    draw.text((w * 0.82, top), "5G  100%", font=font(int(w * 0.027)), fill=TEXT)
    title_y = int(h * 0.105)
    draw.text((w * 0.06, title_y), "デジタルくじ引き", font=font(int(w * 0.064), "bold"), fill=TEXT)
    return img, draw


def segmented(draw, w, y, active):
    x = int(w * 0.06)
    seg_w = int(w * 0.88)
    seg_h = int(w * 0.09)
    rounded(draw, (x, y, x + seg_w, y + seg_h), int(seg_h / 3), (232, 232, 237))
    labels = ["数字", "色", "テキスト"]
    cell = seg_w / 3
    for i, label in enumerate(labels):
        lx = x + int(cell * i)
        if i == active:
            rounded(draw, (lx + 5, y + 5, int(lx + cell - 5), y + seg_h - 5), int(seg_h / 3), PANEL)
        centered(draw, (lx + cell / 2, y + seg_h / 2), label, font(int(w * 0.034), "bold" if i == active else "regular"), TEXT)


def nav_draw_screen(draw, w, h):
    y = int(h * 0.088)
    draw.text((w * 0.06, y), "<", font=font(int(w * 0.052), "regular"), fill=RED)
    centered(draw, (w / 2, y + int(w * 0.035)), "デジタルくじ引き", font(int(w * 0.038), "bold"), TEXT)


def bottom_button(draw, w, h, label):
    margin = int(w * 0.06)
    btn_h = int(w * 0.12)
    y = h - int(w * 0.22)
    rounded(draw, (margin, y, w - margin, y + btn_h), int(btn_h * 0.32), RED)
    centered(draw, (w / 2, y + btn_h / 2), label, font(int(w * 0.037), "bold"), (255, 255, 255))


def ad_bar(draw, w, h):
    bar_h = int(w * 0.11)
    y = h - bar_h
    draw.rectangle((0, y, w, h), fill=(241, 241, 244))
    centered(draw, (w / 2, y + bar_h / 2), "Ad", font(int(w * 0.029)), SUB)


def number_setup(size):
    img, draw = app_canvas(size)
    w, h = size
    y = int(h * 0.19)
    segmented(draw, w, y, 0)
    y += int(w * 0.14)
    margin = int(w * 0.06)
    rounded(draw, (margin, y, w - margin, y + int(w * 0.26)), int(w * 0.025), PANEL, LINE)
    draw.text((margin + int(w * 0.04), y + int(w * 0.035)), "範囲設定", font=font(int(w * 0.035), "bold"), fill=TEXT)
    row_y = y + int(w * 0.1)
    for i, (label, val) in enumerate([("最小", "1"), ("最大", "10")]):
        yy = row_y + i * int(w * 0.075)
        draw.text((margin + int(w * 0.04), yy), label, font=font(int(w * 0.033)), fill=TEXT)
        draw.text((w - margin - int(w * 0.19), yy), "−  " + val + "  +", font=font(int(w * 0.033)), fill=TEXT)
    centered(draw, (w / 2, y + int(w * 0.34)), "10 枚のくじが入ります", font(int(w * 0.032)), SUB)
    grid_y = y + int(w * 0.42)
    cell = int(w * 0.096)
    gap = int(w * 0.022)
    start_x = int((w - (cell * 5 + gap * 4)) / 2)
    for n in range(1, 11):
        r = (n - 1) // 5
        c = (n - 1) % 5
        x = start_x + c * (cell + gap)
        yy = grid_y + r * (cell + gap)
        rounded(draw, (x, yy, x + cell, yy + cell), int(cell * 0.2), (253, 232, 232))
        centered(draw, (x + cell / 2, yy + cell / 2), str(n), font(int(w * 0.034), "bold"), RED)
    bottom_button(draw, w, h, "▶  開始する")
    return img


def color_setup(size):
    img, draw = app_canvas(size)
    w, h = size
    y = int(h * 0.19)
    segmented(draw, w, y, 1)
    y += int(w * 0.16)
    margin = int(w * 0.07)
    draw.text((margin, y), "使う色を選んでください", font=font(int(w * 0.035)), fill=SUB)
    colors = [
        ("赤", (240, 55, 55), True), ("青", (45, 107, 255), True),
        ("黄", (255, 204, 0), True), ("緑", (52, 199, 89), True),
        ("紫", (175, 82, 222), False), ("橙", (255, 149, 0), False),
        ("ピンク", (255, 45, 85), False), ("水色", (90, 200, 250), False),
    ]
    grid_y = y + int(w * 0.09)
    cols = 4
    cell_w = (w - margin * 2) / cols
    for i, (name, color, selected) in enumerate(colors):
        row, col = divmod(i, cols)
        cx = margin + cell_w * col + cell_w / 2
        cy = grid_y + row * int(w * 0.21) + int(w * 0.055)
        r = int(w * 0.049)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color, outline=TEXT if selected else LINE, width=5 if selected else 2)
        if selected:
            centered(draw, (cx, cy), "✓", font(int(w * 0.04), "bold"), (255, 255, 255) if name != "黄" else TEXT)
        centered(draw, (cx, cy + int(w * 0.085)), name, font(int(w * 0.027)), TEXT)
    draw.text((margin, grid_y + int(w * 0.45)), "4 色選択中", font=font(int(w * 0.034)), fill=SUB)
    bottom_button(draw, w, h, "▶  開始する")
    return img


def text_setup(size):
    img, draw = app_canvas(size)
    w, h = size
    y = int(h * 0.19)
    segmented(draw, w, y, 2)
    y += int(w * 0.16)
    margin = int(w * 0.06)
    draw.text((margin, y), "くじに入れる項目を追加してください", font=font(int(w * 0.033)), fill=SUB)
    box_y = y + int(w * 0.07)
    rounded(draw, (margin, box_y, w - margin - int(w * 0.12), box_y + int(w * 0.095)), int(w * 0.018), PANEL, LINE)
    draw.text((margin + int(w * 0.03), box_y + int(w * 0.027)), "Aチーム", font=font(int(w * 0.032)), fill=TEXT)
    centered(draw, (w - margin - int(w * 0.045), box_y + int(w * 0.047)), "+", font(int(w * 0.056), "bold"), RED)
    list_y = box_y + int(w * 0.14)
    for i, item in enumerate(["Aチーム", "Bチーム", "Cチーム"]):
        yy = list_y + i * int(w * 0.085)
        rounded(draw, (margin, yy, w - margin, yy + int(w * 0.07)), int(w * 0.018), PANEL, LINE)
        draw.text((margin + int(w * 0.035), yy + int(w * 0.018)), "▣  " + item, font=font(int(w * 0.03)), fill=TEXT)
        draw.text((w - margin - int(w * 0.055), yy + int(w * 0.016)), "−", font=font(int(w * 0.038), "bold"), fill=RED)
    bottom_button(draw, w, h, "▶  開始する")
    return img


def draw_result(size):
    img, draw = app_canvas(size)
    w, h = size
    nav_draw_screen(draw, w, h)
    top_y = int(h * 0.16)
    draw.text((w * 0.06, top_y), "残り 7 枚", font=font(int(w * 0.043), "bold"), fill=TEXT)
    draw.text((w * 0.06, top_y + int(w * 0.045)), "全 10 枚", font=font(int(w * 0.028)), fill=SUB)
    draw.text((w * 0.78, top_y + int(w * 0.02)), "リセット", font=font(int(w * 0.032)), fill=RED)
    card = int(min(w * 0.63, h * 0.28))
    cx, cy = w / 2, h * 0.44
    rounded(draw, (cx - card / 2 + 18, cy - card / 2 + 24, cx + card / 2 + 18, cy + card / 2 + 24), int(card * 0.085), (219, 219, 224))
    rounded(draw, (cx - card / 2, cy - card / 2, cx + card / 2, cy + card / 2), int(card * 0.085), RED)
    draw.rectangle((cx - card / 2, cy, cx + card / 2, cy + card / 2), fill=DARK_RED)
    rounded(draw, (cx - card / 2, cy - card / 2, cx + card / 2, cy + card / 2), int(card * 0.085), None, (255, 255, 255), 3)
    centered(draw, (cx, cy), "7", font(int(w * 0.18), "bold"), (255, 255, 255))
    centered(draw, (w / 2, h * 0.63), "振ってくじを引こう！", font(int(w * 0.033)), SUB)
    hist_y = int(h * 0.70)
    draw.rectangle((0, hist_y, w, hist_y + int(w * 0.22)), fill=(242, 242, 247))
    draw.text((w * 0.06, hist_y + int(w * 0.03)), "履歴", font=font(int(w * 0.027)), fill=SUB)
    draw.text((w * 0.72, hist_y + int(w * 0.03)), "3 枚引いた", font=font(int(w * 0.027)), fill=SUB)
    for i, (txt, fill) in enumerate([("7", RED), ("3", (229, 229, 234)), ("9", (229, 229, 234))]):
        x = int(w * 0.06) + i * int(w * 0.13)
        y = hist_y + int(w * 0.09)
        rounded(draw, (x, y, x + int(w * 0.095), y + int(w * 0.095)), int(w * 0.02), fill)
        centered(draw, (x + int(w * 0.047), y + int(w * 0.047)), txt, font(int(w * 0.03), "bold"), (255, 255, 255) if i == 0 else TEXT)
    ad_bar(draw, w, h)
    return img


SCENES = [number_setup, color_setup, text_setup, draw_result]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for prefix, size in SIZES.items():
        for index, scene in enumerate(SCENES, 1):
            path = OUT / f"{prefix}_{index:02}.png"
            scene(size).save(path, optimize=True)
            print(path)


if __name__ == "__main__":
    main()
