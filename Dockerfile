#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Use this dockerfile to create a docker image of your apisix local/patched codebase

FROM gateway-build:latest

COPY . /usr/local/apisix

WORKDIR /usr/local/apisix

EXPOSE 9080 9443

# forward request and error logs to docker log collector
RUN make deps && \
    mkdir -p /usr/local/apisix/logs &&  \
    touch logs/access.log &&  \
    touch logs/error.log

ENV PATH=$PATH:/usr/local/apisix/bin:/usr/local/bin:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

CMD ["sh", "-c", "/usr/local/apisix/bin/apisix init && /usr/local/apisix/bin/apisix init_etcd && /usr/local/openresty/bin/openresty -p /usr/local/apisix -g 'daemon off;'"]


STOPSIGNAL SIGQUIT
