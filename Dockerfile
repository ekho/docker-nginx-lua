FROM debian:stretch-slim as builder
ENV NGINX_VERSION 1.13.7
ENV NGINX_NDK_VERSION 0.3.0
ENV NGINX_LUA_MODULE_VERSION 0.10.11
WORKDIR /opt
RUN set -x \
	&& apt-get update \
	&& apt-get install -y luajit libluajit-5.1-dev wget build-essential libpcre3 libpcre3-dev libghc-zlib-dev libssl1.0-dev
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
      --add-module=/opt/lua-nginx-module-${NGINX_LUA_MODULE_VERSION} \
  && make -j2 \
  && make install

#      --add-dynamic-module=/opt/ngx_devel_kit-${NGINX_NDK_VERSION} \
#      --add-dynamic-module=/opt/lua-nginx-module-${NGINX_LUA_MODULE_VERSION} \

FROM nginx:mainline
LABEL maintainer="Boris Gorbylev <ekho@ekho.name>"
RUN set -x \
	&& apt-get update \
	&& apt-get install -y libluajit-5.1-2 libssl1.0.2 \
	&& apt-get purge -y --auto-remove \
	&& rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
#COPY --from=builder /opt/modules/ngx_http_lua_module.so /usr/lib/nginx/modules
#COPY --from=builder /opt/modules/ndk_http_module.so /usr/lib/nginx/modules
