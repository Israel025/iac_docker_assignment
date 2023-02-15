FROM php:apache-bullseye

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Set working directory
WORKDIR /var/www/megait

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libpng-dev \
    locales \
    unzip \
    zip \
    vim \
    git \
    wget \
    curl \
    git \
    libonig-dev \
    libxml2-dev 

# Clean cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions \
    gd \
    xdebug \
    exif \
    opcache \
    mbstring \
    pdo_mysql \
    pcntl \
    bcmath

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u ${uid} -d /home/${user} ${user}
RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

# Copy existing application directory contents
COPY . /var/www/megait

# Copy existing application directory permissions
RUN chown -R ${user}:www-data /var/www/megait \
    && find . -type f -exec chmod 664 {} \; \
    && find . -type d -exec chmod 775 {} \; \
    && chmod -R 775 storage bootstrap/cache

RUN composer install --no-interaction --no-dev --prefer-dist

COPY apache-config/megait.conf /etc/apache2/sites-available/megait.conf

RUN a2enmod rewrite && \
    a2dissite 000-default.conf && \
    a2ensite megait.conf

#CMD ["apache2-foreground"]