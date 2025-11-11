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
	docker exec -it $(DOCKER_NAME) bash -c "cd /workspace/firmware && make"

sim:
	chmod +x scripts/sim.sh
	./scripts/sim.sh run

clean:
	rm -rf work ghdl-*.o sim.log sim.vcd

delete:
	docker rm -f $(DOCKER_NAME)

