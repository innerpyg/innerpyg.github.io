#!/bin/bash
# Blog Auto Post - LaunchAgent Script
# Converts today's HTML reports to Jekyll posts and pushes to GitHub.
#
# Sources:
#   1. MorningBrief HTML: ~/Desktop/Study/Claude/Projects/MorningBrief/html/
#   2. trade-forge HTML:  ~/Desktop/Study/Claude/Projects/trade-forge/reports/html/
#
# Destination: ~/innerpyg.github.io/_posts/
#
# Usage:
#   blog-post-today.sh [am|pm]
#   - am (default): processes MorningBrief + trade-forge AM
#   - pm: processes trade-forge PM only

set -euo pipefail

# --- Config ---
BLOG_DIR="$HOME/Desktop/Study/Github/innerpyg.github.io"
POSTS_DIR="${BLOG_DIR}/_posts"
SCRIPTS_DIR="${BLOG_DIR}/scripts"
CONVERTER="${SCRIPTS_DIR}/convert_html_post.py"

MB_HTML_DIR="$HOME/Desktop/Study/Claude/Projects/MorningBrief/html"
TF_HTML_DIR="$HOME/Desktop/Study/Claude/Projects/trade-forge/reports/html"

LOG_DIR="${BLOG_DIR}/logs"
LOG_FILE="${LOG_DIR}/blog-post.log"

SESSION="${1:-am}"
TODAY=$(date +%Y-%m-%d)
POSTED=0

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Blog Auto Post START (session: ${SESSION}, date: ${TODAY}) ==="

# --- Front matter templates ---
MB_FRONT_MATTER="---
title: Morning Market Brief
author: \"Written by Claude\"
date: \"${TODAY}\"
output:
  html_document:
    toc: yes
    toc_depth: 2
    keep_md: yes
  pdf_document:
    toc: yes
    toc_depth: '2'
layout: post
categories: Quant_Research
tags: [Market, Daily]
series: stock
---"

TF_FRONT_MATTER="---
title: Trade Forge Report
author: \"Written by Claude\"
date: \"${TODAY}\"
output:
  html_document:
    toc: yes
    toc_depth: 2
    keep_md: yes
  pdf_document:
    toc: yes
    toc_depth: '2'
layout: post
categories: Quant_Research
tags: [Market, Daily, Trading]
series: stock
---"

# --- Process function ---
process_file() {
  local src="$1"
  local dest="$2"
  local front_matter="$3"
  local scope="$4"
  local label="$5"

  if [ ! -f "$src" ]; then
    log "[SKIP] ${label}: source not found - ${src}"
    return
  fi

  if [ -f "$dest" ]; then
    log "[SKIP] ${label}: already exists - ${dest}"
    return
  fi

  python3 "$CONVERTER" "$src" "$dest" "$front_matter" "$scope"
  if [ $? -eq 0 ]; then
    log "[OK] ${label}: ${src} -> ${dest}"
    POSTED=$((POSTED + 1))
  else
    log "[ERROR] ${label}: conversion failed"
  fi
}

# --- AM Session: MorningBrief + trade-forge AM ---
if [ "$SESSION" = "am" ]; then
  # MorningBrief
  process_file \
    "${MB_HTML_DIR}/${TODAY}-morning-brief.html" \
    "${POSTS_DIR}/${TODAY}-morning-brief.html" \
    "$MB_FRONT_MATTER" \
    "morning-brief" \
    "MorningBrief"

  # trade-forge AM
  process_file \
    "${TF_HTML_DIR}/daily_${TODAY}-am.html" \
    "${POSTS_DIR}/${TODAY}-trade-forge-am.html" \
    "$TF_FRONT_MATTER" \
    "trade-forge" \
    "trade-forge AM"
fi

# --- PM Session: trade-forge PM only ---
if [ "$SESSION" = "pm" ]; then
  process_file \
    "${TF_HTML_DIR}/daily_${TODAY}-pm.html" \
    "${POSTS_DIR}/${TODAY}-trade-forge-pm.html" \
    "$TF_FRONT_MATTER" \
    "trade-forge" \
    "trade-forge PM"
fi

# --- Git push ---
if [ $POSTED -gt 0 ]; then
  log "Pushing ${POSTED} new post(s) to GitHub..."
  cd "$BLOG_DIR"
  git add _posts/
  git commit -m "Add daily posts for ${TODAY} (${SESSION})"
  git push
  if [ $? -eq 0 ]; then
    log "[OK] Git push successful"
  else
    log "[ERROR] Git push failed"
  fi
else
  log "No new posts to push."
fi

log "=== Blog Auto Post END ==="
