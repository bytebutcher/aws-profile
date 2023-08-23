# Developer Guide

## Testing

To avoid side-effects, tests can only be run inside a Docker container.

**Build Docker Image:**
```
docker build -t bytebutcher/aws-profile .
```

**Run tests:**
```
docker run --rm -it bytebutcher/aws-profile test
```
