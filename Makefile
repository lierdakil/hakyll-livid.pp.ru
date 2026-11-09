.PHONY: all deploy build watch rebuild clean

all: build

deploy: build
	hugo deploy --confirm

build:
	hugo build --cleanDestinationDir

watch:
	hugo server -M

clean:
	rm -rf public
