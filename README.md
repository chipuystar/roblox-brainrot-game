# roblox-brainrot-game — Pasar Brainrot

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/chipuystar/roblox-brainrot-game/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/chipuystar/roblox-brainrot-game/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

Pasar Brainrot is a 3D night-market game in the Steal a Brainrot genre, built
entirely from plain Roblox parts — no uploaded assets. Nine original Indonesian
snack characters walk along a raised orange conveyor belt through a sunset
market: Bakso Berlari, Es Teh Manis Terbang, Gorengan Galak, Kucing Oren
Ngamuk, Ayam Geprek Terbang, Durian Meledak, Kopi Tubruk Raksasa, Gerobak
Bakso Terbang and the Mythic Nasi Padang Sejagat.

How to play: walk up to a brainrot on the belt, press **E**, pay its price,
and carry it home above your head to your own lapak (base). Placed on a
pedestal, it earns dollars per second. Other players can steal a placed
brainrot unless your lapak is locked (Kunci Lapak, 30 seconds, 90-second
cooldown). Every ~90 seconds a Gerobak Tsunami — a wall of runaway carts —
sweeps the market and knocks down anyone caught outside a lapak, dropping what
they carry. Rebirth four times for permanent income multipliers, and buy
upgrades: Sepatu Kilat (walk speed), Tangan Kedua (carry 2 at once) and
Timbangan Emas (+25% income per level).

Play it: https://www.roblox.com/games/120794548284459

## Run it

Build the place with Rojo 7.7:

    rojo build default.project.json --output game.rbxl

Publish `game.rbxl` to the Roblox place (Open Cloud Assets API), or open it
in Roblox Studio to play-test. Controls: **WASD** to walk, **E** to buy / take
a brainrot, the buttons on the right for Kunci Lapak, Rebirth, Upgrade, Index
and Musik. On touch devices the buttons live behind one small MENU pill at the
top right.

## Layout

- `main.ts` — the entrypoint: copies the game into /output and writes dossier.json.
- `default.project.json` — the Rojo project (sunset Lighting, remotes, services, baseplate + spawn).
- `src/server/` — Config, WorldBuilder, BrainrotSpawner, MoneyService,
  BaseService, ProgressionService, WaveEvent, init.server.
- `src/client/` — GameUI (HUD), Effects (particles, tsunami banner, knockback),
  Music (looping "Happy Song" + mute toggle).
- `src/` is the Luau in `game.rbxl`; `screenshots/` holds the four captures
  (the first by name, 1-cover.jpg, is the game's Roblox thumbnail).
- `PLAY.json` — the published place (place_id 120794548284459,
  universe_id 10777455489). `TOUR.json` — a 4-step tour of the screenshots.
- `vendor/makefun-roblox.ts` — the kit's dossier library, unchanged.

## Grade it

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Built with an AI agent for the make.fun bounty — earn money making games with
AI: https://make.fun/r/0cyw4zjw
