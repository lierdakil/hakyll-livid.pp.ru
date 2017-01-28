all: deploy

deploy: build
	stack exec -- site deploy

build:
	stack exec -- site build

rebuild:
	stack build
	stack exec -- site rebuild
