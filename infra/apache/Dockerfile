FROM ubuntu:latest
LABEL Author="Jochen Schultz" Description="Dockerfile for local development"
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin \
    APACHE_RUN_DIR=/var/lib/apache/runtime \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data
RUN apt-get update && apt-get install -yqq \
    software-properties-common \
    tzdata \
    whiptail \
    make \
    gcc \
    g++ \
    curl \
    apt-utils \
    apache2
RUN echo "Package: *\nPin: release o=LP-PPA-ondrej-php\nPin-Priority: 900" > /etc/apt/preferences.d/ondrej-php
RUN echo "Package: php8.4*\nPin: release o=LP-PPA-ondrej-php\nPin-Priority: -1" >> /etc/apt/preferences.d/ondrej-php
RUN add-apt-repository ppa:ondrej/php -y && apt-get update
RUN apt-get install -yqq libgd3
RUN apt-get install -yqq libapache2-mod-php8.3
RUN apt-get install -yqq libapache2-mod-auth-openidc
RUN apt-get install -yqq php8.3-raphf
RUN apt-get install -yqq php8.3-mysql
RUN apt-get install -yqq php8.3-pgsql
RUN apt-get install -yqq php8.3-mbstring
RUN apt-get install -yqq php8.3-curl
RUN apt-get install -yqq php8.3-intl
RUN apt-get install -yqq php8.3-xml
RUN apt-get install -yqq php8.3-gd
RUN apt-get install -yqq php8.3-common
RUN apt-get install -yqq php-json
RUN apt-get install -yqq php8.3-memcached
RUN apt-get install -yqq php8.3-amqp
RUN apt-get install -yqq php8.3-cli
RUN apt-get install -yqq php8.3-bcmath
RUN apt-get install -yqq php8.3-zip
RUN apt-get install -yqq libcap2-bin
RUN apt-get install -yqq php8.3-dev
RUN apt-get install -yqq ca-certificates
RUN apt-get install -yqq vim
RUN apt-get install -yqq openssl
RUN apt-get install -yqq openssh-client
RUN apt-get install -yqq zip
RUN apt-get install -yqq acl
RUN apt-get install -yqq php8.3-http
RUN apt-get install -yqq php8.3-xdebug
RUN apt-get install -yqq postgresql-client
RUN apt-get install -yqq php8.3-pgsql
RUN a2enmod php8.3 ssl rewrite headers expires ext_filter
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh && bash nodesource_setup.sh
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y nodejs
RUN apt-get install -y yarn
RUN mkdir -p /var/www/html/public ${APACHE_RUN_DIR} /var/log/supervisor
RUN chmod -R 777 /var/www/html /var/log/apache2 ${APACHE_RUN_DIR}
RUN echo "alias ..='cd ../'" >> /root/.bashrc
RUN echo "alias ...='cd ../../'" >> /root/.bashrc
RUN echo "alias ll='ls -lastr'" >> /root/.bashrc
RUN update-alternatives --set php /usr/bin/php8.3
RUN echo "opcache.save_comments=1" > /etc/php/8.3/mods-available/opcache.ini && \
    ln -sf /etc/php/8.3/mods-available/opcache.ini /etc/php/8.3/apache2/conf.d/10-opcache.ini && \
    ln -sf /etc/php/8.3/mods-available/opcache.ini /etc/php/8.3/cli/conf.d/10-opcache.ini
ADD start.sh /start.sh
RUN chmod 0755 /start.sh
EXPOSE 8081
CMD ["bash", "/start.sh"]
