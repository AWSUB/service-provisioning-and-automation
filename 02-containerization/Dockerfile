# Taken from https://github.com/GoogleContainerTools/distroless/blob/main/examples/go/Dockerfile

FROM golang as build

WORKDIR /go/src/app
COPY . .

RUN go mod download
RUN go vet -v
RUN go test -v

RUN CGO_ENABLED=0 go build -o /go/bin/app

FROM gcr.io/distroless/static-debian13

COPY --from=build /go/bin/app /
CMD ["/app"]