SHELL := /bin/bash
.PHONY: all docker sim clean del_container

DOCKER_NAME := micromomcha

docker:
	if [ $$(docker ps -a -q -f name=$(DOCKER_NAME)) ]; then \
		echo "🔹 Container exists, starting it..."; \
		docker start -ai $(DOCKER_NAME); \
	else \
		echo "🔹 Creating new container..."; \
		docker build -t microwatt-secureboot:latest .; \
		docker run --name $(DOCKER_NAME) -it \
			-v $(PWD):/workspace \
			-w /workspace \
			microwatt-secureboot:latest /bin/bash; \
	fi
	
hex:
	make -C /workspace/firmware

sim:    hex
	chmod +x scripts/sim.sh
	./scripts/sim.sh run

clean:
	rm -rf work *.o sim.log sim.vcd tb_top
	(cd microwatt && make -f Makefile _clean)
	(cd firmware && make -f Makefile clean)

delete:	
	docker start $(DOCKER_NAME)
	docker exec $(DOCKER_NAME) /bin/bash -c "make clean"
	docker rm -f $(DOCKER_NAME)

