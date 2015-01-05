FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8

#Runit
RUN apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#MySql
RUN apt-get install -y mysql-server mysql-client 

#Memcache
RUN apt-get install -y memcached

#Require libs
RUN apt-get install -y zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libmysqlclient-dev libpq-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libgdbm-dev libncurses5-dev automake libtool bison libffi-dev

#Node
RUN curl http://nodejs.org/dist/v0.10.35/node-v0.10.35-linux-x64.tar.gz | tar xz
RUN mv node* node && \
    ln -s /node/bin/node /usr/local/bin/node && \
    ln -s /node/bin/npm /usr/local/bin/npm
ENV NODE_PATH /usr/local/lib/node_modules
RUN npm -g install bower

#Ruby
RUN curl http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.4.tar.gz | tar -xz && \
    cd ruby* && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf ruby*
RUN gem install bundler

#Openproject
ENV OPENPROJECT_TAG v4.0.4
RUN git clone https://github.com/opf/openproject.git
ENV CONFIGURE_OPTS --disable-install-doc
#Plugins
ADD Gemfile.plugins /openproject/
#Passenger
ADD Gemfile.local /openproject/
RUN cd openproject && \
    git checkout tags/${OPENPROJECT_TAG} && \
    bundle install --without development test && \
    npm install && \
    bower install --allow-root

#Init DB
ADD configuration.yml /openproject/config/
ADD database.yml /openproject/config/
ADD preparedb.sh /
RUN /preparedb.sh

#Add runit services
ADD sv /etc/service 
