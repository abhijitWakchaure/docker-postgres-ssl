# Docker Postgres SSL

This will help you quickly spin up a SSL enabled Postgres server with dummy table schema.

## How to

Basic commands

### Start the server

```bash
$ docker-compose up --force-recreate --build
```

`--force-recreate` will recreate the containers even if their configuration and image haven't changed

`--build` will build the docker image, so your local changes will get picked up. If you don't want to make any changes, you can remove this flag

### Stop the server

```bash
$ docker-compose down -v --remove-orphans
```

`-v` will remove named volumes declared in the `volumes` section of the `docker-compose` file and anonymous volumes attached to containers

`--remove-orphans` will remove containers for services not defined in the Compose file
