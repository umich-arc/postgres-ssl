# Postgres-SSL

Docker container automatically generates SSL certificates and requires client certificates to connect.

The auto-generated client certs are accessible within the container and also get piped to STDOUT during initialization.

#### Why:

We are provisioning many short lived data services that require secure-by-default settings such as requiring client certificates to establish a connection. 

#### To Do:

- Configure SSL options via environment variables
- Allow certs to reside in a different directory (and configure via env)
- Support multiple versions of Postgres (Currently pinned to 9.6)
- TravisCI integration / Auto push to Hub
