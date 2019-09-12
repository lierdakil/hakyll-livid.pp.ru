define run
	nix-shell -p lessc --run "cabal run -- site $(1)"
endef
all: build

deploy: build
	$(call run, deploy)

build:
	$(call run, build)

watch:
	$(call run, watch --port 8081)

rebuild:
	cabal build
	$(call run, rebuild)

clean:
	$(call run, clean)
