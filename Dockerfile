FROM php:8-apache

# Install necessary PHP extensions and tools
RUN apt-get update && apt-get install -y git zip unzip curl

# Install PHP extensions
RUN docker-php-ext-install mysqli

# Add ServerName to Apache config
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && chmod +x /usr/local/bin/composer \
  && ln -s /usr/local/bin/composer /usr/bin/composer

# Check Composer version to verify the installation
RUN /usr/local/bin/composer --version

# Copy Apache configuration
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Copy application source and set permissions
COPY html /var/www
RUN chown -R www-data:www-data /var/www

# Set the working directory
WORKDIR /var/www

# Install Composer dependencies
RUN composer install

# Expose port and start Apache
EXPOSE 80
CMD ["apache2-foreground"]
