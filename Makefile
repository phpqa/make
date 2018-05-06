###
##. Configuration
###

THIS_MAKEFILE = $(lastword $(MAKEFILE_LIST))
THIS_MAKE = $(MAKE) --file $(THIS_MAKEFILE)

BUILD_DOCKERFILE_PATH = Dockerfile
BUILD_IMAGE_NAME = local/$(shell basename "$(shell pwd)")

TEST_COMMAND_FOR_VERSION = --version
TEST_COMMAND_WITH_FLAG = $(shell basename "$(shell pwd)") --version
TEST_FLAG_ONLY = --version

STYLE_RESET = \033[0m
STYLE_TITLE = \033[1;33m
STYLE_ERROR = \033[31m
STYLE_SUCCESS = \033[32m
STYLE_DIM = \033[2m

###
## About
###

.PHONY: help version
.DEFAULT_GOAL: help

# Print this documentation
help:

	@ \
		regexp=$$(                                                                                                     \
			$(THIS_MAKE) --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null                     \
			| awk '/^[a-zA-Z0-9_%-]+:/{ if (skipped) printf "|"; printf "^%s", $$1; skipped=1 }'                       \
		);                                                                                                             \
		awk -v pattern="$${regexp}" '                                                                                  \
			{ if (/^## /) { printf "\n%s\n",substr($$0,4); next } }                                                    \
			{ if ($$0 ~ pattern && doc) { gsub(/:.*/,"",$$1); printf "\033[36m%-40s\033[0m %s\n", $$1, doc; } }        \
			{ if (/^# /) { doc=substr($$0,3,match($$0"# TODO",/# TODO/)-3) } else { doc="No documentation" } }         \
			{ if (/^#\. /) { doc="" } }                                                                                \
			{ gsub(/#!/,"\xE2\x9D\x97 ",doc) }                                                                         \
		' $(THIS_MAKEFILE);
	@printf "\\n"

# Print the version
version:

	@date -r $(THIS_MAKEFILE) +"%d/%m/%Y %H:%M:%S"

###
## Build & Clean
###

.PHONY: master-branch-image clean-master-branch-image \
		tag-%-image clean-tag-%-image \
		docker-compose-test-image clean-docker-compose-test-image

# Build an image from the master branch
master-branch-image:

	@printf "$(STYLE_TITLE)Building an image from the master branch $(STYLE_RESET)\\n"
	@ \
		SOURCE_BRANCH="master" \
		SOURCE_COMMIT="this is not a commit" \
		COMMIT_MSG="this is not a commit message" \
		DOCKER_REPO="index.docker.io/$(BUILD_IMAGE_NAME)" \
		DOCKERFILE_PATH="Dockerfile" \
		CACHE_TAG="" \
		IMAGE_NAME="index.docker.io/$(BUILD_IMAGE_NAME):latest" \
		sh ./hooks/build

# Clean the image from the master branch
clean-master-branch-image:

	@printf "$(STYLE_TITLE)Removing the image from the master branch $(STYLE_RESET)\\n"
	@docker rmi $(BUILD_IMAGE_NAME):latest

# Build an image from the tag "%"
tag-%-image:

	$(eval $@_TAG := $(patsubst tag-%-image,%,$@))
	@printf "$(STYLE_TITLE)Building an image from the tag $($@_TAG) $(STYLE_RESET)\\n"
	@ \
		SOURCE_BRANCH="$($@_TAG)" \
		SOURCE_COMMIT="this is not a commit" \
		COMMIT_MSG="this is not a commit message" \
		DOCKER_REPO="index.docker.io/$(BUILD_IMAGE_NAME)" \
		DOCKERFILE_PATH="Dockerfile" \
		CACHE_TAG="" \
		IMAGE_NAME="index.docker.io/$(BUILD_IMAGE_NAME):$($@_TAG)" \
		sh ./hooks/build

# Clean the image from the tag "%"
clean-tag-%-image:

	$(eval $@_TAG := $(patsubst clean-tag-%-image,%,$@))
	@printf "$(STYLE_TITLE)Removing the image from the tag $($@_TAG) $(STYLE_RESET)\\n"
	@docker rmi $(BUILD_IMAGE_NAME):$($@_TAG)

# Build an image from the docker-compose.test.yml file
docker-compose-test-image:

	@printf "$(STYLE_TITLE)Building an image from the docker-compose.test.yml file $(STYLE_RESET)\\n"
	@docker-compose --file docker-compose.test.yml --project-name ci build

	@printf "$(STYLE_TITLE)Running the image from the docker-compose.test.yml file $(STYLE_RESET)\\n"
	@docker-compose --file docker-compose.test.yml --project-name ci --no-ansi up --detach
	@docker logs -f ci_sut_1

# Clean the image from the docker-compose.test.yml file
clean-docker-compose-test-image:

	@printf "$(STYLE_TITLE)Removing the image from the docker-compose.test.yml file $(STYLE_RESET)\\n"
	@docker-compose --file docker-compose.test.yml --project-name ci down --rmi all --volumes

###
## Tests
###

.PHONY: test-master-branch-image test-tag-%-image test-docker-compose-image \
		tests-verbose tests

status_after_run = ($(1) && printf '$(STYLE_SUCCESS)\342\234\224$(STYLE_RESET)\n') || (printf '$(STYLE_ERROR)\342\234\226$(STYLE_RESET)\n' && exit 1)

# Test the image from the master branch
test-master-branch-image: test-tag-latest-image

# Test the image from the tag "%"
test-tag-%-image:

	$(eval $@_TAG := $(patsubst test-tag-%-image,%,$@))
	$(eval $@_VERSION := $(shell echo $($@_TAG) | awk -F "-on-" '{print $1}'))

	@printf "$(STYLE_TITLE)Running tests for tag $($@_TAG) $(STYLE_RESET)\\n"

	@printf "Image was built: "
	@$(call status_after_run, test -n "$$(docker image ls $(BUILD_IMAGE_NAME):$($@_TAG) --quiet)")

	@printf "Image contains label \"org.label-schema.version\" with correct version: "
	@$(call status_after_run, \
		docker inspect --format "{{ index .Config.Labels \"org.label-schema.version\" }}" $$(docker images $(BUILD_IMAGE_NAME):$($@_TAG) --quiet) \
			| grep --quiet "\b$($@_LATEST_TAG)\b" \
	)

	@printf "Image contains label \"org.label-schema.docker.cmd\" with correct version: "
	@$(call status_after_run, \
		docker inspect --format "{{ index .Config.Labels \"org.label-schema.docker.cmd\" }}" $$(docker images $(BUILD_IMAGE_NAME):$($@_TAG) --quiet) \
			| grep --quiet "\b$($@_LATEST_TAG)\b" \
	)

	@printf "Container understands command with flag: "
	@$(call status_after_run, docker run --rm $(BUILD_IMAGE_NAME):$($@_TAG) $(TEST_COMMAND_WITH_FLAG) > /dev/null)

	@printf "Container understands only a flag: "
	@$(call status_after_run, docker run --rm $(BUILD_IMAGE_NAME):$($@_TAG) $(TEST_FLAG_ONLY) > /dev/null)

	@printf "Container understands other commands: "
	@$(call status_after_run, docker run --rm $(BUILD_IMAGE_NAME):$($@_TAG) test -x "$$(command -v ls)" > /dev/null)

	@printf "Container understands entrypoint override: "
	@$(call status_after_run, docker run --rm --entrypoint "" $(BUILD_IMAGE_NAME):$($@_TAG) ls "$$(command -v ls)" > /dev/null)

	@printf "Container returns correct version: "
	@$(call status_after_run, \
		docker run --rm $(BUILD_IMAGE_NAME):$($@_TAG) $(TEST_COMMAND_FOR_VERSION) \
			| head -n 1 | grep --quiet "$$(printf "$($@_VERSION)" | sed -n 's/\([0-9\.]*\).*/\1/p')" \
	)

# Test the image from the docker-compose.test.yml file
test-docker-compose-image:

	@printf "$(STYLE_TITLE)Running tests for docker-compose.test.yml $(STYLE_RESET)\\n"

	@printf "Container can run: "
	@$(call status_after_run, docker wait ci_sut_1 > /dev/null 2>&1)

	@printf "Container understands command with flag: "
	@$(call status_after_run, docker run --rm ci_sut $(TEST_COMMAND_WITH_FLAG) > /dev/null)

	@printf "Container understands only a flag: "
	@$(call status_after_run, docker run --rm ci_sut $(TEST_FLAG_ONLY) > /dev/null)

	@printf "Container understands other commands: "
	@$(call status_after_run, docker run --rm ci_sut test -x "$$(command -v ls)" > /dev/null)

	@printf "Container understands entrypoint override: "
	@$(call status_after_run, docker run --rm --entrypoint "" ci_sut ls "$$(command -v ls)" > /dev/null)

# Run all tests in verbose mode
tests-verbose:

	$(eval $@_VERSION := $(shell sed -n "s/ARG VERSION=\"\(.*\)\"/\1/p" Dockerfile))
	$(eval $@_BASE_IMAGE := $(shell sed -n "s/ARG BASE_IMAGE=\"\(.*\)\"/\1/p" Dockerfile | sed -e '1 s/:/-/; t'))
	$(eval $@_LATEST_TAG := $(shell printf "$($@_VERSION)-on-$($@_BASE_IMAGE)"))

	@$(THIS_MAKE) --quiet master-branch-image
	@$(THIS_MAKE) --quiet test-master-branch-image
	@$(THIS_MAKE) --quiet clean-master-branch-image

	@$(THIS_MAKE) --quiet tag-$($@_LATEST_TAG)-image
	@$(THIS_MAKE) --quiet test-tag-$($@_LATEST_TAG)-image
	@$(THIS_MAKE) --quiet clean-tag-$($@_LATEST_TAG)-image

	@$(THIS_MAKE) --quiet docker-compose-test-image
	@$(THIS_MAKE) --quiet test-docker-compose-image
	@$(THIS_MAKE) --quiet clean-docker-compose-test-image

# Run all tests
tests:

	$(eval $@_VERSION := $(shell sed -n "s/ARG VERSION=\"\(.*\)\"/\1/p" Dockerfile))
	$(eval $@_BASE_IMAGE := $(shell sed -n "s/ARG BASE_IMAGE=\"\(.*\)\"/\1/p" Dockerfile | sed -e '1 s/:/-/; t'))
	$(eval $@_LATEST_TAG := $(shell printf "$($@_VERSION)-on-$($@_BASE_IMAGE)"))

	@$(THIS_MAKE) --quiet master-branch-image 1> /dev/null
	@$(THIS_MAKE) --quiet test-master-branch-image
	@$(THIS_MAKE) --quiet clean-master-branch-image 1> /dev/null

	@$(THIS_MAKE) --quiet tag-$($@_LATEST_TAG)-image 1> /dev/null
	@$(THIS_MAKE) --quiet test-tag-$($@_LATEST_TAG)-image
	@$(THIS_MAKE) --quiet clean-tag-$($@_LATEST_TAG)-image 1> /dev/null

	@$(THIS_MAKE) --quiet docker-compose-test-image > /dev/null 2>&1
	@$(THIS_MAKE) --quiet test-docker-compose-image
	@$(THIS_MAKE) --quiet clean-docker-compose-test-image > /dev/null 2>&1





