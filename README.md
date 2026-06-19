# Apache Incubator DevLake Helm Chart

<!--
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
-->

Thanks to @matrixji who initiated all content in `apache/devlake`, this repo is copied from directory deployment/helm in repo `apache/devlake`! Also thanks to @lshmouse, @shubham-cmyk and @SnowMoon-Dev for the contribution for devlake helm deployment.

## Install

1. Install the latest stable version with release name `devlake`

```shell
helm repo add devlake https://apache.github.io/devlake-helm-chart
helm repo update
ENCRYPTION_SECRET=$(openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1)
helm install devlake devlake/devlake --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

2. Install the latest development version with release name `devlake`:

```shell
helm repo add devlake https://apache.github.io/devlake-helm-chart
helm repo update
ENCRYPTION_SECRET=$(openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1)
helm install devlake devlake/devlake --version=1.0.3-beta13 --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

Helm chart are also published to GitHub container registry as OCI artifact.

If you are using minikube inside your mac, please use the following command to forward the port:

```shell
kubectl port-forward service/devlake-ui  30090:4000
```

and open another terminal:

```shell
kubectl port-forward service/devlake-grafana  30091:3000
```

Then you can visit:
config-ui by url `http://YOUR-NODE-IP:30090`
grafana by url `http://YOUR-NODE-IP:30091`

## Upgrade

**Note:**

**If you're upgrading from DevLake v0.17.x or earlier versions to v0.18.x or later versions:**

1. Copy the ENCODE_KEY value from /app/config/.env of the lake pod (e.g. devlake-lake-0), and replace the <ENCRYPTION_SECRET> in the upgrade command below.

2. You may encounter the below error when upgrading because the built-in grafana has been replaced by the official grafana dependency. So you may need to delete the grafana deployment first.

> Error: UPGRADE FAILED: cannot patch "devlake-grafana" with kind Deployment: Deployment.apps "devlake-grafana" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/instance":"devlake", "app.kubernetes.io/name":"grafana"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable

```shell
helm repo update
helm upgrade devlake devlake/devlake --version=1.0.3-beta13 --set lake.encryptionSecret.secret=<ENCRYPTION_SECRET>
```

**If you're upgrading from DevLake v0.18.x or later versions:**

```shell
helm repo update
helm upgrade devlake devlake/devlake --version=1.0.3-beta13
```

## Uninstall

To uninstall/delete the `devlake` release:

```shell
helm uninstall devlake
```

## Original pr in apache/devlake

https://github.com/apache/devlake/pulls?q=is%3Apr+helm+is%3Aclosed

## More

You could find more examples and details in [HelmSetup.md](HelmSetup.md)
