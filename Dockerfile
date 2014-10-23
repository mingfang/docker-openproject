FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

#Runit
RUN apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

RUN apt-get install -y gcc make libxml2-dev libxslt-dev g++ libpq-dev
RUN apt-get install -y postgresql postgresql-contrib

#Ruby
RUN curl http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz | tar -xz && \
    cd ruby* && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf ruby*
#Bundler
RUN gem install bundler --version '>=1.5.1'

#Openproject stable branch
ENV OPENPROJECT_VERSION 3.0.3
RUN git clone --depth 1 --branch stable https://github.com/opf/openproject.git

ADD Gemfile.plugins /openproject/
ADD Gemfile.local /openproject/
RUN cd openproject && \
    bundle install --without mysql mysql2 sqlite development test rmagick

#Memcache
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y memcached

#Add runit services
ADD sv /etc/service 

RUN runsv /etc/service/postgres & sleep 2 && sv start postgres && \
    sudo -u postgres psql -c "CREATE USER openproject WITH PASSWORD 'openproject';" && \
    sudo -u postgres psql -c "CREATE DATABASE openproject WITH OWNER openproject ENCODING 'UTF8' TEMPLATE template0;" && \
    sudo -u postgres psql -c "GRANT ALL ON DATABASE openproject TO openproject;" && \
    sv stop postgres

ADD database.yml /openproject/config/
ADD configuration.yml /openproject/config/
ADD pg_hba.conf /etc/postgresql/9.3/main/

#Init Db
RUN runsv /etc/service/postgres & sleep 2 && sv start postgres && \
    runsv /etc/service/memcache & sleep 3 && sv start memcache && \
    cd /openproject && \
    rake generate_secret_token && \
    bundle exec rake db:create:all && \
    bundle exec rake db:migrate RAILS_ENV=production && \
    bundle exec rake db:seed RAILS_ENV=production && \
    bundle exec rake assets:precompile && \
    sv stop postgres
