#!/bin/bash
# Weekly Google Scholar citation update for howeyz.github.io
#
# Runs on the local machine (macOS) via the LaunchAgent
#   ~/Library/LaunchAgents/com.howeyz.scholar-citations.plist
# because Google blocks GitHub Actions runner IPs (HTTP 403).
#
# Logs: ~/Library/Logs/scholar-citations.log
set -uo pipefail

REPO="/Users/howeyzhang/Documents/howeyz.github.io"
SCHOLAR_ID="gYMOkGYAAAAJ"
PYTHON="/usr/bin/python3"
LOG="$HOME/Library/Logs/scholar-citations.log"

mkdir -p "$(dirname "$LOG")"

{
    echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') ====="

    cd "$REPO" || { echo "ERROR: repo not found at $REPO"; exit 1; }

    # 1. Crawl the total citation count from Google Scholar
    #    (run inside google_scholar_crawler so results/ lands next to the script)
    if ! (cd google_scholar_crawler && GOOGLE_SCHOLAR_ID="$SCHOLAR_ID" "$PYTHON" main.py); then
        echo "ERROR: crawl failed (Google may have blocked the request); keeping existing data"
        exit 1
    fi

    # 2. Publish the new count to the site data directory
    cp google_scholar_crawler/results/gs_data_shieldsio.json google-scholar-stats/gs_data_shieldsio.json

    if git diff --quiet -- google-scholar-stats/gs_data_shieldsio.json; then
        echo "citation count unchanged, nothing to push"
        exit 0
    fi

    cp google_scholar_crawler/results/gs_data.json google-scholar-stats/gs_data.json
    NEW_COUNT=$(sed -n 's/.*"message": *"\([0-9]*\)".*/\1/p' google-scholar-stats/gs_data_shieldsio.json)
    echo "citation count updated to $NEW_COUNT"

    # 3. Commit and push
    git add google-scholar-stats/gs_data.json google-scholar-stats/gs_data_shieldsio.json
    git -c user.name="HoweyZ" -c user.email="HoweyZ@users.noreply.github.com" \
        commit -m "Update citation count to $NEW_COUNT"

    if git push origin main; then
        echo "pushed to origin/main"
    else
        echo "ERROR: git push failed (check keychain credentials)"
        exit 1
    fi
} >> "$LOG" 2>&1
