#!/usr/bin/env bash
# Swap the active koga config.sexp between the host (x86-64) and aarch64 cross
# builds. koga always reads the fixed name "config.sexp", so this copies the
# chosen variant over it. ALWAYS set the config to match the build dir you are
# about to `./koga` or `ninja -C <dir>` — koga bakes config into <dir>/build.ninja
# and may regenerate it from config.sexp, so a mismatched config.sexp corrupts it.
#
#   ./select-build.sh aarch64   # -> build-aarch64/   (ADSP-SC598 / Cortex-A55)
#   ./select-build.sh host      # -> build/           (native x86-64, LLVM 22)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
case "${1:-}" in
  host)    cp "$here/config-host.sexp"    "$here/config.sexp"; echo "config.sexp <- host    (build/)";;
  aarch64) cp "$here/config-aarch64.sexp" "$here/config.sexp"; echo "config.sexp <- aarch64 (build-aarch64/)";;
  *) echo "usage: $(basename "$0") host|aarch64" >&2; exit 2;;
esac
