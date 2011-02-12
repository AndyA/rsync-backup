#!/bin/bash

/usr/sbin/service mysql-eric-slave stop
$RSYNC -av /var/lib/mysql-eric-slave/* $WORK/var/lib/mysql
/usr/sbin/service mysql-eric-slave start

# vim:ts=2:sw=2:sts=2:et:ft=sh

