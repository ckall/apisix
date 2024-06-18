FROM registry.cn-hangzhou.aliyuncs.com/ckall/production-stage:latest AS production-stage
#
COPY ./ /apisix/
#
RUN make resty-install

FROM centos:7 AS last-stage
#
WORKDIR /usr/local/apisix
#
COPY --from=production-stage /usr/local/ /usr/local/
COPY --from=production-stage /apisix/apisix/ /usr/local/apisix/apisix/
COPY --from=production-stage /apisix/conf/ /usr/local/apisix/conf/
COPY --from=production-stage /apisix/deps/ /usr/local/apisix/deps/
COPY --from=production-stage /apisix/bin/apisix /usr/local/bin/apisix
##
ENV PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
## forward request and error logs to docker log collector
RUN mkdir -p /usr/local/apisix/logs && \
    touch /usr/local/apisix/logs/access.log && \
    touch /usr/local/apisix/logs/error.log && \
    ln -sf /dev/stdout /usr/local/apisix/logs/access.log && \
    ln -sf /dev/stderr /usr/local/apisix/logs/error.log
#
EXPOSE 9080 9443
#
CMD ["sh", "-c", "/usr/local/bin/apisix init && /usr/local/bin/apisix init_etcd && /usr/local/openresty/bin/openresty -p /usr/local/apisix -g 'daemon off;'"]
#
STOPSIGNAL SIGQUIT
