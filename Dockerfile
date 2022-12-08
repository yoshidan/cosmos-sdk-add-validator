FROM ignitehq/cli AS builder
ENTRYPOINT []

RUN /usr/bin/ignite scaffold chain hello
RUN cd hello && /usr/bin/ignite chain build

FROM busybox
WORKDIR /
COPY --from=builder /go/bin/hellod /usr/bin/hellod
CMD ["hellod"]
