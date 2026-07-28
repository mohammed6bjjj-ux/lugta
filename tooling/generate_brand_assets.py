from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FONT_PATH = ROOT / "assets" / "fonts" / "SpaceGrotesk-Variable.ttf"
BRAND_DIR = ROOT / "assets" / "branding"

INK = (25, 23, 19, 255)
GREEN = (27, 158, 106, 255)
CREAM = (250, 246, 237, 255)
WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def space_grotesk(size: int, weight: int = 700) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT_PATH), size=size)
    font.set_variation_by_axes([weight])
    return font


def rotated_bar(width: int, height: int, radius: int) -> Image.Image:
    padding = max(width, height)
    bar = Image.new("RGBA", (width + padding * 2, height + padding * 2), TRANSPARENT)
    draw = ImageDraw.Draw(bar)
    draw.rounded_rectangle(
        (padding, padding, padding + width, padding + height),
        radius=radius,
        fill=GREEN,
    )
    return bar.rotate(16, resample=Image.Resampling.BICUBIC, expand=True)


def draw_centered_g(
    image: Image.Image,
    *,
    color: tuple[int, int, int, int],
    font_size: int,
    center: tuple[float, float],
    bar_scale: float = 1.0,
    with_bar: bool = True,
) -> None:
    draw = ImageDraw.Draw(image)
    font = space_grotesk(font_size)
    bbox = draw.textbbox((0, 0), "g", font=font)
    glyph_width = bbox[2] - bbox[0]
    glyph_height = bbox[3] - bbox[1]
    x = center[0] - glyph_width / 2 - bbox[0]
    y = center[1] - glyph_height / 2 - bbox[1] + font_size * 0.035
    draw.text((x, y), "g", font=font, fill=color)

    if not with_bar:
        return

    bar_width = max(3, round(font_size * 18 / 54 * bar_scale))
    bar_height = max(2, round(font_size * 6 / 54 * bar_scale))
    bar = rotated_bar(bar_width, bar_height, max(1, bar_height // 2))
    bar_x = round(center[0] - bar.width / 2)
    bar_y = round(center[1] - glyph_height / 2 - font_size * 0.095 - bar.height / 2)
    image.alpha_composite(bar, (bar_x, bar_y))


def icon_mark(size: int, *, full_bleed: bool, adaptive_foreground: bool = False) -> Image.Image:
    image = Image.new("RGBA", (size, size), INK if full_bleed else TRANSPARENT)
    if not full_bleed and not adaptive_foreground:
        margin = round(size * 0.055)
        radius = round((size - margin * 2) * 28 / 96)
        ImageDraw.Draw(image).rounded_rectangle(
            (margin, margin, size - margin, size - margin),
            radius=radius,
            fill=INK,
        )

    if adaptive_foreground:
        font_size = round(size * 0.40)
        bar_scale = 0.92
    else:
        font_size = round(size * 0.56)
        bar_scale = 1.0
    draw_centered_g(
        image,
        color=WHITE,
        font_size=font_size,
        center=(size / 2, size / 2),
        bar_scale=bar_scale,
        with_bar=size >= 32,
    )
    return image


def wordmark(
    *,
    color: tuple[int, int, int, int],
    font_size: int = 320,
    padding: int = 80,
) -> Image.Image:
    font = space_grotesk(font_size)
    probe = Image.new("RGBA", (16, 16), TRANSPARENT)
    draw = ImageDraw.Draw(probe)
    bbox = draw.textbbox((0, 0), "Lugta", font=font)
    width = math.ceil(bbox[2] - bbox[0] + padding * 2)
    height = math.ceil((bbox[3] - bbox[1]) + padding * 2 + font_size * 0.12)
    image = Image.new("RGBA", (width, height), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    origin_x = padding - bbox[0]
    origin_y = padding - bbox[1] + font_size * 0.08
    draw.text((origin_x, origin_y), "Lugta", font=font, fill=color)

    lu_width = draw.textlength("Lu", font=font)
    g_width = draw.textlength("g", font=font)
    bar_width = round(font_size * 13 / 44)
    bar_height = round(font_size * 4 / 44)
    bar = rotated_bar(bar_width, bar_height, max(1, bar_height // 2))
    center_x = origin_x + lu_width + g_width / 2
    bar_x = round(center_x - bar.width / 2)
    bar_y = round(padding - font_size * 0.045)
    image.alpha_composite(bar, (bar_x, bar_y))

    content_bbox = image.getbbox()
    assert content_bbox is not None
    cropped = image.crop(content_bbox)
    framed = Image.new(
        "RGBA",
        (cropped.width + padding, cropped.height + padding),
        TRANSPARENT,
    )
    framed.alpha_composite(cropped, (padding // 2, padding // 2))
    return framed


def fit_inside(image: Image.Image, size: tuple[int, int], fraction: float) -> Image.Image:
    canvas = Image.new("RGBA", size, TRANSPARENT)
    max_width = round(size[0] * fraction)
    max_height = round(size[1] * fraction)
    scale = min(max_width / image.width, max_height / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas.alpha_composite(
        resized,
        ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2),
    )
    return canvas


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def generate_flutter_assets() -> None:
    save_png(icon_mark(1024, full_bleed=False), BRAND_DIR / "lugta_icon_mark.png")
    save_png(icon_mark(1024, full_bleed=True), BRAND_DIR / "lugta_app_icon.png")
    save_png(wordmark(color=INK), BRAND_DIR / "lugta_wordmark_ink.png")
    save_png(wordmark(color=WHITE), BRAND_DIR / "lugta_wordmark_white.png")


def generate_android_icons() -> None:
    legacy_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    adaptive_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in legacy_sizes.items():
        mark = icon_mark(size, full_bleed=False)
        save_png(mark, res / folder / "ic_launcher.png")
        save_png(mark, res / folder / "ic_launcher_round.png")
    for folder, size in adaptive_sizes.items():
        save_png(
            icon_mark(size, full_bleed=False, adaptive_foreground=True),
            res / folder / "ic_launcher_foreground.png",
        )


def generate_ios_icons() -> None:
    app_icon_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    manifest = json.loads((app_icon_dir / "Contents.json").read_text(encoding="utf-8"))
    master = icon_mark(1024, full_bleed=True).convert("RGB")
    for entry in manifest["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].removesuffix("x"))
        pixels = round(points * scale)
        save_png(
            master.resize((pixels, pixels), Image.Resampling.LANCZOS),
            app_icon_dir / filename,
        )

    launch_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    inverse = wordmark(color=WHITE)
    for scale in (1, 2, 3):
        size = (168 * scale, 185 * scale)
        launch = fit_inside(inverse, size, 0.72)
        suffix = "" if scale == 1 else f"@{scale}x"
        save_png(launch, launch_dir / f"LaunchImage{suffix}.png")


def generate_web_icons() -> None:
    web = ROOT / "web"
    regular = icon_mark(512, full_bleed=False)
    full_bleed = icon_mark(512, full_bleed=True)
    save_png(
        regular.resize((192, 192), Image.Resampling.LANCZOS),
        web / "icons" / "Icon-192.png",
    )
    save_png(regular, web / "icons" / "Icon-512.png")
    save_png(
        full_bleed.resize((192, 192), Image.Resampling.LANCZOS),
        web / "icons" / "Icon-maskable-192.png",
    )
    save_png(full_bleed, web / "icons" / "Icon-maskable-512.png")
    save_png(
        regular.resize((64, 64), Image.Resampling.LANCZOS),
        web / "favicon.png",
    )


def main() -> None:
    if not FONT_PATH.exists():
        raise SystemExit(f"Missing logo font: {FONT_PATH}")
    BRAND_DIR.mkdir(parents=True, exist_ok=True)
    generate_flutter_assets()
    generate_android_icons()
    generate_ios_icons()
    generate_web_icons()


if __name__ == "__main__":
    main()
