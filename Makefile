.PHONY: all deploy build watch rebuild clean

all: build

deploy: build
	git push
	rclone sync ./_site/ weed:static-sites/livid.pp.ru/

build:
	nix build .
	nix run . -- build

watch:
	nix run . -- watch --port --8081

clean:
	nix run . -- clean
