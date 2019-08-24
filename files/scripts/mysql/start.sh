#!/bin/bash

cp /my.cnf /etc/mysql/my.cnf

## Binary log options
if [ "${RECEIVER_ENABLE_BIN_LOG}" == "1" ]; then
	sed -i '/^#log_bin.*/s/^#//' /etc/mysql/my.cnf
fi
sed -i -e "s/logBinIndex/${RECEIVER_BIN_LOG_INDEX}/g" /etc/mysql/my.cnf
sed -i -e "s/logBinMaxSize/${RECEIVER_BIN_LOG_MAX_SIZE}/g" /etc/mysql/my.cnf
sed -i -e "s/binLogFormat/${RECEIVER_BIN_LOG_FORMAT}/g" /etc/mysql/my.cnf
sed -i -e "s/logBinDays/${RECEIVER_BIN_LOG_EXPIRE_DAYS}/g" /etc/mysql/my.cnf

if [ ! -f /var/lib/mysql/ibdata1 ]; then
    mysqld --initialize-insecure
fi
chown -R  mysql:mysql /var/lib/mysql

mysqld_safe --skip-syslog --skip-grant-tables &
for i in $(seq 1 60); do
     sleep 1
     mysql -e "" >/dev/null 2>&1
     retval=$?
     if [ $retval -eq 0 ]; then
             break
     fi
done


mysql -h127.0.0.1 -e  "use mysql;update user set authentication_string=PASSWORD('') where User='root';update user set plugin='mysql_native_password' where User='root';flush privileges;"

MYSQL_DB_NAME=$(grep -oP '(?<=db=)[^=]*' /var/run/secrets/mysql_credentials)
MYSQL_DB_USER=$(grep -oP '(?<=user=)[^=]*' /var/run/secrets/mysql_credentials)
MYSQL_DB_PASSWORD=$(grep -oP '(?<=password=)[^=]*' /var/run/secrets/mysql_credentials)

RESULT=$(mysqlshow | grep -v Wildcard | grep -o ${MYSQL_DB_NAME})
if  [ "$RESULT" != "${MYSQL_DB_NAME}" ]; then
	mysql -h127.0.0.1 -e "Create database if not exists ${MYSQL_DB_NAME}; grant all on ${MYSQL_DB_NAME}.* to ${MYSQL_DB_USER} identified by '${MYSQL_DB_PASSWORD}';"
fi

for i in $(seq 1 60); do
     sleep 1
     if [[ $(ps -ef | grep -v grep | grep mysql | wc -l) -eq 0 ]];then
             break
     fi
done


echo "#################################################---- Now Service starting ------########################################################"
/usr/bin/mysqld_safe  --ledir=/usr/sbin --skip-syslog && tail -f /var/log/mysql/mysql.log & tail -f /var/log/mysql/error.log
