#!/usr/bin/env python3
# palette_no_numpy.py
import colorsys
import math
import os
import random
from pathlib import Path

from PIL import Image


def hex_color(c: tuple[float, float, float]) -> str:
    r = int(round(c[0]))
    g = int(round(c[1]))
    b = int(round(c[2]))
    r = max(0, min(255, r))
    g = max(0, min(255, g))
    b = max(0, min(255, b))
    return f"#{r:02x}{g:02x}{b:02x}"

def clip_color(c: tuple[float, float, float]) -> tuple[float, float, float]:
    return (max(0.0, min(255.0, c[0])),
            max(0.0, min(255.0, c[1])),
            max(0.0, min(255.0, c[2])))

def lighten(c: tuple[float, float, float], f: float) -> tuple[float, float, float]:
    return clip_color((
        c[0] + (255.0 - c[0]) * f,
        c[1] + (255.0 - c[1]) * f,
        c[2] + (255.0 - c[2]) * f,
    ))

def darken(c: tuple[float, float, float], f: float) -> tuple[float, float, float]:
    return clip_color((
        c[0] * (1.0 - f),
        c[1] * (1.0 - f),
        c[2] * (1.0 - f),
    ))

def bright(c: tuple[float, float, float]) -> tuple[float, float, float]:
    return lighten(c, 0.4)

def get_redness(c: tuple[float, float, float]) -> float:
    r, g, b = c
    return r - (g + b) / 2.0

def rgb_to_hsl(r: float, g: float, b: float) -> tuple[float, float, float]:
    # colorsys uses 0..1
    h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
    # return H, S, L scaled to 0..255-ish for compatibility with original scoring
    return (h * 360.0, s * 255.0, l * 255.0)

def euclidean(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    return math.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2 + (a[2]-b[2])**2)

def kmeans_plain(data: list[tuple[float, float, float]], k: int, iterations: int = 20) -> tuple[list[tuple[float, float, float]], list[int]]:
    if not data:
        return ([(0.0, 0.0, 0.0)] * k, [0]*len(data))
    centroids = [tuple(p) for p in random.sample(data, min(k, len(data)))]
    while len(centroids) < k:
        centroids.append(tuple(random.choice(data)))
    for _ in range(iterations):
        clusters = [[] for _ in range(k)]
        for p in data:
            # find nearest centroid
            best = 0
            best_d = euclidean(p, centroids[0])
            for i in range(1, k):
                d = euclidean(p, centroids[i])
                if d < best_d:
                    best_d = d
                    best = i
            clusters[best].append(p)
        moved = False
        for i in range(k):
            if clusters[i]:
                # compute mean
                sx = sy = sz = 0.0
                for px, py, pz in clusters[i]:
                    sx += px; sy += py; sz += pz
                n = len(clusters[i])
                newc = (sx / n, sy / n, sz / n)
                if euclidean(newc, centroids[i]) > 1e-6:
                    centroids[i] = newc
                    moved = True
            else:
                # reinitialize empty centroid
                centroids[i] = tuple(random.choice(data))
                moved = True
        if not moved:
            break
    # optional: return cluster indices for each point
    indices = []
    for p in data:
        best = 0
        best_d = euclidean(p, centroids[0])
        for i in range(1, k):
            d = euclidean(p, centroids[i])
            if d < best_d:
                best_d = d
                best = i
        indices.append(best)
    return centroids, indices

def get_image_palette(image_path: str) -> dict[str, str]:
    # open image, convert to RGB and resize for speed
    img = Image.open(image_path).convert("RGB")
    img = img.resize((150, 150))
    pixels = list(img.getdata())
    # convert to floats
    data = [(float(r), float(g), float(b)) for (r, g, b) in pixels]

    def score(c: tuple[float, float, float]) -> float:
        # use HSV-like scoring: prefer high saturation and mid-high lightness
        h, s, l = rgb_to_hsl(c[0], c[1], c[2])
        # negative because we want sort ascending -> brightest/saturated first
        return -s * 1000.0 - l

    # run kmeans plain for 6 centroids
    centroids, _ = kmeans_plain(data, 6, iterations=30)

    # clip centroids
    centroids = [clip_color(c) for c in centroids]

    # sort by score
    centroids = sorted(centroids, key=score)

    # ensure we have at least 6 entries
    while len(centroids) < 6:
        centroids.append((128.0, 128.0, 128.0))

    p, s, t, n, nv, err = centroids[:6]

    term_black   = darken(n, 0.3)
    term_red = p if get_redness(p) > get_redness(s) else s
    term_green   = t
    term_yellow  = lighten(p, 0.4)
    term_blue    = s
    term_magenta = t
    term_cyan    = nv
    term_white   = lighten(n, 0.8)

    palette: dict[str, str] = {
        "primary_paletteKeyColor": hex_color(p),
        "secondary_paletteKeyColor": hex_color(s),
        "tertiary_paletteKeyColor": hex_color(t),
        "neutral_paletteKeyColor": hex_color(n),
        "neutral_variant_paletteKeyColor": hex_color(nv),

        "background": hex_color(darken(n, 0.98)),
        "onBackground": hex_color(lighten(n, 0.9)),
        "surface": hex_color(darken(n, 0.93)),
        "surfaceDim": hex_color(darken(n, 0.99)),
        "surfaceBright": hex_color(lighten(n, 0.2)),
        "surfaceContainerLowest": hex_color(darken(n, 0.99)),
        "surfaceContainerLow": hex_color(darken(n, 0.96)),
        "surfaceContainer": hex_color(darken(n, 0.92)),
        "surfaceContainerHigh": hex_color(darken(n, 0.85)),
        "surfaceContainerHighest": hex_color(darken(n, 0.75)),
        "onSurface": hex_color(lighten(n, 0.95)),
        "surfaceVariant": hex_color(nv),
        "onSurfaceVariant": hex_color(darken(nv, 0.3)),
        "outline": hex_color(darken(n, 0.5)),
        "outlineVariant": hex_color(darken(n, 0.8)),
        "shadow": "#000000",
        "scrim": "#000000",
        "surfaceTint": hex_color(p),

        "primary": hex_color(p),
        "onPrimary": "#ffffff" if sum(p) < 420 else "#000000",
        "primaryContainer": hex_color(darken(p, 0.75)),
        "onPrimaryContainer": "#ffffff" if sum(darken(p,0.75)) < 420 else "#000000",
        "inversePrimary": hex_color(lighten(p, 0.7)),

        "secondary": hex_color(s),
        "onSecondary": "#ffffff" if sum(s) < 420 else "#000000",
        "secondaryContainer": hex_color(darken(s, 0.75)),
        "onSecondaryContainer": "#ffffff" if sum(darken(s,0.75)) < 420 else "#000000",

        "tertiary": hex_color(t),
        "onTertiary": "#ffffff" if sum(t) < 420 else "#000000",
        "tertiaryContainer": hex_color(darken(t, 0.75)),
        "onTertiaryContainer": "#ffffff" if sum(darken(t,0.75)) < 420 else "#000000",

        "error": "#f28b82",
        "onError": "#000000",
        "errorContainer": "#f28b82",
        "onErrorContainer": "#000000",

        "term0":  hex_color(term_black),    "term8":  hex_color(bright(term_black)),
        "term1":  hex_color(term_red),      "term9":  hex_color(bright(term_red)),
        "term2":  hex_color(term_green),    "term10": hex_color(bright(term_green)),
        "term3":  hex_color(term_yellow),   "term11": hex_color(bright(term_yellow)),
        "term4":  hex_color(term_blue),     "term12": hex_color(bright(term_blue)),
        "term5":  hex_color(term_magenta),  "term13": hex_color(bright(term_magenta)),
        "term6":  hex_color(term_cyan),     "term14": hex_color(bright(term_cyan)),
        "term7":  hex_color(term_white),    "term15": hex_color(lighten(term_white, 0.2)),

        "rosewater": hex_color(lighten(p, 0.7)),
        "flamingo":  hex_color(lighten(term_red, 0.4)),
        "pink":      hex_color(lighten(term_magenta, 0.5)),
        "mauve":     hex_color(t),
        "red":       hex_color(term_red),
        "maroon":    hex_color(darken(term_red, 0.4)),
        "peach":     hex_color(lighten(term_yellow, 0.3)),
        "yellow":    hex_color(term_yellow),
        "green":     hex_color(term_green),
        "teal":      hex_color(term_cyan),
        "sky":       hex_color(lighten(term_cyan, 0.4)),
        "sapphire":  hex_color(term_blue),
        "blue":      hex_color(term_blue),
        "lavender":  hex_color(lighten(n, 0.8)),

        "text":      hex_color(lighten(n, 0.95)),
        "subtext1":  hex_color(lighten(n, 0.85)),
        "subtext0":  hex_color(lighten(n, 0.75)),
        "overlay2":  hex_color(lighten(n, 0.65)),
        "overlay1":  hex_color(lighten(n, 0.55)),
        "overlay0":  hex_color(lighten(n, 0.45)),
        "surface2":  hex_color(lighten(n, 0.25)),
        "surface1":  hex_color(lighten(n, 0.15)),
        "surface0":  hex_color(lighten(n, 0.05)),
        "base":      hex_color(darken(n, 0.98)),
        "mantle":    hex_color(darken(n, 0.95)),
        "crust":     hex_color(darken(n, 0.90)),

        "success": hex_color(term_green),
        "onSuccess": "#000000",
        "successContainer": hex_color(darken(term_green, 0.7)),
        "onSuccessContainer": "#ffffff",

        "klink": hex_color(p),
        "kvisited": hex_color(s),
        "knegative": hex_color(term_red),
        "kpositive": hex_color(term_green),
        "kneutral": hex_color(nv),
        "klinkSelection": hex_color(darken(p, 0.4)),
        "kvisitedSelection": hex_color(darken(s, 0.4)),
        "knegativeSelection": hex_color(darken(term_red, 0.6)),
        "kpositiveSelection": hex_color(darken(term_green, 0.6)),
        "kneutralSelection": hex_color(darken(nv, 0.5)),
    }

    for base, color in [("secondary", s), ("tertiary", t)]:
        palette[f"{base}Fixed"] = hex_color(darken(color, 0.7))
        palette[f"{base}FixedDim"] = hex_color(darken(color, 0.85))
        palette[f"on{base.capitalize()}Fixed"] = "#ffffff" if sum(darken(color,0.7)) < 380 else "#000000"
        palette[f"on{base.capitalize()}FixedVariant"] = "#ffffff" if sum(color) < 380 else "#000000"

    return palette

def get_caelestia_palette() -> dict[str, str]:
    path = Path(os.path.expandvars("$HOME/.config/hypr/scheme/current.conf"))
    if not path.exists():
        return {}
    palette: dict[str, str] = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key_part, value = line.split("=", 1)
                key = key_part.strip().lstrip("$").strip()
                color = value.strip().lstrip("#").strip()
                if not color.startswith("#"):
                    color = "#" + color
                palette[key] = color.lower()
    return palette

# Example usage:
# p = get_image_palette("/path/to/image.png")
# c = get_caelestia_palette()
