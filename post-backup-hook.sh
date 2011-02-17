#!/bin/bash

MS_PATH="var/lib/mysql"
MS_PATH_SLAVE="var/lib/mysql-eric-slave"

RS_MS_OPT=""
if [ -e "$CURRENT" ]; then
  LATEST=$(readlink -f "$CURRENT")
  RS_MS_OPT="$RS_MS_OPT --link-dest $LATEST/$MS_PATH"
fi

/usr/sbin/service mysql-eric-slave stop
$RSYNC -av $RS_MS_OPT /$MS_PATH_SLAVE/ $WORK/$MS_PATH
RC=$?
/usr/sbin/service mysql-eric-slave start
after_rsync $RC

# vim:ts=2:sw=2:sts=2:et:ft=sh

