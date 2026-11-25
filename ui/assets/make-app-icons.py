#!/usr/bin/env python3
"""The Asima OS apps' icons: one white symbol per app on the Asima Blue tile of the Asima OS mark
(make-mark.py), so the apps look like one family and are still told apart at a glance.
Usage: python3 make-app-icons.py OUTPUT_DIR  (writes updater.svg, maintenance.svg, appcenter.svg, …)"""
import os
import sys

TILE = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <!-- {title}: {meaning} on the Asima Blue tile -->
  <defs>
    <linearGradient id="sky" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="64" y2="64">
      <stop offset="0" stop-color="#38BDF8"/>
      <stop offset="0.55" stop-color="#2F80ED"/>
      <stop offset="1" stop-color="#1E3FAE"/>
    </linearGradient>
  </defs>
  <rect width="64" height="64" rx="16" fill="url(#sky)"/>
{glyph}
</svg>
'''

STROKE = 'fill="none" stroke="#FFFFFF" stroke-linecap="round" stroke-linejoin="round"'

ICONS = {
    "updater": ("Asima Updater", "an update arriving", f'''  <g {STROKE} stroke-width="5">
    <path d="M32 14 V36"/>
    <path d="M22 27 L32 37 L42 27"/>
    <path d="M16 39 V47 H48 V39"/>
  </g>'''),
    # A wrench: an open ring (the jaw faces up and right) and its handle.
    "maintenance": ("Asima Maintenance", "a wrench", f'''  <g {STROKE} stroke-width="5.5">
    <path d="M47.88 22.61 A8 8 0 1 1 41.39 16.12"/>
    <path d="M34.3 29.7 L18 46"/>
  </g>'''),
    # Three sliders: settings.
    "manager": ("Asima Manager", "settings sliders", f'''  <g {STROKE} stroke-width="4">
    <path d="M16 20 H48 M16 32 H48 M16 44 H48"/>
  </g>
  <g fill="#FFFFFF" stroke="url(#sky)" stroke-width="2.5">
    <circle cx="25" cy="20" r="6"/>
    <circle cx="40" cy="32" r="6"/>
    <circle cx="30" cy="44" r="6"/>
  </g>'''),
    # A game controller with its direction pad and two buttons cut out of it.
    "gaming": ("Asima Gaming", "a game controller", '''  <rect x="10" y="21" width="44" height="24" rx="12" fill="#FFFFFF"/>
  <path d="M22 28 V38 M17 33 H27" fill="none" stroke="url(#sky)" stroke-width="3.5" stroke-linecap="round"/>
  <circle cx="41" cy="30" r="2.6" fill="url(#sky)"/>
  <circle cx="46" cy="36" r="2.6" fill="url(#sky)"/>'''),
    # A hub: three spokes from a centre, for the online app that brings everything together.
    "hub": ("Asima Hub", "a hub with three spokes", f'''  <g {STROKE} stroke-width="4">
    <path d="M32 32 V17 M32 32 L18.6 39.7 M32 32 L45.4 39.7"/>
  </g>
  <g fill="#FFFFFF">
    <circle cx="32" cy="32" r="7"/>
    <circle cx="32" cy="15" r="5"/>
    <circle cx="17.3" cy="40.5" r="5"/>
    <circle cx="46.7" cy="40.5" r="5"/>
  </g>'''),
    # Four app tiles, one of them a plus: every kind of app, and getting more.
    "appcenter": ("Asima App Center", "four app tiles", f'''  <g fill="#FFFFFF">
    <rect x="13" y="13" width="16" height="16" rx="4.5"/>
    <rect x="35" y="13" width="16" height="16" rx="4.5"/>
    <rect x="13" y="35" width="16" height="16" rx="4.5"/>
  </g>
  <g {STROKE} stroke-width="4.5">
    <path d="M43 35 V51 M35 43 H51"/>
  </g>'''),
    "dev": ("Asima Dev", "code brackets", f'''  <g {STROKE} stroke-width="5">
    <path d="M24 20 L12 32 L24 44"/>
    <path d="M40 20 L52 32 L40 44"/>
    <path d="M35.5 16 L28.5 48"/>
  </g>'''),
}

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
for name, (title, meaning, glyph) in ICONS.items():
    with open(os.path.join(out, f"{name}.svg"), "w") as f:
        f.write(TILE.format(title=title, meaning=meaning, glyph=glyph))
    print(f"{name}.svg")
