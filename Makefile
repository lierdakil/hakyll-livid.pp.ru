.PHONY: all deploy build watch rebuild clean

all: build

deploy: build
	rclone sync ./_site/ weed:static-sites/livid.pp.ru/

build:
	hugo build --cleanDestinationDir

watch:
	hugo server -M

clean:
	rm -rf public
