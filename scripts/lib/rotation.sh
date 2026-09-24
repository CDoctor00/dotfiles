# =============================================================================
#  scripts/lib/rotation.sh — Shared log rotation
#
#  Shared by: install.sh, sync.sh, status.sh
#  Purpose:   Rotate old logs while respecting retention limits.
# =============================================================================

#  Intentionally does NOT set its own `set -e`/`set -o pipefail`:
#  the calling script controls that.

RETENTION_DAYS=30
RETENTION_MIN_KEEP=10

# Deletes logs older than RETENTION_DAYS in $LOG_DIR, but always keeps at
# least RETENTION_MIN_KEEP most recent files regardless of age.
# Requires the caller to have already defined: LOG_DIR, warn(), log()
rotate_logs() {
  local all_logs=() old_logs=() keep_recent=() to_delete=() f

  mapfile -t all_logs < <(command find "$LOG_DIR" -maxdepth 1 -name '*.log' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | cut -d' ' -f2-)

  [[ ${#all_logs[@]} -le $RETENTION_MIN_KEEP ]] && return 0

  mapfile -t keep_recent < <(printf '%s\n' "${all_logs[@]}" | head -n "$RETENTION_MIN_KEEP")
  mapfile -t old_logs < <(command find "$LOG_DIR" -maxdepth 1 -name '*.log' -mtime "+$RETENTION_DAYS" 2>/dev/null)

  for f in "${old_logs[@]}"; do
    if ! printf '%s\n' "${keep_recent[@]}" | command grep -qxF "$f"; then
      to_delete+=("$f")
    fi
  done

  [[ ${#to_delete[@]} -eq 0 ]] && return 0

  for f in "${to_delete[@]}"; do
    command rm -f "$f" 2>/dev/null || warn "Could not delete old log (permission denied?): $f"
  done
  log "Log rotation: removed ${#to_delete[@]} log(s) older than ${RETENTION_DAYS}d (kept ${RETENTION_MIN_KEEP} most recent)"
}