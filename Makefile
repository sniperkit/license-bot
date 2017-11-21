PROJ=license-bot
ORG_PATH=github.com/yldio
REPO_PATH=$(ORG_PATH)/$(PROJ)
export PATH := $(PWD)/bin:$(PATH)

VERSION ?= '0.0.0'

DOCKER_REPO=quay.io/yldio/license-bot
DOCKER_IMAGE=$(DOCKER_REPO):$(VERSION)

$( shell mkdir -p bin )

user=$(shell id -u -n)
group=$(shell id -g -n)

export GOBIN=$(PWD)/bin

LD_FLAGS=-w -X $(REPO_PATH)/version.Version=$(VERSION)
REL_LD_FLAGS=-s $(LD_FLAGS)

build: bin/license-bot.dev

bin/license-bot.dev:
	@go build -o bin/license-bot.dev -v -ldflags "$(LD_FLAGS)" $(REPO_PATH)

.PHONY: release-binary
release-binary:
	@go build -o bin/license-bot -v -ldflags "$(REL_LD_FLAGS)" $(REPO_PATH)

.PHONY: revendor
revendor:
	@dep ensure --update

test:
	@go test -v -i $(shell go list ./... | grep -v '/vendor/')
	@go test -v $(shell go list ./... | grep -v '/vendor/')

testrace:
	@go test -v -i --race $(shell go list ./... | grep -v '/vendor/')
	@go test -v --race $(shell go list ./... | grep -v '/vendor/')

vet:
	@go vet $(shell go list ./... | grep -v '/vendor/')

fmt:
	@go fmt $(shell go list ./... | grep -v '/vendor/')

lint:
	@for package in $(shell go list ./... | grep -v '/vendor/' | grep -v '/api' | grep -v '/server/internal'); do \
      golint -set_exit_status $$package $$i || exit 1; \
	done

.PHONY: docker-image
docker-image:
	@docker build -t $(DOCKER_IMAGE) .

clean:
	@rm -rf bin/

testall: testrace vet fmt lint

FORCE:

.PHONY: test testrace vet fmt lint testall
