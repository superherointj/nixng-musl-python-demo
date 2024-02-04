DEFAULT: container-nixng-musl

container-nixng-musl:
	docker image rm pydemo:latest || true
	nix build .#pydemo-container-nixng-musl
	ls -l -h $$(readlink -f ./result)
	cat ./result | docker load
	docker image ls pydemo:latest
	docker run --rm --cap-add=CAP_SYS_RESOURCE pydemo:latest

tree:
	nix build .#pydemo-toplevel-nixng-musl; nix-tree ./result
