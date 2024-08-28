FROM php:8-apache

# Install necessary PHP extensions and tools
RUN apt-get update && apt-get install -y git zip unzip

RUN <<-EOF
 docker-php-ext-install mysqli
 echo "ServerName localhost" >> /etc/apache2/apache2.conf
 # Install Composer
 curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
EOF

# Copy Apache configuration
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Copy application source and set permissions
COPY html /var/www
RUN chown -R www-data:www-data /var/www

# Install Composer dependencies
WORKDIR /var/www
RUN composer install

# Expose port and start Apache
EXPOSE 80
CMD ["apache2-foreground"]
