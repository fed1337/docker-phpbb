# phpBB3 docker image

Lightweight Alpine-based [phpBB](https://www.phpbb.com/) image with nginx and PHP 8.4 FPM.

Bundled phpBB **3.3.17** with support for SQLite, MariaDB/MySQL (`mysqli`), and PostgreSQL.

## Quick start with Docker Compose

The included `compose.yml` runs phpBB with MariaDB LTS:

```console
$ docker compose up -d --build
```

Open http://127.0.0.1:8000. For a fresh install, start once with the installer enabled:

```console
$ PHPBB_INSTALL=true docker compose up --build
```

During installation, use these database settings:

| Field | Value |
| --- | --- |
| Database type | MySQL with MySQLi Extension |
| Database server | `mariadb` |
| Database name | `phpbb` (or your `MARIADB_DATABASE`) |
| Username | `phpbb` (or your `MARIADB_USER`) |
| Password | `phpbb` (or your `MARIADB_PASSWORD`) |

Default MariaDB credentials can be overridden with environment variables:

- `MARIADB_ROOT_PASSWORD` (default: `changeme`)
- `MARIADB_DATABASE` (default: `phpbb`)
- `MARIADB_USER` (default: `phpbb`)
- `MARIADB_PASSWORD` (default: `phpbb`)

After installation, restart without `PHPBB_INSTALL` so the `install/` directory is removed on startup. Optionally enable automatic migrations:

```console
$ docker compose up -d
$ PHPBB_DB_AUTOMIGRATE=true docker compose up -d
```

When `PHPBB_INSTALL` is not set in the environment, the startup script deletes `install/` automatically.

## Standalone container

Build and run the image without Compose:

```console
$ docker build -t phpbb .
$ docker run -p 8000:80 --name phpbb-install -e PHPBB_INSTALL=true -d phpbb
```

By default the standalone image uses SQLite. Set the DSN field to `/phpbb/sqlite/sqlite.db` during installation and leave username, password, and database name blank.

For an external database:

```console
$ docker run --name phpbb \
    -e PHPBB_DB_DRIVER=mysqli \
    -e PHPBB_DB_HOST=dbhost \
    -e PHPBB_DB_PORT=3306 \
    -e PHPBB_DB_NAME=phpbb \
    -e PHPBB_DB_USER=phpbb \
    -e PHPBB_DB_PASSWD=pass \
    -p 8000:80 -d phpbb
```

## Environment variables

Most variables are written into phpBB's `config.php` or read by the startup script.

### PHPBB_INSTALL

If `true`, removes `config.php` and keeps the `/install/` directory for a fresh setup.

### PHPBB_DB_DRIVER

Supported drivers in this image: `sqlite3`, `mysqli`, `postgres`.

Default: `sqlite3`

### PHPBB_DB_HOST

Database hostname, or SQLite file path for the `sqlite3` driver.

Default: `/phpbb/sqlite/sqlite.db`

### PHPBB_DB_PORT

Database port (required for `PHPBB_DB_WAIT` with network databases).

### PHPBB_DB_NAME / PHPBB_DB_USER / PHPBB_DB_PASSWD

Database credentials.

### PHPBB_DB_TABLE_PREFIX

Default: `phpbb_`

### PHPBB_DB_AUTOMIGRATE

If `true`, runs `bin/phpbbcli.php db:migrate` on startup. Requires an existing database schema.

### PHPBB_DB_WAIT

If `true`, waits for the database host/port to accept connections before running migrations. Not used with SQLite.

### PHPBB_DISPLAY_LOAD_TIME / PHPBB_DEBUG / PHPBB_DEBUG_CONTAINER

Enable phpBB debug and diagnostics output when set to `true`.

## Volumes

Persistent data paths:

- `/phpbb/www/files`
- `/phpbb/www/store`
- `/phpbb/www/images/avatars/upload`
- `/phpbb/sqlite` (SQLite only)

## Updating phpBB version

```console
$ ./update.sh 3.3
```

This updates `PHPBB_VERSION` and its checksum in the `Dockerfile`.

## Custom configuration

Drop PHP settings into `/usr/local/etc/php/conf.d` and nginx site config into `/etc/nginx/http.d` by extending the image:

```dockerfile
FROM your-image/phpbb:latest

COPY custom.ini /usr/local/etc/php/conf.d/
COPY custom.conf /etc/nginx/http.d/
```

To pass the client IP through a reverse proxy, configure nginx `real_ip` directives in a custom server block.
