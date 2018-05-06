# Make on Alpine/Docker

This image provides a way to run the latest make version with docker.
 
For example, Make 4 adds the -j flag, which makes it possible to run multiple jobs in parallel:

```
docker run --rm --tty --volume ${PWD}:/app --workdir /app \
    phpqa/make --file Makefile -j --output-sync=target --ignore-errors --quiet target1 target2 target3 
```
