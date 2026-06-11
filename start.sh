#!/bin/sh

set -e

if [ "${PHPBB_INSTALL:-}" = "true" ]; then
	rm -f config.php
else
	rm -rf install
fi

db_wait() {
	if [[ "${PHPBB_DB_WAIT}" = "true" && "${PHPBB_DB_DRIVER}" != "sqlite3" && "${PHPBB_DB_DRIVER}" != "sqlite" ]]; then
		until nc -z ${PHPBB_DB_HOST} ${PHPBB_DB_PORT}; do
			echo "$(date) - waiting for database on ${PHPBB_DB_HOST}:${PHPBB_DB_PORT} to start before applying migrations"
			sleep 3
		done
	fi
}

db_migrate() {
	if [[ "${PHPBB_DB_AUTOMIGRATE}" = "true" && "${PHPBB_INSTALL}" != "true" ]]; then
		echo "$(date) - applying migrations"
		su-exec nginx php bin/phpbbcli.php db:migrate
	fi
}

db_wait && db_migrate

php-fpm &
exec nginx -g 'daemon off;'
