#!/usr/bin/env bash
# jdtls-launcher: wraps jdt-language-server with lombok, reads .vscode/settings.json
# for JDK home and JVM args.
#
# Environment variables (set by nix wrapper):
#   JDTLS_REAL           - path to the real jdtls binary
#   JDTLS_WRAPPED_SHARE  - path to our share dir (contains lombok.jar, java-debug-adapter/, java-test/)
#   LOMBOK_JAR           - path to lombok.jar
#
set -euo pipefail

EXTRA_ARGS=()

# Always inject lombok
EXTRA_ARGS+=("--jvm-arg=-javaagent:${LOMBOK_JAR}")

# Default JVM memory settings (sized for large projects)
DEFAULT_XMS="-Xms4G"
DEFAULT_XMX="-Xmx8G"

# Find workspace root by walking up from $PWD
find_workspace_root() {
	local dir="$PWD"
	while [ "$dir" != "/" ]; do
		for marker in build.gradle build.gradle.kts settings.gradle settings.gradle.kts pom.xml .git; do
			if [ -e "$dir/$marker" ]; then
				echo "$dir"
				return 0
			fi
		done
		dir=$(dirname "$dir")
	done
	echo "$PWD"
}

WORKSPACE_ROOT=$(find_workspace_root)
SETTINGS_FILE="$WORKSPACE_ROOT/.vscode/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
	# Strip JSONC comments before parsing:
	#   1. Remove full-line // comments (lines where // is first non-whitespace)
	#   2. Remove trailing // comments only after safe delimiters (, { [)
	#      This avoids mangling URLs like https://... inside string values
	SETTINGS=$(sed \
		-e 's|^\([[:space:]]*\)//.*$|\1|' \
		-e 's|\([,{[]\)[[:space:]]*//.*$|\1|' \
		"$SETTINGS_FILE" | jq -c '.' 2>/dev/null || echo "{}")

	# java.jdt.ls.java.home -> --java-executable <path>/bin/java
	JAVA_HOME=$(echo "$SETTINGS" | jq -r '.["java.jdt.ls.java.home"] // empty' 2>/dev/null || true)
	if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
		EXTRA_ARGS+=("--java-executable" "$JAVA_HOME/bin/java")
	fi

	# java.jdt.ls.vmargs -> individual --jvm-arg flags
	VMARGS=$(echo "$SETTINGS" | jq -r '.["java.jdt.ls.vmargs"] // empty' 2>/dev/null || true)
	if [ -n "$VMARGS" ]; then
		for arg in $VMARGS; do
			# Skip if it's a lombok agent (we already inject it)
			case "$arg" in
			*lombok*) continue ;;
			esac
			EXTRA_ARGS+=("--jvm-arg=$arg")
			# Track if user specified memory settings
			case "$arg" in
			-Xms*) HAS_XMS=1 ;;
			-Xmx*) HAS_XMX=1 ;;
			esac
		done
	fi
fi

# Apply default memory settings if not overridden by .vscode/settings.json
[ -z "${HAS_XMS:-}" ] && EXTRA_ARGS+=("--jvm-arg=$DEFAULT_XMS")
[ -z "${HAS_XMX:-}" ] && EXTRA_ARGS+=("--jvm-arg=$DEFAULT_XMX")

exec "$JDTLS_REAL" "${EXTRA_ARGS[@]}" "$@"
