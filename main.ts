// Pasar Brainrot — the make.fun roblox-brainrot-01 entrypoint (Node 22, standard library only).
//
// This program hands the game in. It copies the built place (game.rbxl), the Luau sources
// (src/), the screenshots (screenshots/) and the play link (PLAY.json) from beside this file
// into the output directory, then writes the dossier the judge reads with the vendored
// make.fun library.
//
// Run it the way the grader does:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// The grader refuses any name under /output that does not start with a letter, a digit or _,
// so dotted names (.gitkeep, .DS_Store, .git) are filtered out at every depth while copying.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// cpSync filter: skip every file and directory whose name starts with a dot.
function isVisible(entryPath: string): boolean {
	return !basename(entryPath).startsWith(".");
}

mkdirSync(outDir, { recursive: true });

// Fail fast with a readable message when the place has not been built yet.
if (!existsSync(join(repoRoot, "game.rbxl"))) {
	throw new Error("game.rbxl is missing: build it first with `rojo build default.project.json --output game.rbxl`.");
}

copyFileSync(join(repoRoot, "game.rbxl"), join(outDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outDir, "PLAY.json"));
cpSync(join(repoRoot, "src"), join(outDir, "src"), { recursive: true, filter: isVisible });
mkdirSync(join(outDir, "screenshots"), { recursive: true });
if (existsSync(join(repoRoot, "screenshots"))) {
	cpSync(join(repoRoot, "screenshots"), join(outDir, "screenshots"), {
		recursive: true,
		filter: isVisible,
	});
}

// The scorer's own caps: text_max_bytes shapes the dossier text; the rest refuse an entry
// the scorer would refuse (more than 4 screenshots, or one over 256 KiB; a place of more
// than 500000 instances, whose scripts' sources come to over 8 MiB, or whose scripts'
// paths come to over 1048576 characters in all).
const dossier = buildDossier(outDir, {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
});
writeFileSync(join(outDir, "dossier.json"), dossier);
