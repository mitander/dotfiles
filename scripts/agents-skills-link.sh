#!/usr/bin/env bash
# Link every personal skill from ~/.agents/skills into the skill directories of
# the other agent harnesses (Claude Code, Codex, Copilot). Real directories that
# other tools manage (for example installed marketplace skills) are never
# touched; existing correct symlinks are left alone; stale symlinks are repaired.
set -euo pipefail

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
