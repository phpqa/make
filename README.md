# Make on Alpine/Docker

This image provides a way to run the latest make commands from docker.
 
For example using the -j flag to run multiple jobs in parallel:

```
docker run --rm \
    --tty \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    phpqa/make --file Makefile -j --output-sync=target --ignore-errors --quiet target1 target2 target3 
```
