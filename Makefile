all: build

build: podman

buildah:
	export PATH=$PATH:/usr/sbin
	buildah build-using-dockerfile --tag rds-to-s3-crystal

podman:
	podman build . --tag rds-to-s3-crystal

crystal:
	shards build --release --no-debug --static --link-flags "-lxml2 -llzma"
	strip bin/bootstrap

crystal-debug:
	shards build --debug --static --link-flags "-lxml2 -llzma"

run: build
	podman run -t -p 6666:6666 rds-to-s3-crystal

bootstrap: build
	$(eval CONTAINER := $(shell podman run -d rds-to-s3-crystal false))
	podman cp $(CONTAINER):/app/bin/bootstrap .
	podman rm ${CONTAINER}
	zip bootstrap.zip bootstrap

clean:
	rm -f bootstrap
