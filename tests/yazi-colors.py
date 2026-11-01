"""Check Yazi's native selection slots against independently loaded Flume palettes."""

import json
import re
import sys
import tomllib
from pathlib import Path


def contrast(first: str, second: str) -> float:
    def luminance(color: str) -> float:
        channels = [int(color[index : index + 2], 16) / 255 for index in (1, 3, 5)]
        linear = [
            value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
            for value in channels
        ]
        return sum(
            value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722), strict=True)
        )

    low, high = sorted((luminance(first), luminance(second)))
    return (high + 0.05) / (low + 0.05)


def check_native_selection(capture: str, filename: str) -> None:
    foreground, background, reverse = "default", "default", False
    position = 0
    for match in re.finditer(r"\x1b\[([0-9;]*)m", capture):
        fragment = capture[position : match.start()]
        if filename in fragment and (foreground, background, reverse) == (
            "ansi:5",
            "default",
            True,
        ):
            return
        position = match.end()
        codes = [int(code or "0") for code in match[1].split(";")]
        index = 0
        while index < len(codes):
            code = codes[index]
            index += 1
            if code == 0:
                foreground, background, reverse = "default", "default", False
            elif code in (7, 27):
                reverse = code == 7
            elif code in (39, 49):
                if code == 39:
                    foreground = "default"
                else:
                    background = "default"
            elif code in (38, 48):
                if codes[index] == 5:
                    color = f"ansi:{codes[index + 1]}"
                    index += 2
                elif codes[index] == 2:
                    color = "rgb:" + ",".join(map(str, codes[index + 1 : index + 4]))
                    index += 4
                else:
                    raise ValueError("unsupported native SGR color")
                if code == 38:
                    foreground = color
                else:
                    background = color
            elif 30 <= code <= 37 or 90 <= code <= 97:
                foreground = f"ansi:{code - (30 if code < 90 else 82)}"
            elif 40 <= code <= 47 or 100 <= code <= 107:
                background = f"ansi:{code - (40 if code < 100 else 92)}"
    raise ValueError("selected filename did not render as reversed terminal magenta on the canvas")


def main() -> None:
    root, flume, capture = map(Path, sys.argv[1:4])
    check_native_selection(capture.read_text(), sys.argv[4])
    theme = tomllib.loads((root / "yazi/.config/yazi/theme.toml").read_text())
    for section, item in (
        ("tabs", "active"),
        ("indicator", "current"),
        ("cmp", "active"),
        ("help", "hovered"),
    ):
        style = theme[section][item]
        if (style["fg"], style["bg"], style["reversed"]) != ("magenta", "reset", True):
            raise ValueError(f"{section}.{item} does not use the readable terminal selection pair")
    for schema in ("dusk", "opal", "mira", "mesa"):
        colors = json.loads((flume / f"extras/palette/flume-{schema}.json").read_text())["colors"]
        # Reversal makes the terminal canvas the text and ANSI magenta the fill.
        ratio = contrast(colors["bg"], colors["magenta"])
        if ratio < 4.5:
            raise ValueError(f"{schema}: native selection contrast {ratio:.2f}:1 is below 4.5:1")
        print(f"PASS: Yazi {schema} native selection pair {ratio:.2f}:1")


if __name__ == "__main__":
    main()
