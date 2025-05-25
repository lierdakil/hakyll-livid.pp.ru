.PHONY: all deploy build watch rebuild clean

all: build

deploy: build
	git push
	rsync -avcz -e ssh --delete --rsync-path="sudo rsync" ./_site/ chaya:/var/www/livid.pp.ru/htdocs/

build:
	nix build .
	nix run . -- build

watch:
	nix run . -- watch --port --8081

clean:
	nix run . -- clean
