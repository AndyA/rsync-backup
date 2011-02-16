#!/bin/bash

/usr/sbin/service mysql-eric-slave stop
$RSYNC -av $RSYNC_EXTRA /var/lib/mysql-eric-slave/* $WORK/var/lib/mysql
RC=$?
/usr/sbin/service mysql-eric-slave start
after_rsync $RC

# vim:ts=2:sw=2:sts=2:et:ft=sh

