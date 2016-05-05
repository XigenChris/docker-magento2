#Use the current Ubuntu LTS release
FROM ubuntu:16.04
MAINTAINER Chris Hilsdon <chrish@xigen.co.uk>

# dpkg-preconfigure error messages fix
# http://stackoverflow.com/a/31595470
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Update the apt-get repository
RUN apt-get update

# Install necessary tools
RUN apt-get install -y nano wget dialog net-tools libreadline6 libreadline6-dev sudo apt-utils

# Install Nginx mainline
ADD nginx.list /etc/apt/sources.list.d/nginx.list
RUN wget -q -O- http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
RUN sudo apt-get update

# Download and Install Nginx
RUN apt-get install -y nginx

RUN nginx -v

COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/magento.conf /etc/nginx/magento.conf

RUN nginx -t

RUN mkdir -p /var/www/magento/
RUN chown -Rv www-data:www-data /var/www/magento/

#Install PHP7 :O
RUN sudo apt-get install -y \
    build-essential \
    pkg-config \
    git-core \
    autoconf \
    bison \
    libxml2-dev \
    libbz2-dev \
    libmcrypt-dev \
    libicu-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libltdl-dev \
    libjpeg-dev \
    libpng-dev \
    libpspell-dev \
    libxslt1-dev

RUN sudo mkdir /usr/local/php7

RUN git clone -b PHP-7.0.6 --depth=1 https://github.com/php/php-src.git

RUN cd php-src && ./buildconf --force

ENV CONFIGURE_STRING="--prefix=/usr/local/php7 \
--with-config-file-scan-dir=/usr/local/php7/etc/conf.d \
--without-pear \
--enable-bcmath \
--with-bz2 \
--enable-calendar \
--enable-intl \
--enable-exif \
--enable-dba \
--enable-ftp \
--with-gettext \
--with-gd \
--with-jpeg-dir \
--enable-mbstring \
--with-mcrypt \
--with-mhash \
--enable-mysqlnd \
--with-mysql=mysqlnd \
--with-mysql-sock=/var/run/mysqld/mysqld.sock \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-openssl \
--enable-pcntl \
--with-pspell \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--enable-wddx \
--with-zlib \
--enable-zip \
--with-readline \
--with-curl \
--with-xsl \
--enable-fpm \
--with-fpm-user=www-data \
--with-fpm-group=www-data"

RUN cd php-src && sudo ./configure $CONFIGURE_STRING
RUN cd php-src && make

RUN cd php-src && sudo make install

## Install.sh
# Create a dir for storing PHP module conf
RUN mkdir /usr/local/php7/etc/conf.d

# Symlink php-fpm to php7-fpm
RUN ln -s /usr/local/php7/sbin/php-fpm /usr/local/php7/sbin/php7-fpm

# Add config files
RUN cd php-src && cp php.ini-production /usr/local/php7/lib/php.ini
ADD conf/php7/www.conf /usr/local/php7/etc/php-fpm.d/www.conf
ADD conf/php7/php-fpm.conf /usr/local/php7/etc/php-fpm.conf
ADD conf/php7/modules.ini /usr/local/php7/etc/conf.d/modules.ini

# Add init script
ADD conf/php7/php7-fpm.init /etc/init.d/php7-fpm
RUN chmod +x /etc/init.d/php7-fpm
RUN update-rc.d php7-fpm defaults

# Link php and phpize into the /usr/bin/ folder
RUN ln -s /usr/local/php7/bin/php /usr/bin/
RUN ln -s /usr/local/php7/bin/phpize /usr/bin/

# Install composer
RUN cd /tmp && \
    php -r "readfile('https://getcomposer.org/installer');" > composer-setup.php && \
    php composer-setup.php --install-dir=/usr/bin/ && \
    ln -s /usr/bin/composer.phar /usr/bin/composer && \
    php -r "unlink('composer-setup.php');"

# Define working directory.
WORKDIR /var/www/magento

VOLUME ["/var/www/magento"]

# Expose ports.
EXPOSE 80 443

# Define default command.
ENTRYPOINT service nginx restart && service php7-fpm restart && bash;
