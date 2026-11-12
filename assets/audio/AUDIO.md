# Kinetic Whip 2D — Real Audio (replaces procedural SFX + music)

Delivered 2026-11-13. All files WAV, 44.1 kHz, 16-bit. SFX are mono,
music is stereo. Total: **11,561,590 bytes (~11.0 MiB)** — under the ~15 MB
web-export budget. No game code was changed; these are drop-in files for
the integrator to wire into `scripts/audio.gd`.

## Sources and licences

### 1. All SFX — Sonniss GDC 2026 Game Audio Bundle
- Bundle page: https://sonniss.com/gameaudiogdc/ and https://gdc.sonniss.com/
- Licence page (read 2026-11-12): https://sonniss.com/gdc-bundle-license/
- Licence: **Sonniss #GameAudioGDC Bundle Licence, Version 2.0, effective
  27 August 2026** (a copy of the licence PDF is inside bundle part 5).
  Worldwide, non-exclusive, royalty-free licence; unlimited projects for
  life; personal **and commercial** use; sounds may be modified; **no
  attribution required**. Restrictions: do not sell / distribute / sub-licence
  the sounds as sound effects (in any form, including modified or re-designed,
  as a library, sample pack, asset pack or template); do not use the sounds
  for AI training. Finished games using the sounds may be shared, published
  and sold normally.
- Download: the bundle is 5 zip parts (7.47 GB total). Only the parts
  containing the sounds used here were touched, and only the listed files
  were extracted (via HTTP range requests — the full 7.47 GB was never
  downloaded):
  - Part 2: https://downloads.sonniss.com/Sonniss.com-GDC2026-GameAudioBundle2of5.zip
  - Part 3: https://downloads.sonniss.com/Sonniss.com-GDC2026-GameAudioBundle3of5.zip
  - Part 5: https://downloads.sonniss.com/Sonniss.com-GDC2026-GameAudioBundle5of5.zip
- Credit required: **No.** Optional credit line (not used in-game):
  "Sound effects from the Sonniss GDC 2026 Game Audio Bundle (sonniss.com)"
- Fallback sources (Kenney / Freesound) were **not needed** — every SFX slot
  has a real Sonniss match. Nothing was left out.

### 2. Music — Mixkit
- Track: **"Cyberpunk City" by Alejandro Magaña (A. M.)**, Ambient,
  1 min 40 s original, found on the Mixkit cinematic listing
  https://mixkit.co/free-stock-music/tag/cinematic/
- Audio file: https://assets.mixkit.co/music/140/140.mp3 (256 kbps MP3, 44.1 kHz
  stereo — converted to WAV 44.1 kHz 16-bit for format consistency; the
  conversion adds no quality)
- Licence: **Mixkit Stock Music Free License**,
  https://mixkit.co/license/#musicFree (confirmed on the track's metadata:
  "Mixkit Stock Music Free License", free to access). Free for commercial
  use, including games; **no attribution required**; may not be resold as-is,
  registered with a rights-management service, or claimed as your own work.
- Credit required: **No.** Optional credit line:
  "Music: 'Cyberpunk City' by Alejandro Magaña (A. M.), via Mixkit (mixkit.co)"

## Files

LUFS = integrated loudness re-measured on the delivered file (EBU R128).
TP = true peak. SFX were normalised toward -16 LUFS; short transient
sounds (hit, orb, core_hit, unlock) are peak-limited at -1.5 dB TP, so
their LUFS reads lower — that is normal for transients and they still peak
near full scale. Music was normalised to -14 LUFS.

| File | Game event | Source file (Sonniss bundle part) | Duration | Size | LUFS / TP |
|---|---|---|---|---|---|
| `sfx/hit.wav` | Whip impact — metallic clink (`play_hit`) | `Epic Stock Media - HD Game Materials/METLImpt_Metal Old File Impact Tap Against Tire Iron Metallic Hit 01_ESM_HDGM.wav` (Part 2). Single bright metallic tap, spectral centroid ~6.2 kHz, 73% of energy 3–8 kHz. | 0.47 s | 41,988 B | -20.2 / -1.5 dB |
| `sfx/shatter.wav` | Robot shatters into parts (`play_shatter`) | `Epic Stock Media - Tower Defense Game/ICEBrk_Skill Freeze Whoosh Break Impact Layered Movement Shatter 03_ESM_TDG.wav` (Part 2). Noise burst + debris, loudest at 0.3 s, trimmed to the first 1.1 s. | 1.10 s | 97,430 B | -16.0 / -5.1 dB |
| `sfx/shield_break.wav` | Blue shield breaks (`play_shield_break`) | `Epic Stock Media - Elemental Mutation Whooshes and Impacts/GLASMvmt_Whoosh Glass Crystal Fragments Sharp Shards Dry 05_ESM_EMWI.wav` (Part 2). The file is a whoosh into glass; the 1.0–2.2 s slice is the glass-fragment burst (centroid ~8.5 kHz, 56% of energy 3–8 kHz). | 1.20 s | 106,472 B | -16.0 / -5.1 dB |
| `sfx/orb.wav` | Orb pickup blip (`play_orb`; code varies pitch per combo) | `Cinematic Sound Design - Interface & Infographics/Interface Pop High Short.wav` (Part 2). One clean bright blip. | 0.65 s | 57,406 B | -19.6 / -1.5 dB |
| `sfx/alarm.wav` | Boss-warning horn swell (`play_alarm`) | `Jake Fielding - Cinematic Horn Braams/DSGNBram____Cinematic Horn Braam, Epic, Cinematic, Dark, Instrument, Huge-67.wav` (Part 3). Low horn braam: 43% of energy below 300 Hz, centroid ~590 Hz. The 3.0–5.5 s slice is the swell up to its peak. | 2.50 s | 220,760 B | -16.0 / -3.3 dB |
| `sfx/upgrade.wav` | Upgrade chime arpeggio (`play_upgrade`) | `Cinematic Sound Design - User Interface/Button Arp Twinkle.wav` (Part 2). Bright arp, trimmed to the first 1.0 s (the tail after that is near-silent). | 1.00 s | 88,602 B | -16.0 / -2.7 dB |
| `sfx/core_hit.wav` | Core takes damage — low heavy thud (`play_core_hit`) | `The Noisery - Moaning Metal/DSGNImpt_Metal Hit Thud Thump Low Ring Geofon 1_The Noisery_Moaning Metal.wav` (Part 5). 100% of energy below 300 Hz, centroid ~165 Hz. Trimmed to the first 1.0 s (attack + ring). | 1.00 s | 88,298 B | -23.4 / -1.5 dB |
| `sfx/unlock.wav` | Chakra unlocked — bright fanfare (`play_unlock`) | `Epic Stock Media - Anime Game/DSGNStngr_Power Up Bright Positive Successful Light Saturation Crash Shimmer 05_ESM_AG.wav` (Part 2). Bright positive power-up sting. | 1.52 s | 134,658 B | -19.0 / -1.5 dB |
| `sfx/wave_clear.wav` | Wave cleared — soft major chime (`play_wave_clear`) | `Cinematic Sound Design - User Interface/Interface Plucks Happy.wav` (Part 2). Soft happy plucks. | 0.85 s | 75,372 B | -16.0 / -1.8 dB |
| `sfx/deflect.wav` | **Bonus, not in the filename contract.** Shield deflect ping. The game code currently reuses the shield-break sound pitched up for deflect, so this file is optional. | `Cinematic Sound Design - System & UI Feedback Elements/Interface Sci-Fi Ping Down.wav` (Part 2). Short sci-fi ping, centroid ~1.4 kHz. | 0.75 s | 66,526 B | -16.0 / -3.0 dB |
| `music/cinematic_loop.wav` | Cinematic soundtrack loop (`start_music`) | Mixkit "Cyberpunk City" — see §2 above. | 60.00 s | 10,584,078 B | -14.0 / -3.2 dB |

## Music loop construction (read before changing it)

"Cyberpunk City" is a near-constant ambient bed (per-5 s mean level stays
between -15.8 and -13.3 dB across the whole 1:40), so it loops well. The
delivered 60 s loop was built from the 8–72 s window of the track (skipping
the quiet 0–5 s intro): the first 4 s of the window (8–12 s) was
crossfaded over the last 4 s (68–72 s) with a 4 s triangular acrossfade,
and the middle (12–68 s) placed in front, giving a 60.0 s file whose end
is the same musical instant as its start. Verified: the sample step across
the loop boundary (0.019) is the same size as a typical sample-to-sample
step mid-file (0.016) — no click. First/last 1 s RMS differ only because
of the track's own slow swell. If the loop ever needs to be longer, redo
the same edit on the full track; do not just concatenate the file with
itself (the intro swell would dip once per loop).

## Processing applied to every file

- ffmpeg only. Sources were 24-bit, 48–192 kHz stereo WAV (Sonniss) or
  256 kbps MP3 (Mixkit).
- SFX: trim to the segment listed above → downmix to mono → 2-pass EBU
  R128 loudnorm (SFX -16 LUFS, music -14 LUFS, true-peak ceiling -1.5 dB)
  → short fades at edit points to remove clicks → resample 44.1 kHz →
  PCM 16-bit WAV. Short fade-outs were added at each trim end.
- All delivered files verified with ffprobe and Python `wave`: 44.1 kHz,
  16-bit, correct channel count, no clipping (true peak ≤ -1.5 dBFS).
- Nothing was upsampled to fake quality: the Mixkit MP3 was converted to
  WAV for format consistency only.

## Candidates considered and not used

- hit alternate: David Dumais "METAL SWING HIT … Metallic Body Impact And
  Resonant Tail" (Part 2, 2.93 s) — swing + impact + long tail; too long
  and the impact sits 0.3 s in. The single tap won for a rapid-fire hit.
- shatter alternate: Anime Game "Explosion Small Blast Enemy Death" — boomier,
  less debris-like than the freeze shatter.
- shield_break alternate: "Interface Accept Glassy Snap" (0.44 s) — too thin.
- alarm alternate: Federico Soler "Effective Trailer Alarms Vol. 2,
  WholeNotes 011" (Part 2) — a loud sustained alarm tone, but the braam is
  the low horn the brief asked for. Braam "Huge-32" (Part 3) rises more
  slowly; "Huge-67" was used.
- upgrade alternate: CB Sounddesign "UIMisc_Kalimba 3 Up" — the rising
  kalimba notes after the first strike are very quiet.
- core_hit alternate: Federico Soler "Effective Trailer Booms Vol. 2, 011"
  (Part 2, 17 s) — huge sustained boom with a slow attack; the Moaning
  Metal thud attacks immediately.
- unlock alternate: InMotionAudio "ArcPowerUpDesign04" (Part 3, 7.48 s) —
  a long riser, not a fanfare.
- wave_clear alternate: CB Sounddesign "Magic Creation 23" (3.19 s) — long
  shimmer, not a short chime.
- music runner-up: Mixkit "Silent Descent" by Eugenio Mininni (2:40, Film
  Score) — darker and more dynamic; "Cyberpunk City" won on theme
  (neon sci-fi arena) and steadiness (better loop).

## Integrator notes

- File names match the contract exactly: `sfx/hit.wav`,
  `sfx/shatter.wav`, `sfx/shield_break.wav`, `sfx/orb.wav`,
  `sfx/alarm.wav`, `sfx/upgrade.wav`, `sfx/core_hit.wav`,
  `sfx/unlock.wav`, `sfx/wave_clear.wav`, `music/cinematic_loop.wav`.
- `sfx/deflect.wav` is extra (see table); wire it only if deflect gets its
  own stream — otherwise the existing pitched shield-break behaviour is
  unchanged.
- Godot import was not run in this sandbox (no Godot binary here); verify
  the files import cleanly in the editor / headless import before shipping.
- Licence compliance reminder: the Sonniss sounds must not be shipped as
  a standalone sound pack and must not be used for AI training. Shipping
  them inside the game is covered. No attribution is required for any file
  here, but the optional credit lines above are safe to include.
