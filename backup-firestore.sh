#!/bin/bash
# Backup all Firestore collections to timestamped JSON file.
# Usage: ./backup-firestore.sh [collection1 collection2 ...]
# Default collections: results, lineups, loadouts, paddlers

set -e

PROJECT_ID="auschamps26"
COLLECTIONS=("$@")
if [ ${#COLLECTIONS[@]} -eq 0 ]; then
  COLLECTIONS=("results" "lineups" "loadouts" "paddlers")
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"
OUT="$BACKUP_DIR/firestore_${TIMESTAMP}.json"

echo "Backing up project: $PROJECT_ID"
echo "Collections: ${COLLECTIONS[*]}"
echo "Output: $OUT"
echo ""

echo "{" > "$OUT"
FIRST=1
for COL in "${COLLECTIONS[@]}"; do
  if [ $FIRST -eq 0 ]; then echo "," >> "$OUT"; fi
  FIRST=0
  echo "  \"$COL\": " >> "$OUT"
  curl -s "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COL}?pageSize=500" >> "$OUT"
  COUNT=$(curl -s "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COL}?pageSize=500" | python3 -c "import json,sys;print(len(json.load(sys.stdin).get('documents',[])))" 2>/dev/null || echo "?")
  echo "  $COL: $COUNT documents backed up" >&2
done
echo "}" >> "$OUT"

echo ""
echo "Backup complete: $OUT"
echo "Size: $(du -h "$OUT" | cut -f1)"
