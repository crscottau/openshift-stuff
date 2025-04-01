# oc mirror container

## Build

```
$ TAG=1.1
$ build -f Containerfile -t container-tools-with-oc-mirror:${TAG} .
```

## Run

```
$ podman run --name oc-mirror --rm --privileged --net=host -it -v ~/.docker/config.json:/root/.docker/config.json:Z -v .:/tmp:Z container-tools-with-oc-mirror:1.1 oc-mirror --config=/tmp/imageset-config.yaml file:///tmp/mirror
```

## Push

