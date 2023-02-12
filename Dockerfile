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
RUN useradd -G www-data,root -u ${uid} -d /home/$user $user
RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

# Create system user to run Composer and Artisan Commands
# RUN groupadd -g $UID $user && \
#     useradd -u $UID -g $user -m $user

# Copy existing application directory contents
COPY . /var/www/megait

# Copy existing application directory permissions
COPY --chown=$user:$user . /var/www/megait/


# RUN groupadd -g 1000 www
# RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory permissions
# COPY --chown=www:www . /var/www/megait

RUN chown -R ${user}:www-data . \
    && find . -type f -exec chmod 664 {} \; \
    && find . -type d -exec chmod 775 {} \; \
    && chgrp -R www-data storage bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

# Assume user
USER $user

RUN composer install --no-interaction --no-dev --prefer-dist

COPY apache-config/megait.conf /etc/apache2/sites-available/megait.conf

RUN a2enmod rewrite && \
    a2dissite 000-default.conf && \
    a2ensite megait.conf && \
    service apache2 restart

# Expose port 9000 and start a custom entrypoint
EXPOSE 9000

ENTRYPOINT ["bash", "/seeds.sh"]