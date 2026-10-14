"""Subset the Noto CJK fonts down to the characters the game actually uses.

Usage: python3 tools/subset_fonts.py <dir with NotoSerifSC[wght].ttf and NotoSansSC[wght].ttf>

Download the full fonts from https://github.com/google/fonts (ofl/notoserifsc, ofl/notosanssc).
Run this again whenever new text is added to the scripts.
"""
import pathlib, sys
from fontTools import subset
from fontTools.ttLib import TTFont

root = pathlib.Path(__file__).resolve().parent.parent
src = pathlib.Path(sys.argv[1])
chars = set(chr(c) for c in range(0x20, 0x7f))
chars |= set("，。？！：；、（）《》“”‘’…—–·～×−▼←→♪♫％")
for f in (root / "scripts").rglob("*.gd"):
    chars |= set(f.read_text(encoding="utf-8"))
chars |= set((root / "project.godot").read_text(encoding="utf-8"))
chars = {c for c in chars if c.isprintable() or c == " "}
text = "".join(sorted(chars))
for name, out in (("NotoSerifSC[wght].ttf", "serif.ttf"), ("NotoSansSC[wght].ttf", "sans.ttf")):
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.notdef_outline = True
    font = TTFont(src / name)
    sub = subset.Subsetter(opts)
    sub.populate(text=text)
    sub.subset(font)
    font.save(root / "fonts" / out)
    cmap = font.getBestCmap()
    missing = [c for c in text if ord(c) not in cmap and not c.isspace()]
    print(out, (root / "fonts" / out).stat().st_size // 1024, "KB; missing:", "".join(missing))
