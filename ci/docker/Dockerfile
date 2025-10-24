FROM debian:bullseye-slim

COPY install-dependencies.sh /install-dependencies.sh


RUN set -x \
        && apt-get -y update --fix-missing \
        && apt-get install -y \
            make \
            git  \
            sudo \
            libyaml-dev \
        && ls -al \
        && chmod +x /install-dependencies.sh \
        && /install-dependencies.sh

STOPSIGNAL SIGQUIT
