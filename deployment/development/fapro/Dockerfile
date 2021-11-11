FROM docker.io/alpine:3.13 AS tmpimg

WORKDIR /tmp/
RUN wget https://github.com/fofapro/fapro/releases/latest/download/fapro_linux_x86_64.tar.gz -O fapro.tgz
RUN tar -xvf fapro.tgz
COPY ./entrypoint.sh /tmp/entrypoint.sh
RUN dos2unix /tmp/entrypoint.sh
RUN chmod a+x /tmp/entrypoint.sh

FROM docker.io/ubuntu:20.04

COPY --from=tmpimg /tmp/fapro /opt/fapro/
COPY --from=tmpimg /tmp/entrypoint.sh /bin/entrypoint.sh

WORKDIR /opt/fapro
ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["/opt/fapro/fapro", "run", "--verbose"]
