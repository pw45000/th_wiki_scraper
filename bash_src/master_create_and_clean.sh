#!/usr/bin/bash
echo "@sql_src/create_table.sql;"| sqlplus c##dialogue/dialpass@localhost:1521/FREE
sqlldr userid=c##dialogue/dialpass@localhost:1521/FREE control='transfer_csv.ctl' ERRORS=0 SKIP=1
sqlplus c##dialogue/dialpass@localhost:1521/FREE << EOF
@sql_src/clean_table.sql;
@sql_src/fill_in_gaps.sql;
@sql_src/export_db_to_csv.sql;
EOF