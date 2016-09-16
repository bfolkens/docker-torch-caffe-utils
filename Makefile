LOCAL_NAME=caffe-torch-conversion-utils
VERSION=latest
PUBLIC_NAME=caffe-torch-conversion-utils
REPOSITORY=bfolkens
DOCKER=sudo docker

.PHONY: all build tag release 

all: build

build:
	${DOCKER} build -t $(LOCAL_NAME):$(VERSION) --rm .

tag: build
	${DOCKER} tag $(LOCAL_NAME):$(VERSION) $(REPOSITORY)/$(PUBLIC_NAME):$(VERSION)

release: tag
	${DOCKER} push $(REPOSITORY)/$(PUBLIC_NAME):$(VERSION)

