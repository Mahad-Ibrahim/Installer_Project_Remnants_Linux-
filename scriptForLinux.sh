#!/usr/bin/env bash
set -e

#
# Requirements: jq
#
# Important Notice: If you have a custom place where you have project zomboid installed.
# then follow the following steps:
# 1. Go into the directory where project zomboid is installed.
# 2. Open terminal in that directory, usually it's right-click and "Open in terminal."
# 3. Type the command "pwd"
# 4. Copy that output.
# 5. Paste that path into the GAME_PATH="" in between the ""

echo "=== Project Remnants Linux Installer ==="

MOD_JAR="NPCFW.jar"

GAME_PATH=""

if [[ -n "${GAME_PATH}" ]]; then
	echo "Using user-defined custom path: ${GAME_PATH}"
elif [[ -e "${HOME}/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid" ]]; then
	GAME_PATH="${HOME}/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
elif [[ -e "${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid" ]]; then
	GAME_PATH="${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
else
	echo "Error: Project Zomboid not found in standard Native or Flatpak paths."
	exit 1
fi

JSON_FILE="${GAME_PATH}/ProjectZomboid64.json"

function cleanup() {
    # If the tmp file exists, delete it so we don't leave garbage behind
    if [[ -f "${JSON_FILE}.tmp" ]]; then
        rm -f "${JSON_FILE}.tmp"
    fi
    echo "[-] Script interrupted or failed. Backup is safe at: ${BACKUP_JSON_FILE}"
}

trap cleanup ERR SIGINT SIGTERM

if [[ ! -f "$MOD_JAR" ]]; then
	echo "[-] Error: ${MOD_JAR} not found. Please run this script directly inside the mod directory."
	exit 1
fi

if ! command -v jq &> /dev/null; then
	echo "[-] Error: 'jq' is not installed. Please install it (e.g., sudo apt install jq, sudo dnf install jq, sudo pacman -S jq)."
	exit 1
fi

echo "Copying ${MOD_JAR} to game root..."
cp "${MOD_JAR}" "${GAME_PATH}/"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_JSON_FILE="${JSON_FILE}.bak_${TIMESTAMP}"
cp "${JSON_FILE}" "${BACKUP_JSON_FILE}"

echo "Patching classpath and vmArgs..."
jq '
  .vmArgs += ["-javaagent:NPCFW.jar"] | .vmArgs |= unique
' "${JSON_FILE}" > "${JSON_FILE}.tmp" && mv -f "${JSON_FILE}.tmp" "${JSON_FILE}"

echo "Success! Project Remnants is installed."

