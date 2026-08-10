from __future__ import annotations

from pathlib import Path

import arabic_reshaper
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from bidi.algorithm import get_display


ROOT = Path(__file__).resolve().parents[1]
GOLDENS = ROOT / "test" / "goldens" / "lugta"
STORE = ROOT / "store_assets"
BRAND = ROOT / "assets" / "branding"
FONT_ZAIN = ROOT / "assets" / "fonts" / "Zain-Bold.ttf"
FONT_ARABIC = ROOT / "assets" / "fonts" / "IBMPlexSansArabic-Bold.ttf"

PURPLE = (55, 55, 155, 255)
PURPLE_DARK = (28, 27, 81, 255)
PURPLE_SOFT = (241, 240, 250, 255)
YELLOW = (252, 200, 3, 255)
YELLOW_SOFT = (255, 240, 177, 255)
INK = (32, 32, 53, 255)
WHITE = (255, 255, 255, 255)

JOURNEYS = (
    "product",
    "home",
    "checkout",
    "finance",
    "engagement",
    "account",
)

CAPTIONS = {
    "ar": {
        "product": "منتجات تستحق البيع",
        "home": "كل السوق بمكان واحد",
        "checkout": "اطلب بخطوات واضحة",
        "finance": "أرباحك أمامك دائماً",
        "engagement": "مكافآت تدفعك للأمام",
        "account": "كل أعمالك في حساب واحد",
    },
    "ckb": {
        "product": "بەرهەمێک کە شایەنی فرۆشتنە",
        "home": "هەموو بازاڕ لە یەک شوێن",
        "checkout": "داواکاری بە هەنگاوی ڕوون",
        "finance": "قازانجەکانت هەمیشە لەبەردەستن",
        "engagement": "خەڵات بۆ هەنگاوی داهاتوو",
        "account": "هەموو کارەکانت لە یەک هەژمار",
    },
    "en": {
        "product": "Products worth selling",
        "home": "The whole market in one place",
        "checkout": "Order in clear steps",
        "finance": "Your earnings, always visible",
        "engagement": "Rewards that move you forward",
        "account": "Your business in one account",
    },
}


def shaped(text: str, locale: str) -> str:
    if locale == "en":
        return text
    return get_display(arabic_reshaper.reshape(text))


def text_font(locale: str, size: int) -> ImageFont.FreeTypeFont:
    path = FONT_ZAIN if locale == "en" else FONT_ARABIC
    return ImageFont.truetype(str(path), size=size)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *size), radius=radius, fill=255)
    return mask


def paste_phone(
    canvas: Image.Image,
    screenshot: Image.Image,
    box: tuple[int, int, int, int],
    *,
    radius: int,
) -> None:
    x, y, width, height = box
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (x - 14, y - 10, x + width + 14, y + height + 24),
        radius=radius + 18,
        fill=(24, 21, 74, 74),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(24)))

    frame = Image.new("RGBA", (width + 24, height + 24), WHITE)
    frame_mask = rounded_mask(frame.size, radius + 12)
    canvas.paste(frame, (x - 12, y - 12), frame_mask)

    source_ratio = screenshot.width / screenshot.height
    target_ratio = width / height
    if source_ratio > target_ratio:
        render_height = height
        render_width = round(height * source_ratio)
    else:
        render_width = width
        render_height = round(width / source_ratio)
    rendered = screenshot.resize((render_width, render_height), Image.Resampling.LANCZOS)
    left = max(0, (render_width - width) // 2)
    top = max(0, (render_height - height) // 2)
    rendered = rendered.crop((left, top, left + width, top + height))
    canvas.paste(rendered, (x, y), rounded_mask((width, height), radius))


def decorative_background(
    size: tuple[int, int],
    *,
    index: int,
) -> Image.Image:
    width, height = size
    light = index % 2 == 0
    canvas = Image.new("RGBA", size, PURPLE_SOFT if light else PURPLE_DARK)
    draw = ImageDraw.Draw(canvas)
    if light:
        draw.ellipse(
            (width * 0.69, -height * 0.07, width * 1.13, height * 0.16),
            fill=YELLOW,
        )
        draw.ellipse(
            (-width * 0.16, height * 0.78, width * 0.30, height * 1.04),
            fill=(211, 207, 240, 255),
        )
    else:
        draw.ellipse(
            (-width * 0.18, -height * 0.04, width * 0.32, height * 0.21),
            fill=PURPLE,
        )
        draw.ellipse(
            (width * 0.72, height * 0.78, width * 1.15, height * 1.03),
            fill=YELLOW,
        )
    return canvas


def add_header(
    canvas: Image.Image,
    *,
    locale: str,
    caption: str,
    index: int,
    top: int,
    width: int,
) -> None:
    draw = ImageDraw.Draw(canvas)
    light = index % 2 == 0
    color = INK if light else WHITE
    accent = PURPLE if light else YELLOW
    label = "لكطة — Lugta" if locale != "en" else "Lugta"
    label_font = text_font(locale, max(30, round(width * 0.032)))
    title_font = text_font(locale, max(52, round(width * 0.061)))
    draw.text(
        (width // 2, top),
        shaped(label, locale),
        font=label_font,
        fill=accent,
        anchor="mm",
    )
    draw.text(
        (width // 2, top + round(width * 0.075)),
        shaped(caption, locale),
        font=title_font,
        fill=color,
        anchor="mm",
        stroke_width=0,
    )
    line_width = round(width * 0.11)
    line_y = top + round(width * 0.13)
    draw.rounded_rectangle(
        (
            width // 2 - line_width // 2,
            line_y,
            width // 2 + line_width // 2,
            line_y + max(8, width // 120),
        ),
        radius=99,
        fill=accent,
    )


def generate_store_screenshots() -> None:
    for locale in ("ar", "ckb", "en"):
        scenario = f"{locale}-light"
        for index, journey in enumerate(JOURNEYS, start=1):
            source = GOLDENS / f"{journey}-{scenario}.png"
            if not source.exists():
                raise FileNotFoundError(f"Missing golden screenshot: {source}")
            screenshot = Image.open(source).convert("RGBA")

            google = decorative_background((1080, 1920), index=index)
            add_header(
                google,
                locale=locale,
                caption=CAPTIONS[locale][journey],
                index=index,
                top=86,
                width=1080,
            )
            paste_phone(google, screenshot, (175, 310, 730, 1579), radius=54)
            google_path = STORE / "google_play" / locale / f"{index:02d}-{journey}.png"
            google_path.parent.mkdir(parents=True, exist_ok=True)
            google.convert("RGB").save(google_path, optimize=True)

            ios = decorative_background((1290, 2796), index=index)
            add_header(
                ios,
                locale=locale,
                caption=CAPTIONS[locale][journey],
                index=index,
                top=150,
                width=1290,
            )
            paste_phone(ios, screenshot, (175, 485, 940, 2034), radius=68)
            ios_path = STORE / "app_store" / locale / f"{index:02d}-{journey}.png"
            ios_path.parent.mkdir(parents=True, exist_ok=True)
            ios.convert("RGB").save(ios_path, optimize=True)


def generate_feature_graphic() -> None:
    canvas = Image.new("RGBA", (1024, 500), PURPLE)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((720, -175, 1140, 245), fill=YELLOW)
    draw.ellipse((790, 270, 1080, 560), outline=(255, 227, 105, 255), width=18)
    draw.rounded_rectangle((62, 66, 520, 202), radius=30, fill=(44, 43, 125, 255))
    draw.ellipse((704, 82, 986, 364), fill=WHITE)

    wordmark = Image.open(BRAND / "lugta_wordmark_white.png").convert("RGBA")
    wordmark.thumbnail((430, 142), Image.Resampling.LANCZOS)
    canvas.alpha_composite(wordmark, (76, 64))

    mark = Image.open(BRAND / "lugta_icon_mark.png").convert("RGBA")
    mark.thumbnail((270, 270), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, (710, 88))

    ar_font = ImageFont.truetype(str(FONT_ARABIC), 43)
    en_font = ImageFont.truetype(str(FONT_ZAIN), 23)
    draw.text(
        (70, 309),
        shaped("كل يوم لكطة جديدة", "ar"),
        font=ar_font,
        fill=WHITE,
        anchor="lm",
    )
    draw.text(
        (72, 369),
        "Sell smarter. Grow with every order.",
        font=en_font,
        fill=(219, 217, 247, 255),
        anchor="lm",
    )
    draw.rounded_rectangle((72, 423, 210, 434), radius=99, fill=YELLOW)
    target = STORE / "brand" / "google-play-feature-1024x500.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(target, optimize=True)


def generate_social_square() -> None:
    canvas = Image.new("RGBA", (1200, 1200), PURPLE_SOFT)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((90, 90, 1110, 1110), radius=96, fill=PURPLE)
    draw.ellipse((730, -130, 1280, 420), fill=YELLOW)
    draw.ellipse((-180, 820, 330, 1330), fill=(83, 79, 180, 255))
    draw.ellipse((390, 155, 810, 575), fill=WHITE)

    mark = Image.open(BRAND / "lugta_icon_mark.png").convert("RGBA")
    mark.thumbnail((360, 360), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, (420, 185))
    wordmark = Image.open(BRAND / "lugta_wordmark_white.png").convert("RGBA")
    wordmark.thumbnail((650, 214), Image.Resampling.LANCZOS)
    canvas.alpha_composite(wordmark, (275, 650))

    ar_font = ImageFont.truetype(str(FONT_ARABIC), 45)
    draw.text(
        (600, 970),
        shaped("كل يوم لكطة جديدة", "ar"),
        font=ar_font,
        fill=WHITE,
        anchor="mm",
    )
    draw.rounded_rectangle((510, 1040, 690, 1054), radius=99, fill=YELLOW)
    target = STORE / "brand" / "store-social-square-1200.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(target, optimize=True)


def main() -> None:
    generate_store_screenshots()
    generate_feature_graphic()
    generate_social_square()


if __name__ == "__main__":
    main()
