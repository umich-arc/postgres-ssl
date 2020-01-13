# Postgres-SSL

Docker container automatically generates SSL certificates and requires client certificates to connect.

The auto-generated client certs are accessible within the container and also get piped to STDOUT during initialization.

Once started:

`psql "port=5432 host=192.168.0.10 user=postgres sslcert=./postgresql.crt sslkey=./postgresql.key sslrootcert=./root.crt sslmode=verify-ca"`

**Note:** The user in the connection string above must match the `$POSTGRES_USER` defined at start (defaults to `postgres`)

#### Why:

We are provisioning many short lived data services that require secure-by-default settings such as requiring client certificates to establish a connection.

#### To Do:

- Configure SSL options via environment variables
- Allow certs to reside in a different directory (and configure via env)
- Support multiple versions of Postgres (Currently pinned to 9.6) - Now defaults to 9.6 but can be built to any version by using the DB_VERSION arg at build time
- TravisCI integration / Auto push to Hub
