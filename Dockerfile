# Use the official PHP image with Apache
FROM --platform=linux/amd64 php:8.1-apache

# Set working directory
WORKDIR /var/www/html

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN curl -sS --insecure https://www.dotdeb.org/dotdeb.gpg | apt-key add -

# Add the GPG keys and update the repository
RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends \
    apt-utils \
    gnupg \ 
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libxpm-dev \
    libvpx-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libssl-dev \
    libxslt1-dev \
    libonig-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libmagickwand-dev \
    git

RUN rm -r /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-xpm
RUN docker-php-ext-configure zip
RUN docker-php-ext-configure pdo

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

# Set entrypoint
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]
