PROJECT_ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Build environment defined by ./Dockerfile. Override BASE_IMAGE to compile
# against a different Amazon Linux base instead of editing the Dockerfile.
BASE_IMAGE ?= public.ecr.aws/amazonlinux/amazonlinux:2023
DOCKER_IMAGE ?= imagemagick-lambda-build
# Lambda layers are architecture specific. Pinning the platform stops an arm64
# development machine from silently producing a layer that x86_64 functions
# cannot load.
DOCKER_PLATFORM ?= linux/amd64
TARGET ?=/opt/

MOUNTS = -v $(PROJECT_ROOT):/var/task \
	-v $(PROJECT_ROOT)result:$(TARGET)

DOCKER = docker run --platform=$(DOCKER_PLATFORM) -t --rm -w=/var/task/build

.PHONY: image all libs clean list-formats bash

image:
	docker build --platform=$(DOCKER_PLATFORM) --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(DOCKER_IMAGE) $(PROJECT_ROOT)

build result:
	mkdir $@

clean:
	rm -rf build result

list-formats: image
	$(DOCKER) $(MOUNTS) --entrypoint /opt/bin/identify -t $(DOCKER_IMAGE) -list format

bash: image
	$(DOCKER) -i $(MOUNTS) --entrypoint /bin/bash -t $(DOCKER_IMAGE)

all libs: image
	$(DOCKER) $(MOUNTS) --entrypoint /usr/bin/make -t $(DOCKER_IMAGE) TARGET_DIR=$(TARGET) -f ../Makefile_ImageMagick $@


STACK_NAME ?= imagemagick-layer 

result/bin/identify: all

/tmp/layer.zip: result/bin/identify build
	# imagemagick has a ton of symlinks, and just using the source dir in the template
	# would cause all these to get packaged as individual files. 
	# (https://github.com/aws/aws-cli/issues/2900) 
	#
	# This is why we zip outside, using -y to store them as symlinks
	
	cd result && zip -ry $@ *

/tmp/output.yaml: cleanup template.yaml /tmp/layer.zip
	aws cloudformation package --template template.yaml --s3-bucket $(DEPLOYMENT_BUCKET) --output-template-file $@

deploy: /tmp/output.yaml
	aws cloudformation deploy --template $< --stack-name $(STACK_NAME)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

deploy-example: deploy
	cd example && \
		make deploy DEPLOYMENT_BUCKET=$(DEPLOYMENT_BUCKET) IMAGE_MAGICK_STACK_NAME=$(STACK_NAME)

cleanup:
	@echo cleaning up old files
	rm -rf /tmp/output.yaml /tmp/layer.zip
