#!/bin/bash

# Copyright (c) 2009-2014 Vladimir Fedorkov (http://astellar.com/)
# All rights reserved.                                                         
#                                                                              
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.


HOST=$1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PASS=$4
MYSQL_PORT=$5

TODAY=`date +%y%m%d`

echo "MySQL Health check report for host $HOST"
uptime

echo -e "\n=== disks ==="
df -h

echo -e "\n=== memory ==="
free -m

echo -e "\n=== network ==="
netstat -i

### Run MySQL counters report
### 
echo -e "\n=== MySQL counters ==="
php -q ./mysql_counters/counters_report.php $HOST $MYSQL_HOST $MYSQL_USER "$MYSQL_PASS" $MYSQL_PORT

echo -e "\n=== Top tables ==="
mysql -h $MYSQL_HOST -u $MYSQL_USER --password="$MYSQL_PASS" --port=$MYSQL_PORT -e "SELECT engine, concat(round(table_rows/1000000,2),'M') rows, concat(round((data_length+index_length)/(1024*1024*1024),2),'G') size, concat(table_schema,'.',table_name) as 'DB.table' FROM information_schema.TABLES WHERE table_schema NOT IN('PERFORMANCE_SCHEMA','information_schema') ORDER BY data_length+index_length DESC LIMIT 10"

### Run slow query digest
./mysql_query_review/query_digest_daily.sh $TODAY $MYSQL_HOST $MYSQL_USER "$MYSQL_PASS" $MYSQL_PORT

echo -e "\n\n=== MySQL error log ==="
ERROR_LOG=`mysql -h $MYSQL_HOST -u $MYSQL_USER --password="$MYSQL_PASS" --port=$MYSQL_PORT -BNe "SELECT @@GLOBAL.log_error"`
if [ -z "$ERROR_LOG" ]; then
    echo "can't get error log path, please verify MySQL credentials"
    exit 4
fi
if [ ! -r $ERROR_LOG ]; then
    echo "can't read error log: $ERROR_LOG"
    exit 5
fi

cat $ERROR_LOG | grep $TODAY

echo -e "\n========================="
echo -e "\nReport generated using http://astellar.com/mysql-health-check/"