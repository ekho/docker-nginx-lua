ARG NGINX_VERSION=1.13.7

FROM debian:stretch-slim as builder
ARG NGINX_VERSION
ENV LUA_VERSION 5.1
ENV LUAJIT2_VERSION 2.1-20171103
ENV NGINX_VERSION ${NGINX_VERSION}
ENV NGINX_NDK_VERSION 0.3.0
ENV NGINX_LUA_HTTP_MODULE_VERSION 0.10.11
ENV NGINX_LUA_STREAM_MODULE_VERSION 0.0.3
ENV NGINX_LUA_RESTY_CORE_VERSION 0.1.13
ENV NGINX_LUA_RESTY_LRUCACHE_VERSION 0.07
ENV NGINX_LUA_SPLIT_CLIENTS_VERSION 0.0.2

WORKDIR /opt
RUN set -x \
	&& apt-get update \
	&& apt-get install -y wget build-essential libpcre3 libpcre3-dev libghc-zlib-dev libssl1.0-dev
RUN set -x \
  && wget -O luajit2-${LUAJIT2_VERSION}.tar.gz https://github.com/openresty/luajit2/archive/v${LUAJIT2_VERSION}.tar.gz \
  && tar -xzvf luajit2-${LUAJIT2_VERSION}.tar.gz \
  && cd luajit2-${LUAJIT2_VERSION} \
  && make -j2 \
  && make install
RUN set -x \
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar -xzvf nginx-${NGINX_VERSION}.tar.gz
RUN set -x \
  && wget -O nginx-ndk-${NGINX_NDK_VERSION}.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v${NGINX_NDK_VERSION}.tar.gz \
  && tar -xzvf nginx-ndk-${NGINX_NDK_VERSION}.tar.gz
RUN set -x \
  && wget -O lua-nginx-module-${NGINX_LUA_HTTP_MODULE_VERSION}.tar.gz https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_HTTP_MODULE_VERSION}.tar.gz \
  && tar -xzvf lua-nginx-module-${NGINX_LUA_HTTP_MODULE_VERSION}.tar.gz
RUN set -x \
  && wget -O stream-lua-nginx-module-${NGINX_LUA_STREAM_MODULE_VERSION}.tar.gz https://github.com/openresty/stream-lua-nginx-module/archive/v${NGINX_LUA_STREAM_MODULE_VERSION}.tar.gz \
  && tar -xzvf stream-lua-nginx-module-${NGINX_LUA_STREAM_MODULE_VERSION}.tar.gz
RUN set -x \
  && wget -O lua-resty-lrucache-${NGINX_LUA_RESTY_LRUCACHE_VERSION}.tar.gz https://github.com/openresty/lua-resty-lrucache/archive/v${NGINX_LUA_RESTY_LRUCACHE_VERSION}.tar.gz \
  && tar -xzvf lua-resty-lrucache-${NGINX_LUA_RESTY_LRUCACHE_VERSION}.tar.gz
RUN set -x \
  && wget -O lua-resty-core-${NGINX_LUA_RESTY_CORE_VERSION}.tar.gz https://github.com/openresty/lua-resty-core/archive/v${NGINX_LUA_RESTY_CORE_VERSION}.tar.gz \
  && tar -xzvf lua-resty-core-${NGINX_LUA_RESTY_CORE_VERSION}.tar.gz
RUN set -x \
  && wget -O lua-nginx-split-clients-${NGINX_LUA_SPLIT_CLIENTS_VERSION}.tar.gz https://github.com/ekho/lua-nginx-split-clients/archive/v${NGINX_LUA_SPLIT_CLIENTS_VERSION}.tar.gz \
  && tar -xzvf lua-nginx-split-clients-${NGINX_LUA_SPLIT_CLIENTS_VERSION}.tar.gz
RUN set -x \
  && cd nginx-${NGINX_VERSION}/ \
  && export LUAJIT_LIB=/usr/local/lib \
  && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
  && ./configure --prefix=/opt \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --user=nginx \
      --group=nginx \
      --with-compat \
      --with-file-aio \
      --with-threads \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_slice_module \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_sub_module \
      --with-http_v2_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_realip_module \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-${NGINX_VERSION}/debian/debuild-base/nginx-${NGINX_VERSION}=. -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
      --with-ld-opt='-specs=/usr/share/dpkg/no-pie-link.specs -Wl,-z,relro -Wl,-rpath,/usr/lib/x86_64-linux-gnu,-z,now -Wl,--as-needed -pie' \
      --add-module=/opt/ngx_devel_kit-${NGINX_NDK_VERSION} \
      --add-module=/opt/lua-nginx-module-${NGINX_LUA_HTTP_MODULE_VERSION} \
      --add-module=/opt/stream-lua-nginx-module-${NGINX_LUA_STREAM_MODULE_VERSION} \
  && make -j2 \
  && make install
RUN set -x \
  && cd lua-resty-lrucache-${NGINX_LUA_RESTY_LRUCACHE_VERSION} \
  && make install
RUN set -x \
  && cd lua-resty-core-${NGINX_LUA_RESTY_CORE_VERSION} \
  && make install
RUN set -x \
  && cd lua-nginx-split-clients-${NGINX_LUA_SPLIT_CLIENTS_VERSION} \
  && make install

FROM nginx:${NGINX_VERSION}
LABEL maintainer="Boris Gorbylev <ekho@ekho.name>"
RUN set -x \
	&& apt-get update \
	&& apt-get install -y libssl1.0.2 \
	&& apt-get purge -y --auto-remove \
	&& rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2.1.0 /usr/lib/x86_64-linux-gnu/libluajit-5.1.so.2
COPY --from=builder /usr/local/lib/lua /usr/local/share/lua
