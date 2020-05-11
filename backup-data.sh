#!/usr/bin/env bash

LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "already running"
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Configure backup

BACKUP_HOST='192.168.11.151'
BACKUP_USER='borg'
BACKUP_REPO=$(hostname)-etc

echo $BACKUP_REPO

# Make backup
borg create \
  --info --stats --progress --log-json \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc \
  2>>/var/log/borgbackup.log


# Prune backup
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-within 1m \
  --keep-monthly 3 

# Delete lockfile
rm -f ${LOCKFILE}