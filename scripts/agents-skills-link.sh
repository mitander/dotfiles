#!/usr/bin/env bash
# Share personal skills with Claude Code, Codex and Copilot without replacing
# files or directories managed by those harnesses.
set -euo pipefail

# Require the source checkout before creating any target directories.
src="${HOME}/.agents/skills"
if [[ ! -d "${src}" ]]; then
  echo "Missing skill source checkout: ${src}" >&2
  echo "Clone mitander/agent-config to ~/.agents first." >&2
  exit 1
fi

targets=(
  "${HOME}/.claude/skills"
  "${HOME}/.codex/skills"
  "${HOME}/.copilot/skills"
)

linked=0
for target in "${targets[@]}"; do
  mkdir -p "${target}"
  for skill_dir in "${src}"/*/; do
    skill_dir="${skill_dir%/}"
    [[ -f "${skill_dir}/SKILL.md" ]] || continue
    name="$(basename "${skill_dir}")"
    link="${target}/${name}"

    # Keep correct links and real paths. Only missing or stale links need repair.
    if [[ -L "${link}" && "$(readlink "${link}")" == "${skill_dir}" ]]; then
      continue
    fi
    if [[ -e "${link}" && ! -L "${link}" ]]; then
      echo "skip ${link} (real directory managed by another tool)" >&2
      continue
    fi

    ln -sfn "${skill_dir}" "${link}"
    linked=$((linked + 1))
    echo "linked ${link}"
  done
done

echo "${linked} symlinks updated."
