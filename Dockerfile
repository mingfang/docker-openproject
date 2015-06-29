FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

#MySql
RUN apt-get install -y mysql-server mysql-client 

#Memcache
RUN apt-get install -y memcached

#Require libs
RUN apt-get install -y zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libmysqlclient-dev libpq-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libgdbm-dev libncurses5-dev automake libtool bison libffi-dev

#Node
RUN curl http://nodejs.org/dist/v0.12.5/node-v0.12.5-linux-x64.tar.gz | tar xz
RUN mv node* node && \
    ln -s /node/bin/node /usr/local/bin/node && \
    ln -s /node/bin/npm /usr/local/bin/npm
ENV NODE_PATH /usr/local/lib/node_modules
RUN npm -g install bower

#Ruby
ENV CONFIGURE_OPTS --disable-install-doc
RUN curl http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz | tar -xz && \
    cd ruby* && \
    ./configure --disable-install-doc && \
    make -j8 && \
    make install && \
    cd / && \
    rm -rf ruby*
RUN gem install bundler

#Openproject
RUN git clone https://github.com/opf/openproject.git
RUN cd openproject && \
    git checkout v4.1.3

RUN echo '{ "allow_root": true }' >> ~/.bowerrc

RUN cd openproject && \
    bundle install --without development test && \
    npm install --unsafe-perm

RUN npm install -g webpack

#Plugins
ADD Gemfile.plugins /openproject/
#Passenger
ADD Gemfile.local /openproject/
RUN cd openproject && \
    bundle install --without development test && \
    npm install --unsafe-perm

#Init DB
ADD configuration.yml /openproject/config/
ADD database.yml /openproject/config/
ADD preparedb.sh /
RUN /preparedb.sh

#Add runit services
ADD sv /etc/service 
