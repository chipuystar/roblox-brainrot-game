// Pasar Brainrot — hands the Roblox place in to make.fun (roblox-brainrot-01).
// Node 22, standard library only. Copies game.rbxl, PLAY.json, src/ and
// screenshots/ from beside this file into /output (or MAKEFUN_OUTPUT_DIR
// outside the grader), then writes /output/dossier.json with the vendored
// make.fun library. The game itself is the Rojo project in this directory,
// built with `rojo build default.project.json --output game.rbxl`.
// The market is a golden-hour sunset scene: the cast of nine snack
// characters walks a neon-lit conveyor between six player lapak.
//
// The grader refuses any name under /output that starts with a dot, so the
// directory copies below skip dotted names at every depth (.gitkeep,
// .DS_Store, .git and the like never reach the output).

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// cpSync's filter: leave out every file and directory whose name starts with a dot.
const skipDotted = (path: string): boolean => !basename(path).startsWith(".");

mkdirSync(outDir, { recursive: true });
copyFileSync(join(repoRoot, "game.rbxl"), join(outDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outDir, "PLAY.json"));
cpSync(join(repoRoot, "src"), join(outDir, "src"), { recursive: true, filter: skipDotted });
mkdirSync(join(outDir, "screenshots"), { recursive: true });
if (existsSync(join(repoRoot, "screenshots"))) {
	cpSync(join(repoRoot, "screenshots"), join(outDir, "screenshots"), { recursive: true, filter: skipDotted });
}

// The scorer's own caps (only text_max_bytes shapes the bytes; the others
// refuse an entry the scorer would refuse: more than 4 screenshots or one
// over 256 KiB; a place of more than 500000 instances, whose scripts'
// sources come to over 8 MiB or whose scripts' paths come to over
// 1048576 characters, in all).
const GATE_CAPS = {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
};

writeFileSync(join(outDir, "dossier.json"), buildDossier(outDir, GATE_CAPS));
