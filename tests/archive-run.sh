#!/usr/bin/env bash
# Copies a live run's evidence into a folder (docs/verification/…): reports, logs, the job's .work/ (without worktrees),
# the claude -p transcripts and the delivered git history. Colour codes are stripped; nothing else is changed.
#   tests/archive-run.sh <live run dir (has repo/)> <destination dir> [console output file]
set -euo pipefail
src=${1:?usage: archive-run.sh <run dir> <dest> [console file]}; dst=${2:?}; con=${3:-}
mkdir -p "$dst/work"
strip() { sed 's/\x1b\[[0-9;]*m//g' "$1"; }
for f in report.md run.log doctor.log install.log init.log oracle.log drive.log; do [[ -f $src/$f ]] && strip "$src/$f" > "$dst/$f"; done
[[ -n $con && -f $con ]] && strip "$con" > "$dst/console.txt"
R=$src/repo
J="$(ls -d "$R"/.work/JOB-* | sort | tail -1)"
(cd "$R/.work" && tar --exclude="$(basename "$J")/wt" --exclude='*.lock' -cf - "$(basename "$J")" $( [[ -d runs ]] && echo runs )) | tar -xf - -C "$dst/work"
git -C "$R" log --all --graph --format='%h %ad %an <%ae>  %s' --date=format:'%H:%M:%S' > "$dst/git-log.txt"
git -C "$R" log --all --format='%H%n%B%n----' > "$dst/git-messages.txt"
echo "archived $(basename "$J") → $dst ($(du -sh "$dst" | cut -f1))"
