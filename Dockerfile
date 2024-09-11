FROM 172.16.179.159/jiuzhou/gatewaybuild:1.1

WORKDIR /usr/local/apisix
COPY  ./ /usr/local/apisix/

RUN make build
#
EXPOSE 9080 9443
# forward request and error logs to docker log collector
RUN mkdir -p /usr/local/apisix/logs &&  \
    touch logs/access.log &&  \
    touch logs/error.log

CMD ["sh", "-c", "/usr/local/apisix/bin/apisix init && /usr/local/apisix/bin/apisix init_etcd && /usr/local/openresty/bin/openresty -p /usr/local/apisix -g 'daemon off;'"]

STOPSIGNAL SIGQUIT
