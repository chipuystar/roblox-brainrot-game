// main.ts — the Pasar Brainrot entrypoint (Node 22, standard library only).
//
// It hands the game in: it copies the Rojo-built place, the Luau sources,
// the screenshots and PLAY.json from beside this file into the output
// directory, then writes the dossier the judge reads with the kit's
// vendored library. The grader runs it twice and both runs must write the
// same bytes, so nothing here depends on the clock or on chance.
//
// Every name under /output starts with a letter, a digit or _ and holds only
// letters, digits, . _ and -: a dotted name such as .gitkeep anywhere under
// it fails the entry. The copy below skips every file and directory whose
// name starts with a dot, at every depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Copy a directory tree, leaving out every entry whose name starts with a dot.
function copyTree(fromDir: string, toDir: string): void {
	mkdirSync(toDir, { recursive: true });
	for (const entry of readdirSync(fromDir, { withFileTypes: true })) {
		if (entry.name.startsWith(".")) {
			continue;
		}
		const from = join(fromDir, entry.name);
		const to = join(toDir, entry.name);
		if (entry.isDirectory()) {
			copyTree(from, to);
		} else if (entry.isFile()) {
			copyFileSync(from, to);
		}
	}
}

mkdirSync(outDir, { recursive: true });
copyFileSync(join(repoRoot, "game.rbxl"), join(outDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outDir, "PLAY.json"));
copyTree(join(repoRoot, "src"), join(outDir, "src"));
if (existsSync(join(repoRoot, "screenshots"))) {
	copyTree(join(repoRoot, "screenshots"), join(outDir, "screenshots"));
}

// The scorer's own caps: only text_max_bytes shapes the bytes; the others
// refuse an entry the scorer would refuse (more than 4 screenshots or one
// over 256 KiB; a place of more than 500000 instances, whose scripts'
// sources come to over 8 MiB or whose scripts' paths come to over 1048576
// characters, in all).
const dossier = buildDossier(outDir, {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
});
writeFileSync(join(outDir, "dossier.json"), dossier);

// A one-line summary on stdout for the human running the hand-in; the grader
// only reads /output, so this changes no byte it checks.
console.log(`Pasar Brainrot handed in: ${dossier.length} bytes of dossier in ${outDir}.`);
