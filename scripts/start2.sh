#!/bin/sh

if [ ! -d "/run/mysqld" ]; then
  mkdir -p /run/mysqld
fi

if [ -d /app/mysql ]; then
        echo '[i] MySQL directory already present, skipping creation'
else
        echo "[i] MySQL data directory not found, creating initial DBs"

        #chown -R mysql:mysql /var/lib/mysql
        chown -R root:root /var/lib/mysql

        # Initializing database, mysql_install_db --user=mysql > /dev/null
        #mysql_install_db --user=mysql --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null
        mysql_install_db --user=root --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null
        #echo '[i] Database initialized'

        # create temp file
        tfile=`mktemp`
        if [ ! -f "$tfile" ]; then
            return 1
        fi

        # save sql
        echo "[i] Create temp file: $tfile"
        cat << EOF > $tfile

cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
EOF

  if [ "$MYSQL_DATABASE" != "" ]; then
    echo "[i] Creating database: $MYSQL_DATABASE"
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

    if [ "$MYSQL_USER" != "" ]; then
      echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
      echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
    fi
  fi

  echo 'FLUSH PRIVILEGES;' >> $tfile

  # run sql in tempfile
  /usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tfile
  rm -f $tfile
fi
