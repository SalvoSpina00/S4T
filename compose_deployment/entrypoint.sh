#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Inizializzazione del database..."
    mysql_install_db --user=mysql --ldata=/var/lib/mysql
fi

# Avvia MySQL in background
exec gosu mysql mysqld 
	--bind-address=0.0.0.0 
	--max_connections=4096 \
        --collation-server=utf8_general_ci 
	--character-set-server=utf8 \
        --innodb-buffer-pool-size=1G 
	--innodb-flush-log-at-trx-commit=1 \
        --innodb-file-per-table=1 &
PID_MYSQL=$!

# Attendi che MySQL risponda al ping
echo "Attesa avvio MySQL..."
until mysqladmin ping -h "localhost" --silent; do
    sleep 2
done

echo "MySQL è pronto. Verifica esistenza database..."

# Verifica se il database esiste già
if mysql -uroot -punime -e "USE unime;" 2>/dev/null; then
    echo "Database già esistente, nessuna operazione necessaria."
else
    echo "Creazione del database e dell'utente..."
    mysql -uroot -punime <<EOF
CREATE DATABASE IF NOT EXISTS unime;
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 's4t';
GRANT ALL PRIVILEGES ON unime.* TO 'admin'@'%';
FLUSH PRIVILEGES;
EOF
fi

# Porta in primo piano il processo MySQL in background
wait $PID_MYSQL
