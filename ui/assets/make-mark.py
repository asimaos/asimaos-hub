#!/usr/bin/env python3
"""The Asima OS mark: an infinity ribbon (lemniscate of Bernoulli, stretched upward) on the blue
tile. One strand passes over the crossing, the other stops short of it (over-under), so it reads as
one endless ribbon. Usage: python3 make-mark.py asimaos-mark.svg"""
import math
import sys

A, SY = 20.6, 1.42          # half width of the loop; vertical stretch
CX, CY = 32.0, 32.0
W, GAP = 6.6, 1.5            # ribbon width; gap at the under-crossing
N = 2400                     # samples for measuring; the path keeps every 8th


def point(t):
    s, c = math.sin(t), math.cos(t)
    d = 1 + s * s
    return CX + A * c / d, CY - SY * A * s * c / d


# From just after the under-crossing (t = -pi/2), around the right loop, over the crossing at
# t = pi/2, around the left loop, to just before the under-crossing again (t = 3pi/2).
ts = [-math.pi / 2 + 2 * math.pi * i / N for i in range(N + 1)]
pts = [point(t) for t in ts]
dist = [0.0]
for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
    dist.append(dist[-1] + math.hypot(x1 - x0, y1 - y0))
# Where the strands cross, their directions meet at this angle. The stopped strand ends square
# (it looks like it goes under): its nearer corner must clear the other strand's edge plus the gap.
dx, dy = A / 2, SY * A / 2
crossing = math.atan2(2 * dx * dy, dx * dx - dy * dy)
cut = (W / 2 + GAP + W / 2 * abs(math.cos(crossing))) / abs(math.sin(crossing))
keep = [p for p, s in zip(pts, dist) if cut <= s <= dist[-1] - cut]
keep = keep[::8] + [keep[-1]]
d = "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in keep)

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <!-- Asima OS: an endless ribbon on the Asima Blue tile -->
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#38BDF8"/>
      <stop offset="0.55" stop-color="#2F80ED"/>
      <stop offset="1" stop-color="#1E3FAE"/>
    </linearGradient>
    <linearGradient id="ribbon" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#DCEEFF"/>
    </linearGradient>
  </defs>
  <rect width="64" height="64" rx="16" fill="url(#sky)"/>
  <path d="{d}" fill="none" stroke="url(#ribbon)" stroke-width="{W}" stroke-linecap="butt" stroke-linejoin="round"/>
</svg>
'''
open(sys.argv[1], "w").write(svg)
print(f"crossing angle {math.degrees(crossing):.1f} deg, cut {cut:.2f}, {len(keep)} points, {len(svg)} bytes")
