FROM registry.cn-hangzhou.aliyuncs.com/ckall/gtewaybase:latest
COPY ./ .
RUN  chmod +x ./utils/build-apisix-runtime.sh && \
     ./utils/build-apisix-runtime.sh latest && \
     ./utils/linux-install-luarocks.sh

STOPSIGNAL SIGQUIT
