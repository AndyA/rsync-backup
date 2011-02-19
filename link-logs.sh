#!/bin/bash

DEST="/var/lib/backup/eric/mysql-relay-log"
SRC="/var/lib/mysql-eric-slave"

mkdir -p $DEST

for lf in $SRC/lupin-relay-bin.* ; do
  ln=$(basename $lf)
  df="$DEST/$ln"
  if [ ! -e $df ]; then
    echo "$lf -> $df"
    ln $lf $df
  fi
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

