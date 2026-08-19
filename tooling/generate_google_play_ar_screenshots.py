from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "store_assets" / "source" / "google_play_ar"
SANITIZED_SOURCE = ROOT / "store_assets" / "source" / "google_play_ar_sanitized"
OUTPUT = ROOT / "store_assets" / "google_play" / "production_ar_sanitized"
BRAND = ROOT / "assets" / "branding"
FONTS = ROOT / "assets" / "fonts"

CANVAS_SIZE = (1080, 1920)
PURPLE = (55, 55, 155, 255)
YELLOW = (252, 200, 3, 255)
INK = (28, 28, 56, 255)
MUTED = (91, 91, 113, 255)
WHITE = (255, 255, 255, 255)
APP_SURFACE = (248, 248, 253, 255)
CARD_BORDER = (229, 228, 238, 255)
SOFT_PURPLE = (237, 236, 250, 255)
SOFT_YELLOW = (255, 246, 194, 255)

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


def draw_watch_art(
    image: Image.Image,
    box: tuple[int, int, int, int],
    *,
    variant: int,
) -> None:
    """Draw a deterministic, brand-free watch illustration inside ``box``."""

    palettes = (
        ((238, 236, 250), (46, 44, 92), (252, 200, 3)),
        ((255, 246, 194), (91, 65, 27), (55, 55, 155)),
        ((232, 244, 242), (28, 83, 74), (252, 200, 3)),
        ((241, 232, 236), (91, 42, 57), (55, 55, 155)),
        ((232, 235, 245), (42, 48, 74), (252, 200, 3)),
    )
    background, strap, accent = palettes[variant % len(palettes)]
    draw = ImageDraw.Draw(image)
    left, top, right, bottom = box
    width = right - left
    height = bottom - top
    radius = max(8, min(width, height) // 10)
    draw.rounded_rectangle(box, radius=radius, fill=background)

    center_x = (left + right) // 2
    center_y = (top + bottom) // 2
    strap_width = max(10, width // 7)
    face_radius = max(14, min(width, height) // 4)
    draw.rounded_rectangle(
        (
            center_x - strap_width // 2,
            top + height // 12,
            center_x + strap_width // 2,
            bottom - height // 12,
        ),
        radius=max(4, strap_width // 3),
        fill=strap,
    )
    draw.ellipse(
        (
            center_x - face_radius,
            center_y - face_radius,
            center_x + face_radius,
            center_y + face_radius,
        ),
        fill=WHITE[:3],
        outline=strap,
        width=max(2, face_radius // 7),
    )
    hand_width = max(2, face_radius // 9)
    draw.line(
        (center_x, center_y, center_x, center_y - face_radius // 2),
        fill=accent,
        width=hand_width,
    )
    draw.line(
        (center_x, center_y, center_x + face_radius // 2, center_y),
        fill=accent,
        width=hand_width,
    )
    draw.ellipse(
        (
            center_x - hand_width,
            center_y - hand_width,
            center_x + hand_width,
            center_y + hand_width,
        ),
        fill=accent,
    )


def sanitize_home(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    # Replace the third-party campaign photograph with a brand-owned panel.
    draw.rounded_rectangle((38, 267, 544, 486), radius=32, fill=(55, 55, 155))
    draw.ellipse((22, 321, 240, 539), fill=(67, 67, 171))
    draw_watch_art(image, (76, 289, 235, 465), variant=1)
    draw.text(
        (516, 344),
        rtl("مختارات اليوم"),
        font=font(TITLE_FONT, 27),
        fill=WHITE,
        anchor="ra",
    )
    draw.text(
        (516, 386),
        rtl("منتجات جاهزة للبيع"),
        font=font(BODY_FONT, 20),
        fill=SOFT_YELLOW,
        anchor="ra",
    )

    # Product photography may carry tiny dial marks. Replace it with neutral,
    # deterministic artwork instead of trying to blur unknown trademarks.
    draw_watch_art(image, (37, 953, 274, 1175), variant=0)
    draw_watch_art(image, (307, 953, 544, 1175), variant=3)


def sanitize_products(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    title = font(TITLE_FONT, 22)

    # Discount product image and every visible catalogue image are replaced;
    # the originals remain untouched in SOURCE.
    draw_watch_art(image, (311, 344, 544, 560), variant=4)
    draw_watch_art(image, (37, 784, 273, 998), variant=2)
    draw_watch_art(image, (308, 784, 544, 998), variant=3)

    draw.rounded_rectangle((306, 564, 551, 620), radius=8, fill=WHITE)
    draw.text(
        (540, 587),
        rtl("ساعة جلدية كلاسيكية"),
        font=title,
        fill=INK,
        anchor="ra",
    )
    draw.rectangle((35, 1000, 276, 1050), fill=WHITE)
    draw.text(
        (263, 1022),
        rtl("ساعة يومية سوداء"),
        font=title,
        fill=INK,
        anchor="ra",
    )
    draw.rectangle((306, 1000, 551, 1050), fill=WHITE)
    draw.text(
        (538, 1022),
        rtl("ساعة يومية حمراء"),
        font=title,
        fill=INK,
        anchor="ra",
    )

    # The next catalogue row is only partially visible behind the floating
    # navigation bar. Neutralize both exposed edges so no dial mark or brand
    # survives at the top or bottom of the store screenshot.
    draw.rounded_rectangle(
        (37, 1148, 273, 1188),
        radius=12,
        fill=SOFT_PURPLE[:3],
    )
    draw.rounded_rectangle(
        (308, 1148, 544, 1188),
        radius=12,
        fill=SOFT_YELLOW[:3],
    )
    draw.rectangle((0, 1260, 582, 1280), fill=APP_SURFACE[:3])


def sanitize_orders(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    title_font = font(TITLE_FONT, 19)
    detail_font = font(BODY_FONT, 16)
    badge_font = font(TITLE_FONT, 14)
    age_font = font(BODY_FONT, 14)
    rows = (
        (244, "ساعة جلدية كلاسيكية", "طلب ٠٠١ • زبون تجريبي • بغداد", "ملغي", "منذ يوم", (241, 240, 248), MUTED[:3]),
        (438, "ساعة معدنية أنيقة", "طلب ٠٠٢ • زبون تجريبي • البصرة", "تم التسليم", "منذ ٣ أيام", (230, 247, 240), (25, 132, 92)),
        (632, "ساعة رياضية يومية", "طلب ٠٠٣ • زبون تجريبي • بابل", "تم التسليم", "منذ ٧ أيام", (230, 247, 240), (25, 132, 92)),
        (826, "ساعة جلدية داكنة", "طلب ٠٠٤ • زبون تجريبي • نينوى", "ملغي", "منذ ١٢ يوماً", (241, 240, 248), MUTED[:3]),
        (1020, "ساعة عملية خفيفة", "طلب ٠٠٥ • زبون تجريبي • أربيل", "مرتجع", "منذ ١٤ يوماً", (253, 235, 238), (181, 55, 66)),
    )
    for index, (
        top,
        product_name,
        details,
        status,
        age,
        badge_fill,
        badge_color,
    ) in enumerate(rows):
        # Rebuild the complete informational area rather than placing small
        # patches over unknown live data. The status/profit strip is preserved.
        draw.rectangle((32, top - 12, 458, top + 83), fill=WHITE[:3])
        draw.rounded_rectangle(
            (43, top - 3, 145, top + 27),
            radius=15,
            fill=badge_fill,
        )
        draw.text(
            (94, top + 11),
            rtl(status),
            font=badge_font,
            fill=badge_color,
            anchor="mm",
        )
        draw.text(
            (133, top + 53),
            rtl(age),
            font=age_font,
            fill=MUTED[:3],
            anchor="ra",
        )
        draw.text(
            (451, top + 15),
            rtl(product_name),
            font=title_font,
            fill=INK,
            anchor="ra",
        )
        draw.text(
            (451, top + 52),
            rtl(details),
            font=detail_font,
            fill=MUTED,
            anchor="ra",
        )
        draw_watch_art(image, (462, top - 9, 540, top + 69), variant=index)

    # Nothing below the floating navigation bar should reveal another live
    # order or product thumbnail.
    draw.rectangle((0, 1260, 582, 1280), fill=APP_SURFACE[:3])


def sanitize_wallet(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    amount_font = font(TITLE_FONT, 25)
    small_amount_font = font(TITLE_FONT, 19)

    # Replace live-looking account totals with unmistakably synthetic demo data.
    draw.rounded_rectangle((346, 250, 536, 326), radius=14, fill=(55, 55, 155))
    draw.text(
        (521, 282),
        rtl("٤٨,٠٠٠ د.ع"),
        font=amount_font,
        fill=WHITE,
        anchor="ra",
    )
    draw.rounded_rectangle((147, 372, 316, 423), radius=10, fill=(55, 55, 155))
    draw.text(
        (302, 393),
        rtl("١٢٠,٠٠٠ د.ع"),
        font=small_amount_font,
        fill=WHITE,
        anchor="ra",
    )
    draw.rounded_rectangle((370, 372, 529, 423), radius=10, fill=(55, 55, 155))
    draw.text(
        (516, 393),
        rtl("١٨,٠٠٠ د.ع"),
        font=small_amount_font,
        fill=YELLOW,
        anchor="ra",
    )

    # Sales summary values.
    draw.rectangle((29, 815, 552, 858), fill=WHITE)
    summary_font = font(TITLE_FONT, 19)
    for x, value, color in (
        (515, "٨", INK),
        (341, "١٦٠,٠٠٠ د.ع", INK),
        (175, "٥٤,٠٠٠ د.ع", (25, 132, 92, 255)),
    ):
        draw.text((x, 831), rtl(value), font=summary_font, fill=color, anchor="ra")

    # Transaction identifiers and amounts are synthetic as well.
    transactions = (
        (930, "تسوية طلب تجريبي", "طلب ٠٠١ • منذ يوم", "-٥,٠٠٠ د.ع", (181, 55, 66)),
        (1024, "ربح طلب تجريبي", "طلب ٠٠٢ • منذ يومين", "+٩,٠٠٠ د.ع", (116, 93, 10)),
        (1118, "تسوية طلب تجريبي", "طلب ٠٠٣ • منذ ٣ أيام", "-٧,٠٠٠ د.ع", (181, 55, 66)),
    )
    detail_font = font(BODY_FONT, 15)
    value_font = font(TITLE_FONT, 18)
    transaction_title_font = font(TITLE_FONT, 18)
    for top, transaction_title, detail, value, value_color in transactions:
        # Replace the full text area to prevent an old order number or amount
        # from remaining around the edges of a narrower patch.
        draw.rectangle((27, top, 463, top + 89), fill=WHITE[:3])
        draw.text(
            (451, top + 24),
            rtl(transaction_title),
            font=transaction_title_font,
            fill=INK[:3],
            anchor="ra",
        )
        draw.text(
            (451, top + 57),
            rtl(detail),
            font=detail_font,
            fill=MUTED,
            anchor="ra",
        )
        draw.text(
            (171, top + 38),
            rtl(value),
            font=value_font,
            fill=value_color,
            anchor="ra",
        )

    draw.rectangle((0, 1260, 582, 1280), fill=APP_SURFACE[:3])


def sanitize_profile(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image)
    # Rebuild the identity card with explicit demo details. This avoids exposing
    # a real name, phone number, username, avatar initials, or account age.
    draw.rounded_rectangle(
        (26, 164, 556, 454),
        radius=28,
        fill=WHITE,
        outline=CARD_BORDER,
        width=2,
    )
    draw.ellipse((445, 188, 531, 274), fill=WHITE, outline=YELLOW, width=4)
    draw.text(
        (488, 229),
        rtl("لك"),
        font=font(TITLE_FONT, 24),
        fill=INK,
        anchor="mm",
    )
    draw.rounded_rectangle((129, 190, 249, 230), radius=20, fill=YELLOW)
    draw.text(
        (239, 206),
        rtl("حساب عرض"),
        font=font(TITLE_FONT, 16),
        fill=INK,
        anchor="ra",
    )
    draw.text(
        (432, 205),
        rtl("متجر تجريبي"),
        font=font(TITLE_FONT, 23),
        fill=INK,
        anchor="ra",
    )
    draw.text(
        (432, 246),
        "lugta_demo",
        font=font(BODY_FONT, 20),
        fill=MUTED,
        anchor="ra",
    )
    draw.text(
        (432, 284),
        "0770 000 0000",
        font=font(BODY_FONT, 18),
        fill=MUTED,
        anchor="ra",
    )
    draw.text(
        (432, 322),
        "@lugta_demo",
        font=font(BODY_FONT, 18),
        fill=(116, 93, 10),
        anchor="ra",
    )
    draw.line((51, 371, 531, 371), fill=CARD_BORDER, width=2)
    draw.text(
        (515, 407),
        rtl("بيانات تجريبية للعرض فقط"),
        font=font(BODY_FONT, 18),
        fill=MUTED,
        anchor="ra",
    )

    # Rewards and counters are account data too. Rebuild the visible cards
    # with zeroed, explicit demo values instead of retaining live totals.
    draw.rounded_rectangle(
        (26, 482, 556, 689),
        radius=28,
        fill=SOFT_PURPLE[:3],
        outline=CARD_BORDER[:3],
        width=2,
    )
    draw.rounded_rectangle((457, 507, 531, 579), radius=17, fill=SOFT_YELLOW[:3])
    draw.ellipse((480, 526, 508, 554), outline=(116, 93, 10), width=3)
    draw.text(
        (435, 526),
        rtl("مستوى العرض والمكافآت"),
        font=font(TITLE_FONT, 23),
        fill=INK[:3],
        anchor="ra",
    )
    draw.text(
        (435, 566),
        rtl("حساب تجريبي • ٠ نقطة"),
        font=font(BODY_FONT, 19),
        fill=MUTED[:3],
        anchor="ra",
    )
    draw.rounded_rectangle((52, 608, 530, 620), radius=6, fill=WHITE[:3])
    draw.rounded_rectangle((52, 608, 163, 620), radius=6, fill=YELLOW[:3])
    draw.text(
        (515, 655),
        rtl("قيم تجريبية لأغراض العرض فقط"),
        font=font(BODY_FONT, 17),
        fill=MUTED[:3],
        anchor="ra",
    )

    stats = (
        ((26, 715, 556, 902), "٠", "طلبات العرض", (226, 236, 253), (55, 105, 167)),
        ((26, 919, 556, 1105), "٠", "طلبات مكتملة للعرض", (230, 247, 240), (25, 132, 92)),
    )
    for box, value, label, icon_fill, icon_color in stats:
        draw.rounded_rectangle(
            box,
            radius=28,
            fill=WHITE[:3],
            outline=CARD_BORDER[:3],
            width=2,
        )
        center_x = (box[0] + box[2]) // 2
        draw.ellipse((center_x - 31, box[1] + 30, center_x + 31, box[1] + 92), fill=icon_fill)
        draw.ellipse((center_x - 8, box[1] + 53, center_x + 8, box[1] + 69), fill=icon_color)
        draw.text(
            (center_x, box[1] + 118),
            rtl(value),
            font=font(TITLE_FONT, 23),
            fill=INK[:3],
            anchor="mm",
        )
        draw.text(
            (center_x, box[1] + 158),
            rtl(label),
            font=font(BODY_FONT, 19),
            fill=MUTED[:3],
            anchor="mm",
        )

    draw.rounded_rectangle(
        (26, 1120, 556, 1188),
        radius=28,
        fill=WHITE[:3],
        outline=CARD_BORDER[:3],
        width=2,
    )
    draw.text(
        (530, 1152),
        rtl("إحصاءات تجريبية"),
        font=font(TITLE_FONT, 19),
        fill=MUTED[:3],
        anchor="ra",
    )
    draw.rectangle((0, 1260, 582, 1280), fill=APP_SURFACE[:3])


def sanitize_screenshot(source_name: str, image: Image.Image) -> Image.Image:
    if image.size != (582, 1280):
        raise ValueError(f"Unexpected source size for {source_name}: {image.size}")
    sanitizers = {
        "01-home.jpg": sanitize_home,
        "02-products.jpg": sanitize_products,
        "03-orders.jpg": sanitize_orders,
        "04-wallet.jpg": sanitize_wallet,
        "05-profile.jpg": sanitize_profile,
    }
    sanitized = image.copy().convert("RGB")
    sanitizers[source_name](sanitized)
    return sanitized


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
    destination = OUTPUT / "lugta-google-play-ar-sanitized-1080x1920.zip"
    with ZipFile(destination, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in paths:
            archive.write(path, arcname=path.name)
    return destination


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    SANITIZED_SOURCE.mkdir(parents=True, exist_ok=True)
    results: list[Path] = []
    for source_name, output_name, title, subtitle, kind in SCREENS:
        original = Image.open(SOURCE / source_name).convert("RGB")
        sanitized = sanitize_screenshot(source_name, original)
        sanitized_path = SANITIZED_SOURCE / Path(source_name).with_suffix(".png").name
        sanitized.save(sanitized_path, format="PNG", optimize=True)

        canvas = build_background(kind)
        accent = YELLOW if kind == "purple" else PURPLE
        add_header(canvas, title=title, subtitle=subtitle, accent=accent)
        add_phone(canvas, sanitized_path, accent=accent)
        destination = OUTPUT / output_name
        canvas.convert("RGB").save(destination, format="PNG", optimize=True)
        results.append(destination)

    preview = make_contact_sheet(results)
    bundle = make_zip(results)
    for path in [*results, preview, bundle]:
        print(path)


if __name__ == "__main__":
    main()
