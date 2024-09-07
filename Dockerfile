FROM registry.cn-hangzhou.aliyuncs.com/ckall/gatewaybuild:latest

WORKDIR /usr/local/apisix
COPY  ./ /usr/local/apisix/

RUN make build
#
EXPOSE 9080 9443
#
CMD ["sh", "-c", "/usr/local/apisix/bin/apisix init && /usr/local/apisix/bin/apisix init_etcd && /usr/local/openresty/bin/openresty -p /usr/local/apisix -g 'daemon off;'"]

STOPSIGNAL SIGQUIT
