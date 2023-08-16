define run
	nix shell nixpkgs#lessc -c bin/site $(1)
endef

.PHONY: all deploy build watch rebuild clean

all: build

deploy: build
	git push
	rsync -avcz -e ssh --rsync-path="sudo rsync" ./_site/ chaya:/var/www/livid.pp.ru/htdocs/

build:
	$(call run, build)

watch:
	$(call run, watch --port 8081)

rebuild:
	cabal install --installdir=$(PWD)/bin --install-method=copy
	$(call run, rebuild)

clean:
	$(call run, clean)
