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

# Makefile basic env setting
.DEFAULT_GOAL := help
# add pipefail support for default shell
SHELL := /bin/bash -o pipefail


# Project basic setting
VERSION                ?= master
project_name           ?= apache-apisix
project_release_name   ?= $(project_name)-$(VERSION)-src

OTEL_CONFIG ?= ./ci/pod/otelcol-contrib/data-otlp.json

# Hyperconverged Infrastructure
ENV_OS_NAME            ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
ENV_OS_ARCH            ?= $(shell uname -m | tr '[:upper:]' '[:lower:]')
ENV_APISIX             ?= $(CURDIR)/bin/apisix
ENV_GIT                ?= git
ENV_TAR                ?= tar
ENV_INSTALL            ?= install
ENV_RM                 ?= rm -vf
ENV_DOCKER             ?= docker
ENV_DOCKER_COMPOSE     ?= docker-compose --project-directory $(CURDIR) -p $(project_name) -f $(project_compose_ci)
ENV_NGINX              ?= $(ENV_NGINX_EXEC) -p $(CURDIR) -c $(CURDIR)/conf/nginx.conf
ENV_NGINX_EXEC         := $(shell command -v openresty 2>/dev/null || command -v nginx 2>/dev/null)
ENV_OPENSSL_PREFIX     ?= /usr/local/openresty/openssl3
ENV_LUAROCKS           ?= luarocks
## These variables can be injected by luarocks
ENV_INST_PREFIX        ?= /usr
ENV_INST_LUADIR        ?= $(ENV_INST_PREFIX)/share/lua/5.1
ENV_INST_BINDIR        ?= $(ENV_INST_PREFIX)/bin
ENV_HOMEBREW_PREFIX    ?= /usr/local
ENV_RUNTIME_VER	     ?= $(shell $(ENV_NGINX_EXEC) version 2>&1 | tr ' ' '\n'  | grep 'APISIX_RUNTIME_VER' | cut -d '=' -f2)

-include .requirements
export

ifneq ($(shell whoami), root)
	ENV_LUAROCKS_FLAG_LOCAL := --local
endif

ifdef ENV_LUAROCKS_SERVER
	ENV_LUAROCKS_SERVER_OPT := --server $(ENV_LUAROCKS_SERVER)
endif

ifneq ($(shell test -d $(ENV_OPENSSL_PREFIX) && echo -n yes), yes)
	ENV_NGINX_PREFIX := $(shell $(ENV_NGINX_EXEC) version 2>&1 | grep -Eo 'prefix=(.*)/nginx\s+' | grep -Eo '/.*/')
	ifeq ($(shell test -d $(addprefix $(ENV_NGINX_PREFIX), openssl3) && echo -n yes), yes)
		ENV_OPENSSL_PREFIX := $(addprefix $(ENV_NGINX_PREFIX), openssl3)
	endif
endif

# ENV patch for darwin
ifeq ($(ENV_OS_NAME), darwin)
	ifeq ($(ENV_OS_ARCH), arm64)
		ENV_HOMEBREW_PREFIX := /opt/homebrew
		ENV_INST_BINDIR := $(ENV_INST_PREFIX)/local/bin
		ENV_INST_LUADIR := $(shell which lua | xargs realpath | sed 's/bin\/lua//g')
	endif

	# OSX archive `._` cache file
	ENV_TAR      := COPYFILE_DISABLE=1 $(ENV_TAR)
	ENV_LUAROCKS := $(ENV_LUAROCKS) --lua-dir=$(ENV_HOMEBREW_PREFIX)/opt/lua@5.1

	ifeq ($(shell test -d $(ENV_HOMEBREW_PREFIX)/opt/openresty-openssl && echo -n yes), yes)
		ENV_OPENSSL_PREFIX := $(ENV_HOMEBREW_PREFIX)/opt/openresty-openssl
	endif
	ifeq ($(shell test -d $(ENV_HOMEBREW_PREFIX)/opt/openresty-openssl3 && echo -n yes), yes)
		ENV_OPENSSL_PREFIX := $(ENV_HOMEBREW_PREFIX)/opt/openresty-openssl3
	endif
	ifeq ($(shell test -d $(ENV_HOMEBREW_PREFIX)/opt/pcre && echo -n yes), yes)
		ENV_PCRE_PREFIX := $(ENV_HOMEBREW_PREFIX)/opt/pcre
	endif
endif


# Makefile basic extension function
_color_red    =\E[1;31m
_color_green  =\E[1;32m
_color_yellow =\E[1;33m
_color_blue   =\E[1;34m
_color_wipe   =\E[0m


define func_echo_status
	printf "[%b info %b] %s\n" "$(_color_blue)" "$(_color_wipe)" $(1)
endef


define func_echo_warn_status
	printf "[%b info %b] %s\n" "$(_color_yellow)" "$(_color_wipe)" $(1)
endef


define func_echo_success_status
	printf "[%b info %b] %s\n" "$(_color_green)" "$(_color_wipe)" $(1)
endef


define func_check_folder
	if [[ ! -d $(1) ]]; then \
		mkdir -p $(1); \
		$(call func_echo_status, 'folder check -> create `$(1)`'); \
	else \
		$(call func_echo_success_status, 'folder check -> found `$(1)`'); \
	fi
endef


### install-runtime : Installing dependencies install-runtime
.PHONY: install-runtime
install-runtime:
ifneq ($(ENV_RUNTIME_VER), $(APISIX_RUNTIME))
	./utils/install-dependencies.sh
	@sudo $(ENV_INSTALL) /usr/local/openresty/bin/openresty $(ENV_INST_BINDIR)/openresty
endif

.PHONY: uninstall-runtime
uninstall-runtime:
	./utils/install-dependencies.sh uninstall
	rm -rf /usr/local/openresty
	rm -f $(ENV_INST_BINDIR)/openresty
