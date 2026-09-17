#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

lua_bin="${LUA_BIN:-}"
luac_bin="${LUAC_BIN:-}"

if [[ -z "$lua_bin" ]]; then
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    else
        lua_bin="lua"
    fi
fi

if [[ -z "$luac_bin" ]]; then
    if command -v luac5.1 >/dev/null 2>&1; then
        luac_bin="luac5.1"
    else
        luac_bin="luac"
    fi
fi

mapfile -t lua_files < <(find . -type f -name '*.lua' -not -path './.git/*' -print | sort)
for file in "${lua_files[@]}"; do
    "$luac_bin" -p "$file"
done

for test_file in tests/test_*.lua; do
    "$lua_bin" "$test_file"
done

vanilla_files="$(sed -n '/^[^#[:space:]].*\.lua$/p' SimpleScrollingLoot.toc)"
tbc_files="$(sed -n '/^[^#[:space:]].*\.lua$/p' SimpleScrollingLoot_TBC.toc)"
forever_files="$(sed -n '/^[^#[:space:]].*\.lua$/p' SimpleScrollingLoot_Camelot.toc)"
if [[ "$vanilla_files" != "$tbc_files" || "$vanilla_files" != "$forever_files" ]]; then
    echo "TOC Lua load orders differ between Vanilla, TBC, and Forever." >&2
    exit 1
fi

while IFS= read -r toc_file; do
    source_file="${toc_file//\\//}"
    if [[ ! -f "$source_file" ]]; then
        echo "TOC references missing file: $source_file" >&2
        exit 1
    fi
done <<< "$vanilla_files"

grep -qx '## Interface: 11509' SimpleScrollingLoot.toc
grep -qx '## Version: 0.6.0-beta.1' SimpleScrollingLoot.toc
grep -qx '## X-Flavor: Vanilla' SimpleScrollingLoot.toc
grep -qx '## AllowLoadGameType: vanilla' SimpleScrollingLoot.toc
grep -Fqx '## IconTexture: Interface\AddOns\SimpleScrollingLoot\assets\addon-icon.tga' SimpleScrollingLoot.toc
grep -qx '## Interface: 20506' SimpleScrollingLoot_TBC.toc
grep -qx '## Version: 0.6.0-beta.1' SimpleScrollingLoot_TBC.toc
grep -qx '## X-Flavor: TBC' SimpleScrollingLoot_TBC.toc
grep -qx '## AllowLoadGameType: tbc' SimpleScrollingLoot_TBC.toc
grep -Fqx '## IconTexture: Interface\AddOns\SimpleScrollingLoot\assets\addon-icon.tga' SimpleScrollingLoot_TBC.toc
grep -qx '## Interface: 16001' SimpleScrollingLoot_Camelot.toc
grep -qx '## Version: 0.6.0-beta.1' SimpleScrollingLoot_Camelot.toc
grep -qx '## X-Flavor: Forever' SimpleScrollingLoot_Camelot.toc
grep -Fqx '## IconTexture: Interface\AddOns\SimpleScrollingLoot\assets\addon-icon.tga' SimpleScrollingLoot_Camelot.toc
file assets/addon-icon.tga | grep -Fq '256 x 256 x 32'
test -f tools/windows/Deploy-WoW-Addons.cmd
test -f tools/windows/Deploy-WoW-Addons.ps1

echo "All Lua 5.1 and TOC checks passed."
