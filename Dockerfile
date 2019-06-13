FROM debian:jessie-slim

MAINTAINER William Hearn, william.hearn@canada.ca

RUN apt-get update && apt-get install -y curl tar git jq
RUN curl -o /tmp/pachctl.deb -L https://github.com/pachyderm/pachyderm/releases/download/v1.8.7/pachctl_1.8.7_amd64.deb && sudo dpkg -i /tmp/pachctl.deb

ENTRYPOINT ["pachctl"]
CMD ["help"]
