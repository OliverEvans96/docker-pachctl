FROM debian:jessie-slim

MAINTAINER William Hearn, william.hearn@canada.ca

RUN apt-get update && apt-get install -y curl tar git jq

RUN curl -Ls https://github.com/pachyderm/pachyderm/releases/download/v1.7.0rc2/pachctl_1.7.0rc2_linux_amd64.tar.gz | tar xzvf - -C /usr/local/bin/ --strip-components=1

# Temporary workaround for default envs
ENV KUBE_NAMESPACE=ci
ENV TILLER_NAMESPACE=ci

ENTRYPOINT ["pachctl"]
CMD ["help"]
