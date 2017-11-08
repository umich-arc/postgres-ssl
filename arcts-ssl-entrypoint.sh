#!/usr/bin/env bash
set -e

echo "Configuring Postgres for SSL!";

if [ -z "$POSTGRES_USER" ]; then
  export POSTGRES_USER="postgres";
fi

if [ -z "$POSTGRES_EMAIL" ]; then
  export POSTGRES_EMAIL="user@test.com";
fi


if [ ! -s /tmp/docker-entrypoint.sh ]; then
  echo "Their entry script is kinda rough for us. Quick fix."
  head -n -1 /usr/local/bin/docker-entrypoint.sh > /tmp/docker-entrypoint.sh
  cp -rf /tmp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
fi

cat /usr/local/bin/docker-entrypoint.sh | grep gosu

# Don't reinvent the wheel
chmod +x /usr/local/bin/docker-entrypoint.sh && \
chmod +x /docker-entrypoint.sh && \

./usr/local/bin/docker-entrypoint.sh "postgres"

echo "Postgres initialized. Time to SSL.";

if [ ! -s "$PGDATA/postgresql.crt" ]; then
  # Update HBA to require SSL and Client Cert auth
  head -n -1 /var/lib/postgresql/data/pg_hba.conf > /tmp/pg_hba.conf
  echo "hostssl all all all cert clientcert=1" >> /tmp/pg_hba.conf
  mv /tmp/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf

  # Create SSL certs
  cd /var/lib/postgresql/data/
  # CA
  openssl req -new -x509 -nodes -out root.crt -keyout root.key -newkey rsa:4096 -sha512 -subj /CN=TheRootCA
  echo "CA Certificate";
  cat root.crt
  # Server
  openssl req -new -out server.req -keyout server.key -nodes -newkey rsa:4096 -subj "/CN=$( hostname )/emailAddress=$POSTGRES_EMAIL"
  openssl x509 -req -in server.req -CAkey root.key -CA root.crt -set_serial $RANDOM -sha512 -out server.crt

  # Client
  echo "Client Key";
  openssl req -new -out postgresql.req -keyout postgresql.key -nodes -newkey rsa:4096 -subj "/CN=$POSTGRES_USER"
  cat postgresql.key

  openssl x509 -req -in postgresql.req -CAkey root.key -CA root.crt -set_serial $RANDOM -sha512 -out postgresql.crt
  echo "Client Certificate";
  cat postgresql.crt

  chown postgres.postgres server.key root.key postgresql.key
  chmod 600 server.key root.key postgresql.key

  # Update postgresql.conf to support SSL

fi

sed -i 's/#ssl/ssl/g' /var/lib/postgresql/data/postgresql.conf
sed -i 's/ssl \= off/ssl \= on/g' /var/lib/postgresql/data/postgresql.conf
sed -i "s/ssl_ca_file = ''/ssl_ca_file = 'root.crt'/g" /var/lib/postgresql/data/postgresql.conf



if [ "$1" = 'postgres' ] && [ "$(id -u)" = '0' ]; then
  echo "Time to run Postgres. Switching from root to postgres";
  exec gosu postgres "$@"
elif [ "$1" = '' ] && [ "$(id -u)" = '0' ]; then
  echo "Time to run (we assume) Postgres. Switching from root to postgres";
  exec gosu postgres postgres
else
  echo "Oh snap you're going rogue.";
  echo "You're calling $1";
  echo "Your UID is $(id -u)";
  exec "$@"
fi
