FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Shanghai
ENV TIME_ZONE=${TZ}

RUN apt update && apt install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
        ca-certificates \
    && apt clean && apt autoclean && apt autoremove -y \
    && rm -rf /tmp/* /var/cache/* /usr/share/doc/* /usr/share/man/* /var/lib/apt/lists/*

COPY ubuntu22.sources.list /etc/apt/sources.list

# 安装必要工具
RUN apt update && apt install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
        build-essential \
        tzdata \
        git \
        curl \
        wget \
        vim \
        gdb \
        iputils-ping \
        net-tools \
        lsb-release \
        libxml2-dev \
        libssl-dev \
        openssl \
        libffi-dev \
        libx11-xcb1 \
        libxtst6 \
        libxtst6 \
        libnss3 \
        libasound2 \
        libatk-bridge2.0-0 \
        libgtk-3-0 \
        zlib1g \
        zlib1g-dev \
        libsqlite3-dev \
        libpq-dev \
        libxslt-dev \
        libcurl4-openssl-dev \
    && ln -snf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime \
    && echo ${TIME_ZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt clean && apt autoclean && apt autoremove -y \
    && rm -rf /tmp/* /var/cache/* /usr/share/doc/* /usr/share/man/* /var/lib/apt/lists/*

# 编译安装cmake
RUN cd /tmp && wget https://cmake.org/files/v3.25/cmake-3.25.3.tar.gz \
    && tar -xzf cmake-3.25.3.tar.gz && cd cmake-3.25.3 \
    && ./configure && make -j8 && make install \
    && rm -rf /tmp/cmake-3.25.3*

# 编译安装python3.11
ARG PY_INSTALL_PREFIX="/usr/local"
ENV PY_VER=3.8.20
RUN cd /tmp && wget https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tgz \
    && tar -xzf Python-${PY_VER}.tgz && cd Python-${PY_VER} \
    && ./configure --enable-shared --enable-optimizations --with-zlib --enable-loadable-sqlite-extensions \
         --prefix=${PY_INSTALL_PREFIX} \
    && make -j8 && make install && ldconfig \
    && ln -s ${PY_INSTALL_PREFIX}/bin/pip3 ${PY_INSTALL_PREFIX}/bin/pip \
    && ln -s ${PY_INSTALL_PREFIX}/bin/python3 ${PY_INSTALL_PREFIX}/bin/python \
    && rm -rf /tmp/Python-*
COPY pip.conf /root/.pip/pip.conf

# install phantomjs
RUN mkdir -p /opt/phantomjs \
    && cd /opt/phantomjs \
    && wget -O phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
    && tar xavf phantomjs.tar.bz2 --strip-components 1 \
    && ln -s /opt/phantomjs/bin/phantomjs /usr/local/bin/phantomjs \
    && rm phantomjs.tar.bz2
# Fix Error: libssl_conf.so: cannot open shared object file: No such file or directory
ENV OPENSSL_CONF=/etc/ssl/

# install nodejs
ENV NODEJS_VERSION=18.9.1 \
    PATH=$PATH:/opt/node/bin
WORKDIR "/opt/node"
RUN curl -sL https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.gz | tar xz --strip-components=1 \
    && npm install puppeteer express

# install requirements
COPY requirements.txt /opt/pyspider/requirements.txt
RUN pip install -r /opt/pyspider/requirements.txt

# add all repo
ADD ./ /opt/pyspider

# run test
WORKDIR /opt/pyspider
RUN pip install -e .[all]

# Create a symbolic link to node_modules
RUN ln -s /opt/node/node_modules ./node_modules

RUN pip install oss2 celery 

#VOLUME ["/opt/pyspider"]
ENTRYPOINT ["pyspider"]

EXPOSE 5000 23333 24444 25555 22222
