#!/bin/bash

function usage() {
cat << EOL
  usage: $0 IP
EOL
  exit 0
}

# arg check
[ $# -ne 1 ] && usage

# arg set
IP=$1

# parameter
JSTAT="/usr/local/java/bin/jstat /usr/bin/jstat"
APP="tomcat elasticsearch"
PID="/usr/local/tomcat /usr/share/elasticsearch"
USER=hoge

function getPid() {
  # check jstat pass
  jstat=`ssh $IP "for i in $JSTAT ;do [ -e \\$i ] && echo \\$i && break ;done"`

  # check app
  app=`ssh $IP "for i in $APP ;do ps -ef |grep -v grep |grep -wq \\$i && { echo \\$i ; break ; } ;done"`

  # map uid for vertx
  [ "$app" = "501" ] && app=$USER

  # check jvm pid
  jvm_pid=`ssh $IP "for i in $PID ;do ps -ef |grep -v grep |grep -q \\$i && ps -ef |grep -v grep |grep \\$i |awk '{print \\$2}' ;done"`
}

#
# main
#

getPid
##echo "Jstat:$jstat app:$app jvm_pid:$jvm_pid"
[ -z $jvm_pid ] && exit

# get jstat

# check java8
ssh $IP "/usr/bin/sudo -u $app $jstat -gc $jvm_pid 1000 1" |grep -q 'CCSC'
RET=$?

if [ $RET -eq 0 ]; then
  ssh $IP "/usr/bin/sudo -u $app $jstat -gc $jvm_pid 1000 1" |\
  grep -v '[A-Z]' |\
  awk '{print "01_Survivor0c:"int($1*1024),"02_Survivor1c:"int($2*1024),"03_Survivor0u:"int($3*1024),"04_Survivor1u:"int($4*1024),"05_Eden_c:"int($5*1024),"06_Eden_u:"int($6*1024),"07_Old_c:"int($7*1024),"08_Old_u:"int($8*1024),"09_Perm_c:"int($9*1024),"10_Perm_u:"int($10*1024),"11_ygc:"int($13),"12_ygct:"int($14),"13_fgc:"int($15),"14_fgct:"int($16),"15_gct:"int($17)}' |\
  tr -d '\n'

else
  ssh $IP "/usr/bin/sudo -u $app $jstat -gc $jvm_pid 1000 1" |\
  grep -v '[A-Z]' |\
  awk '{print "01_Survivor0c:"int($1*1024),"02_Survivor1c:"int($2*1024),"03_Survivor0u:"int($3*1024),"04_Survivor1u:"int($4*1024),"05_Eden_c:"int($5*1024),"06_Eden_u:"int($6*1024),"07_Old_c:"int($7*1024),"08_Old_u:"int($8*1024),"09_Perm_c:"int($9*1024),"10_Perm_u:"int($10*1024),"11_ygc:"int($11),"12_ygct:"int($12),"13_fgc:"int($13),"14_fgct:"int($14),"15_gct:"int($15)}' |\
  tr -d '\n'

fi
