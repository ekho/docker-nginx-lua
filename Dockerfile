
FROM debian:stretch-slim as builder
ENV NGINX_VERSION 1.13.7
ENV NGINX_NDK_VERSION 0.3.0
ENV NGINX_LUA_MODULE_VERSION 0.10.11
WORKDIR /opt
RUN set -x \
	&& apt-get update \
	&& apt-get install -y luajit libluajit-5.1-dev wget build-essential libpcre3 libpcre3-dev libghc-zlib-dev
RUN set -x \
  && wget -O nginx-ndk-${NGINX_NDK_VERSION}.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v${NGINX_NDK_VERSION}.tar.gz \
  && tar -xzvf nginx-ndk-${NGINX_NDK_VERSION}.tar.gz
RUN set -x \
  && wget -O lua-nginx-module-${NGINX_LUA_MODULE_VERSION}.tar.gz https://github.com/openresty/lua-nginx-module/archive/v${NGINX_LUA_MODULE_VERSION}.tar.gz \
  && tar -xzvf lua-nginx-module-${NGINX_LUA_MODULE_VERSION}.tar.gz
RUN set -x \
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar -xzvf nginx-${NGINX_VERSION}.tar.gz
RUN set -x \
  && cd nginx-${NGINX_VERSION}/ \
  && export LUAJIT_LIB=/usr/lib/x86_64-linux-gnu \
  && export LUAJIT_INC=/usr/include/luajit-2.0 \
  && ./configure --prefix=/opt \
      --with-ld-opt="-Wl,-rpath,/usr/lib/x86_64-linux-gnu" \
      --add-dynamic-module=/opt/ngx_devel_kit-${NGINX_NDK_VERSION} \
      --add-dynamic-module=/opt/lua-nginx-module-${NGINX_LUA_MODULE_VERSION} \
  && make -j2 \
  && make install

FROM nginx:mainline
LABEL maintainer="Boris Gorbylev <ekho@ekho.name>"
COPY --from=builder /opt/modules/ngx_http_lua_module.so /usr/lib/nginx/modules
COPY --from=builder /opt/modules/ndk_http_module.so /usr/lib/nginx/modules
