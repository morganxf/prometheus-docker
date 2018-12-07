############################
# STEP 1 build executable binary
############################
FROM golang:1.11 AS builder

RUN mkdir -p $GOPATH/src/github.com/prometheus \
 && cd $GOPATH/src/github.com/prometheus \
 && git clone https://github.com/prometheus/prometheus.git

RUN cd $GOPATH/src/github.com/prometheus/prometheus \
 && make build \
 && mv prometheus promtool /$GOPATH/bin

############################
# STEP 2 build a small image
############################
FROM debian:stretch

# Copy our static executable and configuration.
COPY --from=builder /go/bin/prometheus /bin/prometheus
COPY --from=builder /go/bin/promtool /bin/promtool
COPY --from=builder /go/src/github.com/prometheus/prometheus/documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml
COPY --from=builder /go/src/github.com/prometheus/prometheus/console_libraries/ /etc/prometheus/
COPY --from=builder /go/src/github.com/prometheus/prometheus/consoles/ /etc/prometheus/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 9090

WORKDIR /prometheus

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/bin/prometheus", \
      "--config.file=/etc/prometheus/prometheus.yml", \
      "--storage.tsdb.path=/prometheus", \
      "--web.console.libraries=/etc/prometheus/console_libraries", \
      "--web.console.templates=/etc/prometheus/consoles", \
      "--web.enable-lifecycle" ]
