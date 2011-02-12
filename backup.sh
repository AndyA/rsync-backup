#!/bin/bash

RHOST="eric.hexten.net"
RUSER="root"
RID="/root/.ssh/id_dsa_backup_eric"
RROOT="/"
RULES="rules"
PIDFILE="/var/run/backup-$RHOST.pid"
PREFIX="archive"

SSH=/usr/bin/ssh
RSYNC=/usr/bin/rsync

cd "$(dirname "$0")"

if [ -e $PIDFILE ]; then
  PID=$(cat $PIDFILE)
  echo "$PIDFILE exists: pid is $PID"
  if [ kill -0 $PID 2>/dev/null ]; then
    echo "Process $PID is still running so I'm stopping"
    exit
  else
    echo "Process $PID doesn't seem to be running, deleting $PIDFILE"
    rm -f $PIDFILE
  fi
fi

function __cleanup__() {
  rm -f $PIDFILE
}

function after_rsync() {
  local RC=$1
  echo "rsync exit code: $RC"
  if [ $RC -ne 0 -a $RC -ne 23 -a $RC -ne 24 ]; then
    __cleanup__
    exit
  fi
}

trap __cleanup__ SIGINT

echo $$ > $PIDFILE

CURRENT="$PREFIX.current"
WORK="$PREFIX.work"
STAMP=$(date +%Y.%m.%d-%H.%M.%S)
BYDATE=$(date +%Y/%m/%d/%H.%M.%S)

RSYNC_EXTRA=""

if [ -e "$CURRENT" ]; then
  LATEST=$(readlink -f "$CURRENT")
  RSYNC_EXTRA="$RSYNC_EXTRA --link-dest $LATEST"
fi

if [ -d "$WORK" ]; then
  RSYNC_EXTRA="$RSYNC_EXTRA --delete"
fi

RSYNC_SSH="$SSH -i $RID -l $RUSER"

set -x

mkdir -p "$WORK"

[ -e pre-backup-hook.sh ] && . pre-backup-hook.sh

$RSYNC -avz -F --include-from=$RULES --numeric-ids \
  $RSYNC_EXTRA -e "$RSYNC_SSH" \
  $RHOST:$RROOT $WORK

after_rsync $?

[ -e post-backup-hook.sh ] && . post-backup-hook.sh

NEW="$PREFIX.$STAMP"
mv "$WORK" "$NEW"
ln -s "./$NEW" "$CURRENT.tmp"
mv -T "$CURRENT.tmp" "$CURRENT"

mkdir -p $(dirname $BYDATE)
ln -s "$PWD/$NEW" "$BYDATE"

__cleanup__

# vim:ts=2:sw=2:sts=2:et:ft=sh
