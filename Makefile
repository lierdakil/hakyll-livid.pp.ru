define run
	nix shell nixpkgs#lessc -c bin/site $(1)
endef
all: build

deploy: build
	$(call run, deploy)

build:
	$(call run, build)

watch:
	$(call run, watch --port 8081)

rebuild:
	cabal install --installdir=$(PWD)/bin --install-method=copy
	$(call run, rebuild)

clean:
	$(call run, clean)
