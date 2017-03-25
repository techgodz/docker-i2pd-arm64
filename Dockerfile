FROM techgodz/alpine-arm64

MAINTAINER Ross Leak <ross.leak@tech.godz.co.uk>

ENV GIT_BRANCH="master"
ENV I2PD_PREFIX="/opt/i2pd-${GIT_BRANCH}"
ENV PATH=${I2PD_PREFIX}/bin:$PATH


RUN mkdir /user && adduser -S -h /user i2pd && chown -R i2pd:nobody /user

# Each RUN is a layer, adding the dependencies and building i2pd in one layer takes around 8-900Mb, so to keep the 
# image under 20mb we need to remove all the build dependencies in the same "RUN" / layer.
#

# 1. install deps, clone and build. 
# 2. strip binaries. 
# 3. Purge all dependencies and other unrelated packages, including build directory. 
RUN apk --no-cache --virtual build-dependendencies add make gcc g++ cmake libtool boost-dev build-base openssl-dev openssl git \
    && mkdir -p /tmp/build \
    && cd /tmp/build && git clone -b ${GIT_BRANCH} https://github.com/PurpleI2P/i2pd.git \
    && cd i2pd \
    && cd build \
    && cmake -L \
    && make -j2 \
    && mkdir -p ${I2PD_PREFIX}/conf \
    && mkdir -p ${I2PD_PREFIX}/bin \
    && mkdir -p /user/.i2pd \
    && mv i2pd ${I2PD_PREFIX}/bin/ \
    && cd ${I2PD_PREFIX}/bin \
    && strip i2pd \
    && rm -fr /tmp/build && apk --purge del build-dependendencies build-base fortify-headers boost-dev zlib-dev openssl-dev \
    boost-python3 python3 gdbm boost-unit_test_framework boost-python linux-headers boost-prg_exec_monitor \
    boost-serialization boost-signals boost-wave boost-wserialization boost-math boost-graph boost-regex git pcre \
    libtool g++ gcc pkgconfig cmake

# 4. Adding required libraries to run i2pd to ensure it will run.
RUN apk --no-cache add boost-filesystem boost-system boost-program_options boost-date_time boost-thread boost-iostreams openssl musl-utils libstdc++


# 5. Pushing custom configuration files into the image and entrypoint.sh
COPY i2pd.conf ${I2PD_PREFIX}/conf/i2pd.conf
COPY subscriptions.txt ${I2PD_PREFIX}/conf/subscriptions.txt
COPY tunnels.conf /user/.i2pd/tunnels.conf
COPY entrypoint.sh /entrypoint.sh


RUN chmod a+x /entrypoint.sh
RUN echo "export PATH=${PATH}" >> /etc/profile

# 6. Define exposed ports of our application
EXPOSE 7070 4444 4447 9439 7656 2827 7654 7650 8834
USER i2pd

# 7. Call entrypoint.sh script
ENTRYPOINT [ "/entrypoint.sh" ]
