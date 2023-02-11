# run migrations
php artisan key:generate 
php artisan config:cache
php artisan migrate:fresh
php artisan migrate --seed

# Updating composer
composer update --no-interaction --no-dev --prefer-dist

# main execution
exec apache2-foreground