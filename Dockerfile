# Use the official PHP image with Apache.
# PHP 8.1 is EOL, so 8.1.34 is pinned by digest and rebuilt below with the
# php-src security backport for CVE-2026-109618 / CVE-2026-109619.
FROM --platform=linux/amd64 php:8.1.34-apache-bookworm@sha256:a935f4a5717427519337269d5d1c89968cc27ab84d1c8d5d7b5363672d800cd5

# Upstream backport: https://github.com/php/php-src/commit/1d7dec178a094e6e75b229ce22754045f8c6070a
COPY patches/php-8.1-CVE-2026-109618-109619.patch /usr/src/
RUN set -eux; \
    echo "c85ad0fddcbff7f2318617eeaa54d271135463b5bf70a01228447e3ed78de96e  /usr/src/php-8.1-CVE-2026-109618-109619.patch" | sha256sum -c -; \
    apt-get update; \
    apt-get install -y --no-install-recommends patch apache2-dev libargon2-dev libcurl4-openssl-dev libonig-dev \
      libreadline-dev libsodium-dev libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    docker-php-source extract; \
    cd /usr/src/php; \
    patch -p1 < /usr/src/php-8.1-CVE-2026-109618-109619.patch; \
    eval "./configure $(php-config --configure-options)"; \
    make -j "$(nproc)"; \
    make install; \
    cd /; \
    docker-php-source delete; \
    rm -rf /var/lib/apt/lists/* /usr/src/php-8.1-CVE-2026-109618-109619.patch; \
    php -r 'exit(PHP_VERSION === "8.1.34" ? 0 : 1);'; \
    grep -q zend_mm_safe_error_ex "$(php-config --include-dir)/Zend/zend_alloc.h"; \
    grep -q zend_mm_safe_error_ex /usr/lib/apache2/modules/libphp.so

# Mitigation from the PHP security team for CVE-2026-109619 / CVE-2026-115560.
RUN echo "session.upload_progress.enabled = 0" > "$PHP_INI_DIR/conf.d/zz-security.ini"

# Set working directory
WORKDIR /var/www/html

RUN apt-get update

# Add the GPG keys and update the repository
RUN apt-get install --reinstall gcc
RUN apt-get install -y apt-utils
RUN apt-get install -y gnupg 
RUN apt-get install -y libfreetype6-dev 
RUN apt-get install -y libjpeg-dev 
RUN apt-get install -y libpng-dev 
RUN apt-get install -y libxpm-dev 
RUN apt-get install -y libvpx-dev 
RUN apt-get install -y libzip-dev 
RUN apt-get install -y libicu-dev 
RUN apt-get install -y libxml2-dev 
RUN apt-get install -y libssl-dev 
RUN apt-get install -y libxslt1-dev 
RUN apt-get install -y libonig-dev 
RUN apt-get install -y zlib1g-dev 
RUN apt-get install -y libcurl4-openssl-dev 
RUN apt-get install -y pkg-config 
RUN apt-get install -y libmagickwand-dev 
RUN apt-get install -y git

RUN rm -r /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-xpm
RUN docker-php-ext-configure zip
RUN docker-php-ext-configure pdo
RUN docker-php-ext-configure mbstring
RUN docker-php-ext-configure intl

# Install PHP extensions
RUN docker-php-ext-install gd
RUN docker-php-ext-install zip
RUN docker-php-ext-install pdo
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install intl 
RUN docker-php-ext-install pdo_mysql 
RUN docker-php-ext-install mysqli 
RUN docker-php-ext-install soap 
RUN docker-php-ext-install bcmath 
RUN docker-php-ext-install opcache 
RUN docker-php-ext-install exif 
RUN docker-php-ext-install pcntl 
RUN docker-php-ext-install xsl 
RUN docker-php-ext-install curl 
RUN docker-php-ext-install gettext 
RUN docker-php-ext-install xml 
RUN docker-php-ext-install sockets 
RUN docker-php-ext-install ftp
RUN docker-php-ext-install calendar

# Install and enable PECL extensions
RUN pecl install redis imagick 
RUN docker-php-ext-enable redis imagick

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set the correct permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Expose port 8080 (Cloud Run expects the service to listen on this port)
EXPOSE 8080
    
# Set the Apache environment variable for the document root
ENV APACHE_DOCUMENT_ROOT /var/www/html

# Update the default Apache site with the new document root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Update the default Apache ports to listen on port 8080
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf

# Fix the .htaccess file handling
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set entrypoint
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]
