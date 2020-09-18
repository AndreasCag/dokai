NAME?=dockai

GPUS?=all
ifeq ($(GPUS),none)
	GPUS_OPTION=
else
	GPUS_OPTION=--gpus=$(GPUS)
endif

.PHONY: all
all: stop build run

.PHONY: build
build:
	docker build -f ./docker/Dockerfile.base -t $(NAME):base .
	docker build -f ./docker/Dockerfile.pytorch -t $(NAME):pytorch .
	docker build -f ./docker/Dockerfile.tensor-stream -t $(NAME):tensor-stream .
	docker rm tensor-stream
	docker run $(GPUS_OPTION) --name=tensor-stream $(NAME):tensor-stream ./install_tensor_stream.sh
	docker commit tensor-stream $(NAME):tensor-stream

.PHONY: stop
stop:
	-docker stop $(NAME)
	-docker rm $(NAME)

.PHONY: run
run:
	docker run --rm -dit \
		$(GPUS_OPTION) \
		--net=host \
		--ipc=host \
		-v $(shell pwd):/workdir \
		--name=$(NAME) \
		$(NAME):tensor-stream \
		bash
	docker attach $(NAME)

.PHONY: attach
attach:
	docker attach $(NAME)

.PHONY: logs
logs:
	docker logs -f $(NAME)

.PHONY: exec
exec:
	docker exec -it $(NAME) bash
