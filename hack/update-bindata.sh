#!/bin/bash

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

set -o errexit
set -o pipefail

if [[ -z ${KUBE_ROOT} ]]; then
	echo "KUBE_ROOT not detected, setting default."
	KUBE_ROOT="../../../"
fi

set -o nounset

if [[ ! -d "${KUBE_ROOT}/examples" ]]; then
	echo "${KUBE_ROOT}/examples not detected.  This script should be run from a location where the source dirs are available."
	exit 1
fi

# Setup bindata if not already in the system.
# For separation of concerns, download first, then install later.
if ! git config -l | grep -q "user.name" && ! git config -l | grep -q "user.email" ; then
    git config --global user.name bindata-mockuser
    git config --global user.email bindata-mockuser@example.com
fi

go get -u github.com/jteeuwen/go-bindata/... || echo "go-bindata get failed, possibly already exists, proceeding"
go install github.com/jteeuwen/go-bindata/... || echo "go-bindata install may have failed, proceeding anyway..."

if [[ ! -f ${GOPATH}/bin/go-bindata ]]; then
	echo "missing bin/go-bindata"
	echo "for debugging, printing search for bindata files out..."
	find ${GOPATH} -name go-bindata
	exit 5
fi

BINDATA_OUTPUT="${KUBE_ROOT}/test/e2e/generated/bindata.go"
${GOPATH}/bin/go-bindata -nometadata -prefix "${KUBE_ROOT}" -o ${BINDATA_OUTPUT} -pkg generated \
	-ignore .jpg -ignore .png -ignore .md \
	"${KUBE_ROOT}/examples/..." \
	"${KUBE_ROOT}/docs/user-guide/..." \
	"${KUBE_ROOT}/test/e2e/testing-manifests/..." \
	"${KUBE_ROOT}/test/images/..."

gofmt -s -w ${BINDATA_OUTPUT}

echo "Generated bindata file : $(wc -l ${BINDATA_OUTPUT}) lines of lovely automated artifacts"
