from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "store_assets" / "source" / "google_play_ar"
OUTPUT = ROOT / "store_assets" / "google_play" / "production_ar"
BRAND = ROOT / "assets" / "branding"
FONTS = ROOT / "assets" / "fonts"

CANVAS_SIZE = (1080, 1920)
PURPLE = (55, 55, 155, 255)
YELLOW = (252, 200, 3, 255)
INK = (28, 28, 56, 255)
MUTED = (91, 91, 113, 255)
WHITE = (255, 255, 255, 255)

TITLE_FONT = FONTS / "IBMPlexSansArabic-Bold.ttf"
BODY_FONT = FONTS / "IBMPlexSansArabic-Regular.ttf"

SCREENS = (
    (
        "01-home.jpg",
        "01-home.png",
        "كل السوق بمكان واحد",
        "اكتشف، اختر، وابدأ البيع.",
        "purple",
    ),
    (
        "02-products.jpg",
        "02-products.png",
        "منتجات تستحق البيع",
        "عروض وأسعار واضحة بلمحة.",
        "yellow",
    ),
    (
        "03-orders.jpg",
        "03-orders.png",
        "تابع طلباتك بسهولة",
        "الحالة والربح في سجل واحد.",
        "purple",
    ),
    (
        "04-wallet.jpg",
        "04-wallet.png",
        "أرباحك أمامك دائماً",
        "رصيدك وحركاتك بوضوح.",
        "yellow",
    ),
    (
        "05-profile.jpg",
        "05-profile.png",
        "كل نشاطك بحساب واحد",
        "طلباتك ومستواك ومكافآتك.",
        "purple",
    ),
)


def rtl(text: str) -> str:
    return get_display(arabic_reshaper.reshape(text))


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size=size)


def resize_exact(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.resize(size, Image.Resampling.LANCZOS)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1),
        radius=radius,
        fill=255,
    )
    return mask


def trimmed_logo(max_size: tuple[int, int]) -> Image.Image:
    logo = Image.open(BRAND / "lugta_wordmark_ink.png").convert("RGBA")
    box = logo.getbbox()
    if box:
        logo = logo.crop(box)
    logo.thumbnail(max_size, Image.Resampling.LANCZOS)
    return logo


def add_phone(
    canvas: Image.Image,
    screenshot_path: Path,
    *,
    accent: tuple[int, int, int, int],
) -> None:
    screenshot = Image.open(screenshot_path).convert("RGB")
    phone_width = 620
    phone_height = round(phone_width * screenshot.height / screenshot.width)
    phone_x = (CANVAS_SIZE[0] - phone_width) // 2
    phone_y = 455
    radius = 50
    frame = 14

    shadow = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (
            phone_x - frame + 4,
            phone_y - frame + 20,
            phone_x + phone_width + frame + 4,
            phone_y + phone_height + frame + 20,
        ),
        radius=radius + frame,
        fill=(24, 19, 72, 98),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(34)))

    frame_layer = Image.new(
        "RGBA",
        (phone_width + frame * 2, phone_height + frame * 2),
        WHITE,
    )
    frame_draw = ImageDraw.Draw(frame_layer)
    frame_draw.rounded_rectangle(
        (0, 0, frame_layer.width - 1, frame_layer.height - 1),
        radius=radius + frame,
        outline=accent,
        width=4,
    )
    canvas.paste(
        frame_layer,
        (phone_x - frame, phone_y - frame),
        rounded_mask(frame_layer.size, radius + frame),
    )

    screenshot = resize_exact(screenshot, (phone_width, phone_height))
    canvas.paste(
        screenshot,
        (phone_x, phone_y),
        rounded_mask((phone_width, phone_height), radius),
    )


def add_header(
    canvas: Image.Image,
    *,
    title: str,
    subtitle: str,
    accent: tuple[int, int, int, int],
) -> None:
    draw = ImageDraw.Draw(canvas)
    logo = trimmed_logo((246, 105))
    canvas.alpha_composite(logo, (70, 58))

    title_font = font(TITLE_FONT, 62)
    body_font = font(BODY_FONT, 33)
    right = 815
    draw.text(
        (right, 192),
        rtl(title),
        font=title_font,
        fill=INK,
        anchor="ra",
    )
    draw.text(
        (right, 282),
        rtl(subtitle),
        font=body_font,
        fill=MUTED,
        anchor="ra",
    )
    draw.rounded_rectangle((right - 108, 349, right, 361), radius=99, fill=accent)


def build_background(kind: str) -> Image.Image:
    filename = "template-yellow.png" if kind == "yellow" else "template-purple.png"
    # The supplied templates store their visible RGB artwork under mostly-zero
    # alpha. Drop that export alpha before resizing; otherwise Pillow correctly
    # premultiplies it and the white/brand fields collapse to black.
    background = Image.open(SOURCE / filename).convert("RGB")
    return resize_exact(background, CANVAS_SIZE).convert("RGBA")


def make_contact_sheet(paths: list[Path]) -> Path:
    thumb_size = (243, 432)
    padding = 28
    columns = 3
    rows = 2
    sheet = Image.new(
        "RGB",
        (
            padding + columns * (thumb_size[0] + padding),
            padding + rows * (thumb_size[1] + 86 + padding),
        ),
        (241, 240, 250),
    )
    draw = ImageDraw.Draw(sheet)
    label_font = font(TITLE_FONT, 26)
    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGB").resize(thumb_size, Image.Resampling.LANCZOS)
        column = index % columns
        row = index // columns
        x = padding + column * (thumb_size[0] + padding)
        y = padding + row * (thumb_size[1] + 86 + padding)
        sheet.paste(image, (x, y))
        draw.text(
            (x + thumb_size[0] // 2, y + thumb_size[1] + 37),
            rtl(f"الصورة {index + 1}"),
            font=label_font,
            fill=INK,
            anchor="mm",
        )
    destination = OUTPUT / "preview-contact-sheet.jpg"
    sheet.save(destination, quality=92, optimize=True)
    return destination


def make_zip(paths: list[Path]) -> Path:
    destination = OUTPUT / "lugta-google-play-ar-1080x1920.zip"
    with ZipFile(destination, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in paths:
            archive.write(path, arcname=path.name)
    return destination


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    results: list[Path] = []
    for source_name, output_name, title, subtitle, kind in SCREENS:
        canvas = build_background(kind)
        accent = YELLOW if kind == "purple" else PURPLE
        add_header(canvas, title=title, subtitle=subtitle, accent=accent)
        add_phone(canvas, SOURCE / source_name, accent=accent)
        destination = OUTPUT / output_name
        canvas.convert("RGB").save(destination, format="PNG", optimize=True)
        results.append(destination)

    preview = make_contact_sheet(results)
    bundle = make_zip(results)
    for path in [*results, preview, bundle]:
        print(path)


if __name__ == "__main__":
    main()
