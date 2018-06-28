FROM debian:jessie-slim

MAINTAINER William Hearn, william.hearn@canada.ca

RUN apt-get update && apt-get install -y curl tar git jq
RUN curl -Ls https://github.com/pachyderm/pachyderm/releases/download/v1.7.3/pachctl_1.7.3_linux_amd64.tar.gz | tar xzvf - -C /usr/local/bin/ --strip-components=1

ENTRYPOINT ["pachctl"]
CMD ["help"]
