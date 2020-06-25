# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file creates a build environment for building and running kubernetes
# unit and integration tests

ARG OLD_BAZEL_VERSION=0.23.2
FROM launcher.gcr.io/google/bazel:${OLD_BAZEL_VERSION} as old
FROM gcr.io/k8s-testimages/bootstrap:v20200430-be2a8a9

# hint to kubetest that it is in CI
ENV KUBETEST_IN_DOCKER="true"

# Go standard envs
ENV GOPATH /go 
ENV PATH /usr/local/go/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-s390x PATH=$JAVA_HOME/bin:$PATH

RUN mkdir -p /go/bin
ENV PATH $GOPATH/bin:$PATH

# setup k8s repo symlink
RUN mkdir -p /go/src/k8s.io/kubernetes \
    && ln -s /go/src/k8s.io/kubernetes /workspace/kubernetes

# preinstall:
# - graphviz package for graphing profiles
# - bc for shell to junit
# - rpm for building RPMs with Bazel
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential openjdk-11-jdk python3 zip unzip wget \
    bc git \
    graphviz \
    rpm && \
    rm -rf /var/lib/apt/lists/*
# preinstall this for kops tests xref kubetest prepareAws(...)
# TODO(krzyzacy,justisb,chrislovecnm): remove this
RUN pip install awscli

# replace kubectl with one from K8S_RELEASE
ARG K8S_RELEASE=latest
RUN rm -f $(which kubectl) && \
    export KUBECTL_VERSION=$(curl https://storage.googleapis.com/kubernetes-release/release/${K8S_RELEASE}.txt) && \
    wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/s390x/kubectl -O /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# install go
ARG GO_VERSION=1.13.5
ENV GO_TARBALL "go${GO_VERSION}.linux-s390x.tar.gz"
RUN wget -q "https://storage.googleapis.com/golang/${GO_TARBALL}" && \
    tar xzf "${GO_TARBALL}" -C /usr/local && \
    rm "${GO_TARBALL}"

# install cfssl to prevent https://github.com/kubernetes/kubernetes/issues/55589
# The invocation at the end is to prevent download failures downloads as in the bug.
# TODO(porridge): bump CFSSL_VERSION to one where cfssljson supports the -version flag and test it as well.
ARG CFSSL_VERSION
RUN mkdir -p $GOPATH/src/github.com/cloudflare \
    && cd $GOPATH/src/github.com/cloudflare && git clone https://github.com/cloudflare/cfssl.git \
    && cd cfssl && git checkout 1.2.0 \
    && go install github.com/cloudflare/cfssl/cmd/... \
    && mv $GOPATH/bin/cfssl $GOPATH/bin/cfssljson /usr/local/bin \
    && cfssl version \
# Install bazel
    && cd /opt \
    && mkdir bazel && cd bazel \
    && wget https://github.com/bazelbuild/bazel/releases/download/2.2.0/bazel-2.2.0-dist.zip \
    && unzip bazel-2.2.0-dist.zip \
    && chmod -R +w . \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && sed -i '472i"//src/conditions:linux_s390x": "*.so *.jnilib *.dll",' third_party/BUILD  \
	&& sed -i '167i\\t"//src/conditions:linux_s390x": ["@bazel_tools//tools/jdk:jni_md_header-linux"],' src/main/java/com/google/devtools/build/lib/syntax/BUILD \
    && sed -i '176i\\t"//src/conditions:linux_s390x": ["../../../../../../../../../external/bazel_tools/tools/jdk/include/linux"],' src/main/java/com/google/devtools/build/lib/syntax/BUILD \
    && sed -i "152/-classpath/-J-Xms1g -J-Xmx1g -classpath/" scripts/bootstrap/compile.sh \
    && sed -i "69s/javac/javac -J-Xms1g -J-Xmx1g/" tools/build_rules/java_rules_skylark.bzl

COPY --from=old \
    /usr/local/bin/bazel /usr/local/lib/bazel/bin/bazel-${OLD_BAZEL_VERSION}

# if UPGRADE_DOCKER_ARG, then install the latest docker over whatever we have
# in the base image.
# TODO: after code freeze, roll out newer docker in the
# base image and possibly remove this ...
ARG UPGRADE_DOCKER_ARG=false
RUN [ "${UPGRADE_DOCKER_ARG}" = "true" ] && \
    apt-get install -y --no-install-recommends docker-ce && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's/cgroupfs_mount$/#cgroupfs_mount\n/' /etc/init.d/docker || true

# add env we can debug with the image name:tag
ARG IMAGE_ARG
ENV IMAGE=${IMAGE_ARG}

# everything below will be triggered on every new image tag ...
ADD ["kops-e2e-runner.sh", \
    "kubetest", \
    "https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/get-kube.sh", \
    "/workspace/"]
RUN ["chmod", "+x", "/workspace/get-kube.sh"]
