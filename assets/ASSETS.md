# Kinetic Whip 2D — Art Assets Manifest

All art under `art/` + `fonts/` in this folder. Total: **~500 KB** (38 files).
Every file was downloaded from a real, license-checked source and verified by
viewing it. Licenses are **CC0 or CC-BY only** (commercial game). Where a file
is a recolor / crop / composition of a source, the derivation is noted so the
license chain stays clear.

**Credit lines to ship in the game** (put these in the credits screen):
- "Energy Ball" by yiannisd — CC-BY 3.0 — https://lpc.opengameart.org/content/energy-ball
- Icons by Lorc and Delapouite — CC-BY 3.0 — https://game-icons.net
- Combat drone sprites by SovDigital (credit appreciated, not required)
- Robot sprites by ArtManOil — https://art-man-oil.itch.io/ (credit appreciated, not required)
- Pixel Sci-Fi Tileset by reodesuxz (credit appreciated, not required)
- Kenney assets — CC0, no credit required

---

## 1. Arena floor

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/arena/floor.png` | 512x512 | Free Pixel Sci-Fi Tileset (16x16), https://reodesuxz.itch.io/free-pixel-sci-fi-tileset-16x16 | reodesuxz | Free for personal + commercial, no attribution required, do not resell/redistribute the files themselves | Appreciated, not required: "Pixel Sci-Fi Tileset by reodesuxz" |

Composed by the asset author (not the raw pack) from the pack's x4 (64x64)
tiles: base `floor_dark_1`, scattered `floor_dark_2`, `floor_steel_2` accents
and `floor_vent` tiles, in a fixed 8x8 grid. Every tile is seamless, so the
512px image tiles seamlessly too (verified: 2x2 repeat shows no seam).
Dark charcoal metal panels with rivets/speckles — fills the 720x1280 arena
without looking empty. The pack's `floor_hazard` (yellow stripes) was NOT
used.

## 2. Core (glowing orb)

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/core/orb.png` | 256x256 | "Energy Ball", https://lpc.opengameart.org/content/energy-ball (file `ball_2.png`, 3x3 grid of plasma balls) | yiannisd | **CC-BY 3.0** | **Required**: "Energy Ball" by yiannisd, CC-BY 3.0 |
| `art/core/glow.png` | 256x256 | Same source, derived | yiannisd | **CC-BY 3.0** | **Required**: same as above |

`orb.png`: the largest ball of the grid (cell x18-86, y8-75, 68x67px),
Lanczos-upscaled to 232px and centered on a transparent 256x256 canvas.
Blue plasma ball with a white-hot core — a real layered energy sprite, not a
flat circle. `glow.png`: the same ball upscaled to 256px and heavily
Gaussian-blurred (radius 22) — a soft radial halo to layer under/behind the
orb. Both are CC-BY: the credit line above covers both.

## 3. Weapons

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/weapons/blade.png` | 64x128 | "Swords - Set 4", http://opengameart.org/content/swords-set-4 (`Sword_1/68.png`) | Cethiel | **CC0** | None required |
| `art/weapons/chain_link.png` | 24x24 | game-icons.net, `delapouite/ring` (PNG endpoint) | Delapouite | **CC-BY 3.0** | **Required**: game-icons.net credit (see credits list) |
| `art/weapons/chakra.png` | 128x128 | game-icons.net, `lorc/circular-sawblade` (PNG endpoint) | Lorc | **CC-BY 3.0** | **Required**: game-icons.net credit (see credits list) |
| `art/weapons/bolt.png` | 32x32 | Kenney "Space Shooter Redux", `PNG/Lasers/laserRed08.png` | Kenney | **CC0** | None required |

Derivations:
- `blade.png`: Sword_1/68 (23x157, slim straight sword, blue blade, gold
  guard, red gem, pointing up) scaled to 128px tall, centered on a 64x128
  transparent canvas. The ornate Sword_2 was rejected as too busy.
- `chain_link.png`: the `delapouite/ring` icon (a clean 3D ring band, white)
  tinted to light steel grey and downscaled to 24x24. Note: the
  `skoll/breaking-chain` and `lorc/andromeda-chain` icons were tried first —
  their links are open C-shapes / interlocked fragments and read as a hook at
  24px, so the ring was used instead. A ring IS a chain link; the whip chain
  is a run of these.
- `chakra.png`: Lorc's circular sawblade (swirling spiked disc, hex hub)
  tinted very lightly toward steel-blue (kept near-white so the game's heat
  modulate tints it well) and downscaled to 128x128.
- `bolt.png`: Kenney's round spiked laser orb `laserRed08` (48x46) recolored
  red -> orange (green channel boosted, blue cut) and downscaled to 32x32.
  Round and direction-independent, so it works as a projectile from any
  angle. It is a recolored laser, not a purpose-drawn orange bolt.

## 4. UI

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/ui/panel.png` | 256x256 | Kenney "UI Pack: Sci-fi", `PNG/Blue/Default` bar pieces | Kenney | **CC0** | None required |
| `art/ui/button.png` | 192x64 | Kenney "UI Pack: Sci-fi", `button_square_header_large_rectangle.png` | Kenney | **CC0** | None required |
| `art/ui/icons/spin.png` | 64x64 | Kenney "Game Icons", `PNG/White/2x/gear.png` | Kenney | **CC0** | None required |
| `art/ui/icons/damage.png` | 64x64 | Kenney "Game Icons", `PNG/White/2x/target.png` | Kenney | **CC0** | None required |
| `art/ui/icons/repair.png` | 64x64 | Kenney "Game Icons", `PNG/White/2x/wrench.png` | Kenney | **CC0** | None required |
| `art/ui/icons/orb.png` | 64x64 | Derived from `art/core/orb.png` (see section 2) | yiannisd | **CC-BY 3.0** | **Required**: yiannisd credit (see credits list) |
| `art/ui/icons/chain.png` | 64x64 | Derived from `art/weapons/chain_link.png` (see section 3) | Delapouite | **CC-BY 3.0** | **Required**: game-icons.net credit |
| `art/ui/icons/chakra.png` | 64x64 | Derived from `art/weapons/chakra.png` (see section 3) | Lorc | **CC-BY 3.0** | **Required**: game-icons.net credit |

Notes:
- `panel.png` is composed (the Sci-fi UI pack has no panel file): 24px
  borders from the pack's `bar_square_large_square` (corners) and
  `bar_square_large_m` (edges, rotated for the sides), dark slate
  (#1A2634) center fill. 9-slice margins: 24px on all sides.
- `button.png` is the pack's header button verbatim (blue header band +
  light grey body, 192x64). The `_screws` variant exists in the pack if the
  integrator prefers it.
- Icon files are white silhouettes (Kenney) or light-steel/blue (derived) on
  transparent — designed for a dark UI; the integrator can modulate them.
  Kenney "Game Icons" has NO orb/coin, chain or chakra icons, which is why
  orb/chain/chakra icons are downscales of the game art instead.

## 5. Font

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `fonts/KenneyFuture.ttf` | 34 KB | Kenney "Kenney Fonts" pack, `Fonts/Kenney Future.ttf` | Kenney | **CC0** | None required |

Sci-fi display font, the standard Kenney Future face.

## 6. Robots

No pack anywhere (Kenney / itch.io / OpenGameArt, searched 2026-11-12/13)
ships robots as **separate part sprites** (torso/head/arm/leg files). All
robot sources are single-body sprites, so the slicing route is used: whole
frames are shipped, plus pre-sliced part PNGs for the standard robot and
exact pixel rects below. The game's `enemy.gd` part model (torso, head,
arm_l, arm_r, leg_l, leg_r; ranged +cannon; boss +crown/shoulder/chestplate/
eyes) maps onto these rects.

### 6a. Standard robot — ArtManOil "Bots and Bolts"

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/robots/standard_idle.png` | 48x48 | "Bots and Bolts" player pack, https://art-man-oil.itch.io/bots-and-bolts-player (`Character/Front/Standing/Front_Standing_Idle_1.png`) | ArtManOil | Free for commercial or non-commercial use; may modify; may NOT resell or redistribute (even modified) | Appreciated, not required: "https://art-man-oil.itch.io/" |
| `art/robots/standard_walk.png` | 48x48 | Same pack, `Front_Standing_Walk_3.png` | ArtManOil | Same | Same |
| `art/robots/standard_hurt.png` | 48x48 | Same pack, `Front_Standing_Hurt_1.png` | ArtManOil | Same | Same |
| `art/robots/standard_attack.png` | 48x48 | Same pack, `Front_Standing_Attack_3.png` | ArtManOil | Same | Same |
| `art/robots/standard_head.png`, `standard_torso.png`, `standard_arm_l.png`, `standard_arm_r.png`, `standard_leg_l.png`, `standard_leg_r.png` | see rects | Pre-sliced from `standard_idle.png` by the asset author | ArtManOil | Same | Same |
| `art/robots/shielded_idle.png` | 48x48 | Same frame, blue-tinted (blend toward #4682FF at 45%) by the asset author | ArtManOil | Same | Same |

Front-view humanoid robot, blue-grey with orange visor, 4-direction pack
(Front/Back/Left/Right) with Idle/Walk/Run/Attack/Hurt/Jump animations.
Only the Front direction is shipped (the game rotates enemies toward the
core). The robot occupies x14-32, y9-38 inside the 48x48 frame (center
~23,23); the rest is transparent padding.

**Slicing plan — standard robot, measured on `standard_idle.png` (48x48).
Rect format: (x, y, width, height), origin top-left:**
- `head` — (16, 9, 15, 14): domed head + face (red eyes) + antenna tip.
- `torso` — (15, 23, 17, 7): dark chest block below the face.
- `arm_l` — (14, 23, 3, 11): left side column.
- `arm_r` — (30, 23, 3, 11): right side column.
- `leg_l` — (14, 30, 9, 9): left lower body + foot taper.
- `leg_r` — (24, 30, 9, 9): right lower body + foot taper.

Caveats, measured honestly: this is a compact 48px sprite, so the arms are
flush to the torso — the arm rects overlap the torso rect by 2px on each
side, and the leg rects include the hip edges. The parts are NOT a perfect
jigsaw; use them as AtlasTexture regions and let the dismantle read via the
part flying off + the game's debris scatter, not via a clean separation.
The same rects apply to `shielded_idle.png` (same frame, blue tint).
The shield ring itself is drawn by the game code, not by the sprite.

### 6b. Ranged robot — Sova Digital "Free Combat Drone"

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/robots/ranged_idle.png` | 148x128 | "Free Combat Drone", https://sovdigital.itch.io/free-combat-drone (base/steel-grey drone, S direction, `_sizes/128` idle frame) | Sova Digital | Use in unlimited personal/commercial games; modify/recolor/resize/cut apart OK; may NOT resell/redistribute as assets, claim as own, use for ML datasets, or NFTs | Appreciated, not required: "Characters by SovDigital" |
| `art/robots/ranged_walk.png` | 148x128 | Same pack, walk frame | Sova Digital | Same | Same |
| `art/robots/ranged_attack.png` | 148x128 | Same pack, attack frame (barrels visible) | Sova Digital | Same | Same |
| `art/robots/ranged_hurt.png` | 148x128 | Same pack, hurt frame | Sova Digital | Same | Same |
| `art/robots/ranged_death.png` | 148x128 | Same pack, death frame (wreck) | Sova Digital | Same | Same |
| `art/robots/LICENSE-sovdigital.txt` | — | The pack's LICENSE.txt, copied verbatim | Sova Digital | — | — |

Detailed armored hover drone, steel-grey with a central red eye/core and
twin side pods. True top-down 2.5D sprite — the highest-detail robot in the
set. Sprite bbox inside the 148x128 frame: x18-127, y20-107.

**Slicing plan — ranged drone: none.** It is a single rigid hover unit with
no limbs, so limb part-slicing does not apply. Hits should remove whole-unit
HP and the death frame shows the wreck; dismantling reads via the debris
system, not part separation. The "cannon" (game's ranged part) is integral:
twin side pods with orange barrel tips on the lower sides of the attack
frame (measured orange barrel-tip pixels at x22-69 and x105-109, y77-102).
No separate cannon file is shipped — use the full attack frame.

### 6c. Boss robot — Sova Digital "Free Combat Drone", red variation

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/robots/boss_idle.png` | 222x192 | Same pack, Faction Red variation, idle frame 000 of the S row (cropped from the 5328x1536 sheet) | Sova Digital | Same as 6b | Same as 6b |
| `art/robots/boss_attack.png` | 222x192 | Same pack, red variation, attack frame 012 of the S row | Sova Digital | Same as 6b | Same as 6b |
| `art/robots/boss_crown.png` | 64x64 | game-icons.net, `lorc/crown`, recolored gold | Lorc | **CC-BY 3.0** | **Required**: game-icons.net credit |

Cream/red armored drone, clearly distinct from the grey ranged drone, with
a glowing red core. Same slicing note as 6b: rigid unit, no limb parts.
The crown is a separate sprite because no robot pack ships a crown: place
`boss_crown.png` above the head at the game's crown offset (0, -1.05r in
`enemy.gd`), scaled to ~40px wide for the boss (r=64).

### 6d. Extra top-down bots (alternates, from the floor tileset pack)

| File | Size | Source | Author | License | Credit |
|---|---|---|---|---|---|
| `art/robots/extra_scout.png` | 64x64 | reodesuxz tileset, `PNG/x4/enemies/bot_scout_1.png` | reodesuxz | Same as section 1 | Same as section 1 |
| `art/robots/extra_guard.png` | 64x64 | reodesuxz tileset, `PNG/x4/enemies/bot_guard_1.png` | reodesuxz | Same as section 1 | Same as section 1 |
| `art/robots/extra_drone.png` | 64x64 | reodesuxz tileset, `PNG/x4/enemies/drone_1.png` | reodesuxz | Same as section 1 | Same as section 1 |

True top-down 16x16 pixel robots (upscaled 4x in the pack). Much simpler
than the ArtManOil/Sova robots — shipped only as alternates if the
integrator wants top-down purity for the standard robot instead of the
front-view ArtManOil sprite. No slicing plan; single-body sprites.

---

## 7. Rejected / checked but NOT used

- **"Pixel Space Shooter" pack (riclmbr.itch.io)** — REJECTED: not free.
  The itch page requires purchase (min price $5.99). Do not use.
- **"Patterned Metal Floor Texture" by Sindwiller (LPC node 3419)** —
  REJECTED: license is GPL 2.0 / GPL 3.0 / CC-BY-SA 3.0 (share-alike / GPL,
  not allowed for this game). Also a GIMP `.xcf`, not PNG.
- **"Round Spiked Saw Blade" by AnaMayArt (opengameart.org)** — REJECTED:
  license CC-BY-SA 3.0 / 4.0 (share-alike, not allowed). The Lorc
  circular-sawblade (CC-BY, section 3) was used instead.
- **"Pixel Saw Blade" (OpenGameArt)** — node URL never found (only appears
  in Latest Art listings); not pursued. Lorc sawblade used instead.
- **"Top-Down: Robot" (OpenGameArt)** — node URL never found; not pursued.
  ArtManOil + Sova cover robots.
- **"Free Laser Bullets Pack 2020" (OpenGameArt)** — node URL never found;
  not pursued. Kenney lasers cover the bolt.
- **"Machine War Asset Package" (DarkCybernetics, itch.io)** — checked,
  deprioritized: 64x64 sprites are crude (tiny white/grey humanoid) and the
  license text was not verified in detail. Not used.
- **CALWebDevelopment "TopDown Pack" v1.1 (itch.io, CC0)** — downloaded and
  license-verified (CC0, `license.txt` in the pack), but NOT used in any
  final file: its floor tiles are plain tan/beige (wrong for a dark arena)
  and the "Garth" robot from the search snippet is not in v1.1. Kept on
  record as a checked source; no file from it ships.
- **Kenney "Sci-Fi RTS"** — checked: units are top-down vehicles/tanks and
  the terrain is orange/rust, not usable for a dark metal arena or humanoid
  robots. Not used.
- **Kenney "Top-Down Shooter" Robot 1** — checked: small (33-54x43) grey
  front-view robot with gun, low detail. Not used; ArtManOil is better.
- **Kenney "Tower Defense Top-Down"** — checked, no usable robot/floor for
  this game. Not used.

## 8. Known gaps / honest notes for the integrator

- **No separate robot part sprites exist** in any license-clean pack found.
  The slicing plan in section 6a is the fallback, and the standard robot's
  parts overlap slightly (see caveats). The drones have no separable parts
  at all.
- **No separate crown asset in a robot pack.** The boss crown is a
  game-icons crown icon, recolored gold.
- **The bolt is a recolored Kenney laser**, not a purpose-drawn orange bolt.
- **The floor is composed pixel-art tiles**, not a photographic metal
  texture — it is the best license-clean option found (the only photographic
  metal floor found was GPL/CC-BY-SA).
- **The chain link is a ring icon**, not a photographed chain link — but a
  ring is exactly what a chain link is, and it reads correctly at 24px.
- **The shielded robot is a blue tint of the standard robot**, not a
  distinct sculpt — that matches the game's own model (same body + shield
  ring drawn in code, tinted blue).
- The `audio/` folder next to `art/` was already in the assets directory
  before this work and is NOT part of this manifest.
