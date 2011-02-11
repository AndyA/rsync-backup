#!/bin/bash

RHOST="eric.hexten.net"
RUSER="root"
RID="/root/.ssh/id_dsa_backup_eric"
RROOT="/"
RULES="rules"
PID="/var/run/backup-$RHOST.pid"

if [ -e $PID ]; then
fi

CURRENT="archive.current"
WORK="archive.work"
STAMP=$(date +%Y%m%d-%H%M%S)

RSYNC_EXTRA=""

if [ -e "$CURRENT" ]; then
  # Assume symlink is absolute so we give rsync an absolute path
  # to link to
  LATEST=$(readlink -f "$CURRENT")
  RSYNC_EXTRA="$RSYNC_EXTRA --link-dest $LATEST"
fi

RSYNC_SSH="ssh -i $RID -l $RUSER"

set -x
mkdir -p "$WORK"
rsync -avz -F --include-from=$RULES \
  $RSYNC_EXTRA -e "$RSYNC_SSH" \
  $RHOST:$RROOT $WORK

echo "rsync: $?"

NEW="archive.$STAMP"
mv "$WORK" "$NEW"
ln -s "$PWD/$NEW" "$CURRENT.tmp"
mv "$CURRENT.tmp" "$CURRENT"


# vim:ts=2:sw=2:sts=2:et:ft=sh
