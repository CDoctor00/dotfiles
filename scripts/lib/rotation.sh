# =============================================================================
#  scripts/lib/logging.sh — Shared logging helpers
#
#  Sourced by install.sh, sync.sh and status.sh, after scripts/lib/colors.sh
#  (these functions use the color variables it defines) and before
#  scripts/lib/rotation.sh (which calls warn()/log()).
#
#  Requires the following to already be defined by the caller before
#  sourcing:
#    - LOG_DIR    directory this script's log file lives in
#    - LOG_FILE   full path to this script's own log file
#
#  Hook:
#    status.sh needs warn()/error() to also flag that an issue was found
#    (it sets ISSUES_FOUND=1, used for its exit code), while install.sh and
#    sync.sh do not need this. Rather than duplicating warn()/error(), they
#    call _on_issue(), a no-op by default. status.sh redefines _on_issue()
#    right after sourcing this file to set ISSUES_FOUND=1 — a plain function
#    redefinition, since bash functions are resolved at call time.
# =============================================================================

_on_issue() { :; }

ok()    { local msg="[ OK ]  $*"; echo -e "${GREEN}${msg}${NC}";   echo "$msg" >> "$LOG_FILE"; }
warn()  { local msg="[WARN]  $*"; echo -e "${YELLOW}${msg}${NC}";  echo "$msg" >> "$LOG_FILE"; _on_issue; }
error() { local msg="[ERR ]  $*"; echo -e "${RED}${msg}${NC}" >&2; echo "$msg" >> "$LOG_FILE"; _on_issue; }
log()   { local msg="[INFO]  $*"; echo -e "${BLUE}${msg}${NC}";    echo "$msg" >> "$LOG_FILE"; }
step()  { local msg="▶ $*";       echo -e "\n${BOLD}${CYAN}${msg}${NC}"; echo -e "\n${msg}" >> "$LOG_FILE"; }

# init_log [extra_line ...]
# Writes the standard log header (script name + timestamp), then any extra
# lines the caller wants recorded right after it (e.g. install.sh's
# DRY_RUN=... flag), then a blank line separator — same layout each script
# produced before this was shared.
init_log() {
  mkdir -p "$LOG_DIR"
  echo "=== $(basename "$0") — $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOG_FILE"
  local extra
  for extra in "$@"; do
    echo "$extra" >> "$LOG_FILE"
  done
  echo "" >> "$LOG_FILE"
}