FROM php:7.4-cli as build

RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/CopernicaMarketingSoftware/PHP-CPP \
    && cd PHP-CPP \
    && make \
    && make install

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

RUN apt-get install -y python2 libtinfo5

RUN ln -s /usr/bin/python2 /usr/bin/python \
    && export PATH=/depot_tools:"$PATH" \
    && gclient \
    && fetch v8 \
    && cd v8 \
    && git checkout 5.9-lkgr \
    && gclient sync \
    && gn gen out.gn/library --args='is_debug=false is_component_build=true v8_enable_i18n_support=false' \
    && ninja -C out.gn/library libv8.so \
    && cp include/*.h /usr/include \
    && cp out.gn/library/*.so /usr/lib \
    && ldconfig

RUN apt-get install -y lsb-release bc xxd

RUN git clone https://github.com/CopernicaMarketingSoftware/PHP-JS.git \
    && cp v8/out.gn/library/natives_blob.bin PHP-JS \
    && cp v8/out.gn/library/snapshot_blob.bin PHP-JS \
    && cd PHP-JS \
    && make \
    && cp -f php-js.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902 \
    && cp -f php-js.ini /usr/local/etc/php/conf.d/

FROM php:7.4-cli as app

COPY --from=build /usr/local/lib/php/extensions/no-debug-non-zts-20190902/php-js.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=build /usr/local/etc/php/conf.d/php-js.ini /usr/local/etc/php/conf.d/
COPY --from=build /usr/include/phpcpp* /usr/include/
COPY --from=build /usr/lib/libphpcpp* /usr/lib/
COPY --from=build /usr/include/v8* /usr/include/
COPY --from=build /usr/lib/libv8* /usr/lib/
