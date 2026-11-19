# roblox-brainrot-game

[![competition](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/chipuystar/roblox-brainrot-game/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/chipuystar/roblox-brainrot-game/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

**Pasar Brainrot** is a 3D night-market game for make.fun's "Make the best AI Roblox brainrot game"
bounty (roblox-brainrot-01), in the genre Steal a Brainrot began — with a cast of its own: nine
original Indonesian snack characters, from the humble Bakso Berlari to the mythic Nasi Padang
Sejagat. The whole world is built from plain Roblox parts: no uploaded assets, no sounds, just
parts, lights and scripts.

Play it: https://www.roblox.com/games/120794548284459

## How to play

Nine brainrots walk the raised orange conveyor through a sunset market. Walk up to one and press
**E** to buy it, carry it home above your head, and it starts earning dollars every second once it
stands on a pedestal in your lapak. Other players can steal a placed brainrot by pressing E on it —
unless you lock your lapak with **Kunci Lapak** (30 seconds locked, 90 seconds cooldown). Every 90
seconds the **Gerobak Tsunami** sweeps the market: a wall of runaway carts that knocks down anyone
caught outside a lapak and sends what they carry back to the belt. Earn enough and you can rebirth
for a permanent +25% income multiplier, and buy upgrades: faster shoes, a second pair of hands, and
a golden scale that raises every brainrot's pay.

## Run it

Build the place with Rojo (7.7.1):

    rojo build default.project.json --output game.rbxl

then publish `game.rbxl` over the experience in Roblox Studio, or open it there to play-test.

## Controls

- **WASD** — walk
- **E** — buy a brainrot on the belt, or take one from a lapak
- **Buttons (right side)** — Kunci Lapak, Rebirth, Upgrade, Index; on touch devices they fold
  into one MENU pill so they never cover the jump button

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and
  writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/server/Config.luau` — every tuning number: characters, rarities, belt, lapak, wave, locks,
  rebirths, upgrades.
- `src/server/WorldBuilder.luau` — builds the market at runtime: belt, six lapak, lamps, food
  stalls, welcome arch, crates, barrels and the starfield.
- `src/server/MoneyService.luau` — cash, lifetime earnings, rebirths and upgrade levels, mirrored
  to leaderstats and attributes; the one-second income loop.
- `src/server/BrainrotSpawner.luau` — builds the nine characters, walks them down the belt, sells
  them, and returns dropped ones to the belt.
- `src/server/BaseService.luau` — lapak assignment, carrying, placement, locks and stealing.
- `src/server/WaveEvent.luau` — the Gerobak Tsunami countdown, warning and sweep.
- `src/server/RebirthService.luau` — rebirths and upgrade purchases.
- `src/server/init.server.luau` — wires the services together and connects the remotes.
- `src/client/GameUI.client.luau` — the HUD: money panel, wave countdown, action buttons, hint
  bar, toasts, upgrade and index panels, title overlay.
- `src/client/Effects.client.luau` — particle bursts, the tsunami banner, screen shake and the
  client-side knockback.
- `screenshots/` holds four captures of the game; the first by name, `1-cover.jpg`, is also the
  game's thumbnail on Roblox.
- `PLAY.json` names the published place; `TOUR.json` is the optional tour for reviewers.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.

Built with Quill for make.fun — https://make.fun/r/0cyw4zjw
