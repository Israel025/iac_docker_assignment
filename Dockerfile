FROM php:apache-bullseye

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Set working directory
WORKDIR /var/www/megait

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jpegoptim optipng pngquant gifsicle \
        build-essential \
        libpng-dev \
        libzip-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        locales \
        unzip \
        zip \
        vim \
        git \
        wget \
        curl \
        git \
        libonig-dev \
        libxml2-dev \
        lsb-release \  
        apt-transport-https \
        ca-certificates \
        software-properties-common

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
        mysql \
        mysqli \
        pcntl \
        zip \
        sockets \
        intl \
        bcmath

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Add user for laravel application
RUN chown -R $user:$user /var/www/megait

# Switch to added user
USER $user

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --no-dev --prefer-dist

# Copy existing application directory permissions
COPY --chown=$user:$user ./application/* /var/www/megait

COPY apache-config/megait.conf /etc/apache2/sites-available/megait.conf

RUN a2enmod rewrite && \
    a2dissite 000-default 000-default.conf && \
    a2ensite megait.conf && \
    service apache2 restart

# Expose port 9000 and start a custom entrypoint
EXPOSE 9000

ENTRYPOINT ["bash", "/seeds.sh"]