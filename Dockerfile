FROM balenalib/aarch64-debian:sid

RUN apt-get update -q \
  && apt-get install --no-install-recommends -qy build-essential python3-dev python3-pip python3-setuptools \
  && pip3 install twine wheel \
  && rm -rf /var/lib/apt/lists/*

COPY [ "Makefile", "/packages/" ]

VOLUME /packages
WORKDIR /packages
CMD [ "make" ]
