#!/usr/bin/bash
# All credit goes to https://csiandal.medium.com/install-oracle-instant-client-on-ubuntu-4ffc8fdfda08
# the said script above was modified to use the latest sqlplus package instead as well as some exports to ensure the
# installation is properly installed.
cd /opt/
sudo mkdir /opt/oracle
cd /opt/oracle

sudo wget https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sqlplus-linux.x64-23.7.0.25.01.zip
sudo unzip instantclient-sqlplus-linux.x64-23.7.0.25.01.zip

sudo wget https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basic-linux.x64-23.7.0.25.01.zip
sudo unzip instantclient-basic-linux.x64-23.7.0.25.01.zip

sudo wget https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-tools-linux.x64-23.7.0.25.01.zip
sudo unzip instantclient-tools-linux.x64-23.7.0.25.01.zip

sudo apt update
sudo apt install libaio1

sudo sh -c "echo /opt/oracle/instantclient_23_7 > /etc/ld.so.conf.d/oracle-instantclient.conf"
export PATH=/opt/oracle/instantclient_23_7:$PATH
export ORACLE_HOME=/opt/oracle/instantclient_23_7
export ORACLE_SID=oracle
sudo ldconfig


# In case of needing to manually linking Oracle
# https://askubuntu.com/questions/1134027/sql-plus-command-not-found
#sudo ln -s /opt/oracle/instantclient_23_7/sqlplus /usr/bin/
#sudo ln -s /opt/oracle/instantclient_23_7/sqlldr /usr/bin/sqlldr
