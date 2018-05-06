BUILD_DOCKERFILE_PATH = Dockerfile
BUILD_IMAGE_NAME = phpqa/make

TEST_COMMAND = make
TEST_FLAG = --version

STYLE_RESET = \033[0m
STYLE_TITLE = \033[1;33m
STYLE_ERROR = \033[31m
STYLE_DIM = \033[2m

.PHONY: build test

build:

	@ \
		export DOCKERFILE_PATH=$(BUILD_DOCKERFILE_PATH); \
		export IMAGE_NAME=$(BUILD_IMAGE_NAME); \
		sh ./hooks/build

test:

	@printf "$(STYLE_TITLE)Building image as ci_sut $(STYLE_RESET)\\n"
	@docker-compose --file docker-compose.test.yml --project-name ci build

	@printf "$(STYLE_TITLE)Checking if container can run $(STYLE_RESET)\\n"
	@docker-compose --file docker-compose.test.yml --project-name ci up -d
	@docker logs -f ci_sut_1
	@exit $$(docker wait ci_sut_1)

	@printf "$(STYLE_TITLE)Testing if container understands flag only $(STYLE_RESET)\\n"
	@(docker run --rm ci_sut $(TEST_FLAG) > /dev/null && printf '\342\234\224\n') || printf '\342\234\226\n'

	@printf "$(STYLE_TITLE)Testing if container understands command and flag $(STYLE_RESET)\\n"
	@(docker run --rm ci_sut $(TEST_COMMAND) $(TEST_FLAG) > /dev/null && printf '\342\234\224\n') || printf '\342\234\226\n'

	@printf "$(STYLE_TITLE)Testing if container understands other commands $(STYLE_RESET)\\n"
	@(docker run --rm ci_sut test -x "$$(command -v $(TEST_COMMAND))" > /dev/null && printf '\342\234\224\n') || printf '\342\234\226\n'

	@printf "$(STYLE_TITLE)Testing if container understands entrypoint override $(STYLE_RESET)\\n"
	@(docker run --rm --entrypoint "" ci_sut ls "$$(command -v $(TEST_COMMAND))" > /dev/null && printf '\342\234\224\n') || printf '\342\234\226\n'

	@printf "$(STYLE_TITLE)Removing image $(STYLE_RESET)\\n"
	@docker-compose --file docker-compose.test.yml --project-name ci down --rmi all --volumes
