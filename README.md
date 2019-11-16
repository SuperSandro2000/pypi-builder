# PyPi builder

This repo is used to build arm64 pypi wheels for https://pypi.supersandro.de/

## Dockerimage

To build in the Docker Image run ``sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`` before.

*NOTE* Building on an emulator is quite slow and not recommended. Real hardware, even a Raspberry Pi 3b, is way faster!
