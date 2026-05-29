#!/bin/bash
# Set up symlinks inside docs/ so MkDocs can build the site using the
# existing repo layout (labs/ at root, STORY.md / README.md at root).
# Idempotent — safe to re-run.

set -euo pipefail
cd "$(dirname "$0")/.."

ln -sfn ../labs docs/labs
ln -sfn ../README.md docs/index.md
ln -sfn ../STORY.md docs/STORY.md
ln -sfn ../CLAUDE.md docs/CLAUDE.md

# TODO.md lives at the repo root. README.md (rendered as docs/index.md)
# links to it as `TODO.md`, which under the docs/ build root resolves to
# docs/TODO.md — so mirror it in with a symlink. (It is intentionally kept
# out of exclude_docs so the link actually renders; see mkdocs.yml nav.)
ln -sfn ../TODO.md docs/TODO.md

# Lab READMEs link to `../../docs/practice/X.md` etc (correct paths on
# GitHub). For MkDocs (where docs/ is the build root), those resolve to
# docs/docs/practice/X.md — so we create docs/docs/ as a real directory
# with targeted symlinks pointing back into docs/. Avoids the
# infinite-recursion that a flat docs/docs → . symlink would cause.
mkdir -p docs/docs
ln -sfn ../concepts docs/docs/concepts
ln -sfn ../practice docs/docs/practice
ln -sfn ../reference-design docs/docs/reference-design
# vm-setup.md lives directly under docs/ (not in concepts/practice/
# reference-design), so README's `docs/vm-setup.md` link resolves to
# docs/docs/vm-setup.md. Mirror it in here. The nav points at this same
# docs/vm-setup.md path so the page has a single canonical URL.
ln -sfn ../vm-setup.md docs/docs/vm-setup.md

echo "docs/ symlinks in place:"
ls -la docs/labs docs/index.md docs/STORY.md docs/CLAUDE.md docs/TODO.md docs/docs/
