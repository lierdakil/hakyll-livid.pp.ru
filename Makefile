define run
	nix-shell -p lessc --run "stack exec -- site $(1)"
endef
all: build

deploy: build
	$(call run, deploy)

build:
	$(call run, build)

rebuild:
	stack build
	$(call run, rebuild)

clean:
	$(call run, clean)
