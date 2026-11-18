# roblox-brainrot-game

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/chipuystar/roblox-brainrot-game/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/chipuystar/roblox-brainrot-game/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Pasar Brainrot — a 3D night-market brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty. Nine original Indonesian snack characters (Bakso Berlari, Es Teh Manis Terbang, Gorengan Galak, Kucing Oren Ngamuk, Ayam Geprek Terbang, Durian Meledak, Kopi Tubruk Raksasa, Gerobak Bakso Terbang, Mythic Nasi Padang Sejagat) walk a conveyor through a neon night market. Buy one with E, carry it home to your lapak, and it earns $/second — then buy the next tier. Lock your lapak against thieves, outrun the Gerobak Tsunami every ~90 seconds, rebirth for permanent multipliers, and upgrade speed, carry capacity and income.

Play it: https://www.roblox.com/games/120794548284459

## Run it

```sh
rojo build default.project.json --output game.rbxl
```

Open `game.rbxl` in Roblox Studio and press Play. WASD to move, E to buy or take a brainrot, the buttons on the right for lock, rebirth, upgrades and the index.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/server/` — `Config` (tuning), `WorldBuilder` (the night market), `MoneyService` (cash state + income tick), `BaseService` (lapak, carrying, placement, lock, stealing), `BrainrotSpawner` (the cast + conveyor), `WaveEvent` (Gerobak Tsunami), `RebirthService` (rebirths + upgrades), `init.server` (wiring only).
- `src/client/` — `GameUI` (HUD, panels, toasts, title overlay), `Effects` (particles, tsunami banner, screen shake).
- `screenshots/` holds captures of the game running in Studio; the first by name is the cover and matches the experience's first thumbnail on Roblox.
- `PLAY.json` names the published place (place 120794548284459, universe 10777455489).

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.

---

<sub>Entered on [make.fun](https://make.fun/?ref=0cyw4zjw&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
