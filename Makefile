all: build deploy

deploy:
	./site deploy

build:
	./site build

rebuild:
	cabal build
	./site rebuild
