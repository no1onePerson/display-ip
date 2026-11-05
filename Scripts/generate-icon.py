#!/usr/bin/env python3
"""Generate the macOS icon set from the supplied IpBan icon artwork."""
from PIL import Image
from pathlib import Path
import json
root = Path(__file__).resolve().parents[1] / 'macOS/Resources'
assets = root / 'Assets.xcassets'
icons = assets / 'AppIcon.appiconset'
icons.mkdir(parents=True, exist_ok=True)
image = Image.open(root / 'IpBan-icon.png').convert('RGBA')
entries = []
for points in [16, 32, 128, 256, 512]:
    for scale in [1, 2]:
        name = f'icon_{points}x{points}@{scale}x.png'
        image.resize((points * scale, points * scale), Image.Resampling.LANCZOS).save(icons / name)
        entries.append({'idiom': 'mac', 'size': f'{points}x{points}', 'scale': f'{scale}x', 'filename': name})
(icons / 'Contents.json').write_text(json.dumps({'images': entries, 'info': {'author': 'IpBan', 'version': 1}}, indent=2))
(assets / 'Contents.json').write_text(json.dumps({'info': {'author': 'IpBan', 'version': 1}}))
