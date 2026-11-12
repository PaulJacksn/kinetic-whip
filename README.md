# Kinetic Whip 2D

A fast-paced top-down action game. Defend a central neural core from
incoming waves of neon robots using physics-driven centrifugal momentum.

Drag in circles around the core to spin your weapon. The Chained Blade is
a multi-link verlet chain that extends outward as you swirl it. The
Chakra is a spinning disc that stores RPM while you keep swiping. Blue
shielded robots deflect ordinary contact: only impacts above 65% spin
speed shatter their shields. Hits dismantle robots part by part; the
parts scatter in the hit direction, then turn into collectible orbs you
spend on upgrades between waves. A boss arrives after every 3 waves.

- Engine: Godot 4.7.2, GDScript, GL Compatibility renderer
- Free with in-app purchases (revives, weapon skins) — store plumbing
  is not in v1; v1 is gameplay only
- Portrait, bird's-eye, endless waves, 60fps target
- All art and audio is procedural (vector-style drawing, synthesized
  cinematic loop + SFX). Real Sonniss GDC SFX can replace the
  procedural SFX later.

## Play

Web build: https://pauljacksn.github.io/kinetic-whip/

## Develop

1. Open the project with Godot 4.7.2.
2. Run the headless verification: `godot --headless --path . test.tscn`
3. Export Web (single-threaded) from the editor or via CLI.

## v1 scope

- Chained Blade (verlet chain) + Chakra (unlock with 150 orbs)
- Standard, shielded, ranged robots + boss every 3 waves
- Orbs, upgrades (longer chain, faster spin, more damage, core repair)
- Arena palette/layout shifts per wave
- Procedural cinematic music + SFX

## Not in v1

- In-app purchase plumbing (Google Play Billing)
- Android APK export
- Real SFX library (Sonniss GDC)
