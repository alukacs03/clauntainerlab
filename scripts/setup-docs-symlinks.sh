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

# Lab READMEs link to `../../docs/practice/X.md` etc (correct paths on
# GitHub). For MkDocs (where docs/ is the build root), those resolve to
# docs/docs/practice/X.md — so we create docs/docs/ as a real directory
# with targeted symlinks pointing back into docs/. Avoids the
# infinite-recursion that a flat docs/docs → . symlink would cause.
mkdir -p docs/docs
ln -sfn ../concepts docs/docs/concepts
ln -sfn ../practice docs/docs/practice
ln -sfn ../reference-design docs/docs/reference-design

echo "docs/ symlinks in place:"
ls -la docs/labs docs/index.md docs/STORY.md docs/CLAUDE.md docs/docs/
