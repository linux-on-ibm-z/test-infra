#!/usr/bin/env bash
# Copyright 2018 The Kubernetes Authors.
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

set -o errexit
set -o nounset
set -o pipefail

# get test-infra for latest bootstrap etc
git clone https://github.com/kubernetes/test-infra
#BOOTSTRAP_UPLOAD_BUCKET_PATH=${BOOTSTRAP_UPLOAD_BUCKET_PATH:-"gs://kubernetes-jenkins/logs"}

# actually start bootstrap and the job, under the runner (which handles dind etc.)
export JOB=${JOB:-"kubernetes-integration"}
export REPO=${REPO:-"k8s.io/kubernetes=$(curl --silent "https://api.github.com/repos/kubernetes/kubernetes/releases/latest" | jq -r .tag_name)"}
if [[ $JOB == "kubernetes-integration"* ]]; then
        sed -i 's/^{/{"kubernetes-integration":{},/' test-infra/jobs/config.json
        /usr/local/bin/runner.sh \
                ./test-infra/jenkins/bootstrap.py \
                --job=${JOB} \
                --repo=${REPO} \
                --root=/go/src \
                --scenario=execute -- bash -- -c 'sed -i "s/--timeout=120/--timeout=300/" hack/make-rules/test.sh && sed -i "s/export KUBE_RACE/#export KUBE_RACE/" ./hack/jenkins/test-dockerized.sh && sed -i "s/WORKSPACE/PWD/" ./hack/jenkins/test-dockerized.sh && sed -i "/install-etcd/d" ./hack/jenkins/test-dockerized.sh && sed -i "s|k8s.gcr.io/serve_hostname|gcr.io/kubernetes-e2e-test-images/serve-hostname-s390x:1.2|" test/fixtures/doc-yaml/admin/limitrange/valid-pod.yaml && sed -i "s/make test-integration/make test-integration KUBE_TEST_ARGS=\"-p 1\"/" ./hack/jenkins/test-dockerized.sh && sed -i "s/exceeded/or context cancellation/" $GOPATH/src/k8s.io/kubernetes/test/cmd/request-timeout.sh && ./hack/jenkins/test-dockerized.sh' \
        "$@"
fi


## changes on master
# export JOB=${JOB:-"kubernetes-integration"}
# export REPO=${REPO:-"k8s.io/kubernetes=$(curl --silent "https://api.github.com/repos/kubernetes/kubernetes/releases/latest" | jq -r .tag_name)"}
# if [[ $JOB == "kubernetes-integration"* ]]; then
#         sed -i 's/^{/{"kubernetes-integration":{},/' test-infra/jobs/config.json
#         /usr/local/bin/runner.sh \
#                 ./test-infra/jenkins/bootstrap.py \
#                 --job=${JOB} \
#                 --repo=${REPO} \
#                 --root=/go/src \
#                 --scenario=execute -- bash -- -c 'sed -i "s/--timeout=120/--timeout=300/" hack/make-rules/test.sh && sed -i "s/export KUBE_RACE/#export KUBE_RACE/" ./hack/jenkins/test-dockerized.sh && sed -i "s/WORKSPACE/PWD/" ./hack/jenkins/test-dockerized.sh && sed -i "/install-etcd/d" ./hack/jenkins/test-dockerized.sh && sed -i "s|k8s.gcr.io/serve_hostname|gcr.io/kubernetes-e2e-test-images/serve-hostname-s390x:1.2|" test/fixtures/doc-yaml/admin/limitrange/valid-pod.yaml && sed -i "s/make test-integration/make test-integration KUBE_TEST_ARGS=\"-p 1\"/" ./hack/jenkins/test-dockerized.sh && ./hack/jenkins/test-dockerized.sh' \
#         "$@"
# fi
