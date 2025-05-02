#!/usr/bin/bash
echo "@sql_src/create_db_user.sql;"| sqlplus sys/WikiTest123@localhost:1521/FREE AS SYSDBA
