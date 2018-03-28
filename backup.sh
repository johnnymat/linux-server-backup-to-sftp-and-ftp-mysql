#!/bin/sh

PRESERVATION=14 #how many days store the backups
WHAT_TO_BACKUP="/home /var/www/html /srv/mytext.txt" #local directories to be included in backup If you want more directory, list them sepatare with one empty space
BACKUP_FILENAME="mybackup" #backup file filename
BACKUP_DB_FILENAME="mybackup" #db backup file filename
REMOTE_DIR="/" #directory on the remote server to backup
ONE_FILE=1 #0/1 disable/enable to put the sql file and the directories in one backup file

DB_USER="root" #db username for backup
DB_PASSWORD="123456" #db user password for backup
DB_HOST="localhost" #db server ip/hostname
DB_NAME="db1 db2 db3 db4" #The db name for backup. If you want more db, list them sepatare with one empty space
ALL_DB_BACKUP=0 #0/1 disable/enable db backup for all databases

FTP_TYPE=1 #Transfer type, 0=FTP, 1=SFTP

FTP_USER="sftpusername" #ftp/sftp server username
FTP_PASSWORD="123456" #ftp/sftp server user password
FTP_HOST="mybackupserver.com" #ftp/sftp server hostname/ip
FTP_PORT="115" #sftp server port, only when you use sftp server

BACKUP_DIR=/backup #local server directory to keep backups-> backups temp directory

#------DO NOT EDIT --------#

TODAY=`date +%d-%m-%Y`
DELETEDATE=`date --date="-$PRESERVATION day" +%d-%m-%Y`

if [ $ONE_FILE -eq 0 ];then
    if [ $ALL_DB_BACKUP -eq 0 ];then
    mysqldump --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST --databases $DB_NAME | gzip --best > $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql.gz
    elif [ $ALL_DB_BACKUP -eq 1 ]; then
    mysqldump --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST --all-databases | gzip --best > $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql.gz
    fi
elif [ $ONE_FILE -eq 1 ];then
    if [ $ALL_DB_BACKUP -eq 0 ];then
    mysqldump --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST --databases $DB_NAME > $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql
    elif [ $ALL_DB_BACKUP -eq 1 ]; then
    mysqldump --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST --all-databases > $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql
    fi
fi

if [ $ONE_FILE -eq 0 ];then
    tar -cvzf $BACKUP_DIR/${BACKUP_FILENAME}_$TODAY.tar.gz $WHAT_TO_BACKUP
elif [ $ONE_FILE -eq 1 ];then
    tar -cvf $BACKUP_DIR/${BACKUP_FILENAME}_$TODAY.tar $WHAT_TO_BACKUP
    cd $BACKUP_DIR
    tar --append --file=${BACKUP_FILENAME}_$TODAY.tar ${BACKUP_DB_FILENAME}_$TODAY.sql
    gzip ${BACKUP_FILENAME}_$TODAY.tar
fi

if [ $FTP_TYPE -eq 0 ];then
    cd $BACKUP_DIR
    ftp -n -v $FTP_HOST <<EOF
    user $FTP_USER $FTP_PASSWORD
    binary
    cd $REMOTE_DIR
    put ${BACKUP_FILENAME}_$TODAY.tar.gz
    put ${BACKUP_DB_FILENAME}_$TODAY.sql.gz
    delete ${BACKUP_FILENAME}_$DELETEDATE.tar.gz
    delete ${BACKUP_DB_FILENAME}_$DELETEDATE.sql.gz
    quit
EOF
elif [ $FTP_TYPE -eq 1 ];then
    sshpass -p $FTP_PASSWORD sftp -oPort=$FTP_PORT $FTP_USER@$FTP_HOST:$REMOTE_DIR << EOF
    put $BACKUP_DIR/${BACKUP_FILENAME}_$TODAY.tar.gz
    put $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql.gz
    rm $REMOTE_DIR/${BACKUP_FILENAME}_$DELETEDATE.tar.gz
    rm $REMOTE_DIR/${BACKUP_DB_FILENAME}_$DELETEDATE.sql.gz
    quit
EOF
fi

if [ $ONE_FILE -eq 0 ];then
rm $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql.gz
elif [ $ONE_FILE -eq 1 ];then
rm $BACKUP_DIR/${BACKUP_DB_FILENAME}_$TODAY.sql
fi
rm $BACKUP_DIR/${BACKUP_FILENAME}_$TODAY.tar.gz