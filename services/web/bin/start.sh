#!/bin/sh
set -eu
/var/www/bin/migrate.sh
php-fpm -D
if [ "${FCM_ENABLED:-false}" = "true" ]; then
    # Existing web service; no extra paid Railway service is required.
    php /var/www/bin/process-notifications.php --check-config
    php /var/www/bin/process-notifications.php --loop &
fi
exec nginx -g 'daemon off;'
