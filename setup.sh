#!/usr/bin/env bash
# Statusline for Claude Code that also caches live rate-limit data to disk.
# Claude Code pipes session JSON (incl. rate_limits) on stdin during interactive
# sessions; the autobuild cron job reads the cache to decide whether to run.
# Cache: ~/.claude/usage-cache.json

set -u
input="$(cat)"

CACHE="$HOME/.claude/usage-cache.json"

rate_limits="$(printf '%s' "$input" | jq -c '.rate_limits // empty' 2>/dev/null)"
if [ -n "$rate_limits" ] && [ "$rate_limits" != "null" ]; then
  printf '%s' "$rate_limits" | jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{cached_at: $ts, rate_limits: .}' > "${CACHE}.tmp" 2>/dev/null \
    && mv "${CACHE}.tmp" "$CACHE"
fi

# --- visible statusline ---
model="$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)"
dir="$(printf '%s' "$input" | jq -r '.workspace.current_dir // ""' 2>/dev/null)"
five="$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)"
week="$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)"

line="$model | ${dir##*/}"
[ -n "$five" ] && line="$line | 5h: $(printf '%.0f' "$five")%"
[ -n "$week" ] && line="$line | wk: $(printf '%.0f' "$week")%"
printf '%s' "$line"
