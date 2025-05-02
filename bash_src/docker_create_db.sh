#!/usr/bin/bash
sudo chmod -R 777 /opt/oracle

sudo docker run --name oracle \
-p 1521:1521 \
-e ORACLE_PWD=WikiTest123 \
-v /opt/oracle/oradata:/opt/oracle/oradata \
container-registry.oracle.com/database/free