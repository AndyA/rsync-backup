#!/bin/bash

RHOST="eric.hexten.net"
RUSER="root"
RID="/root/.ssh/id_dsa_backup_eric"
RROOT="/"
RULES="rules"
PIDFILE="/var/run/backup-$RHOST.pid"
PREFIX="archive"
TOUCH="/var/run/backup-$RHOST.done"

SSH=/usr/bin/ssh
RSYNC=/usr/bin/rsync

function rotate_archive() {
  local PREFIX=$1
  local THIS=$2
  local NEXT=$3
  local LIMIT=$4
  if [ -e "$PREFIX.$NEXT" ]; then
    if [ $NEXT -lt $LIMIT ]; then
      rotate_archive "$PREFIX" "$NEXT" $(expr $NEXT + 1) $LIMIT
    else
      echo "Removing $PREFIX.$NEXT"
      rm -f "$PREFIX.$NEXT"
    fi
  fi
  echo "Moving $PREFIX.$THIS to $PREFIX.$NEXT"
  mv "$PREFIX.$THIS" "$PREFIX.$NEXT"
}

function after_rsync() {
  local RC=$1
  echo "rsync exit code: $RC"
  if [ $RC -ne 0 -a $RC -ne 23 -a $RC -ne 24 ]; then
    __cleanup__
    exit
  fi
}

function __cleanup__() {
  rm -f $PIDFILE
}

trap __cleanup__ SIGINT

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
echo $$ > $PIDFILE

CURRENT="$PREFIX.current"
WORK="$PREFIX.work"
BYDATE="$PREFIX/$(date +%Y/%m/%d/%H.%M.%S)"

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

mkdir -p $(dirname $BYDATE)
mkdir -p "$WORK"

[ -e pre-backup-hook.sh ] && . pre-backup-hook.sh

$RSYNC -avz -F --include-from=$RULES --numeric-ids \
  $RSYNC_EXTRA -e "$RSYNC_SSH" \
  $RHOST:$RROOT $WORK

after_rsync $?

[ -e post-backup-hook.sh ] && . post-backup-hook.sh

mv "$WORK" "$BYDATE"
rotate_archive "$PREFIX" "current" 1 10
ln -s "$BYDATE" "$CURRENT"

touch $TOUCH

__cleanup__

# vim:ts=2:sw=2:sts=2:et:ft=sh
