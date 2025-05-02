#!/usr/bin/bash
export PATH=/opt/oracle/instantclient_23_7:$PATH
export ORACLE_HOME=/opt/oracle/instantclient_23_7

# In case of needing to manually linking Oracle
# https://askubuntu.com/questions/1134027/sql-plus-command-not-found
#sudo ln -s /opt/oracle/instantclient_23_7/sqlplus /usr/bin/
#sudo ln -s /opt/oracle/instantclient_23_7/sqlldr /usr/bin/sqlldr