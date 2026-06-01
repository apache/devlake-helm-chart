## How to upgrade helm chart after releasing new devlake images

1. In [values.yaml](https://github.com/apache/devlake-helm-chart/blob/main/charts/devlake/values.yaml), change {{ imageTag }} to current image tag
2. In [chart.yaml](https://github.com/apache/devlake-helm-chart/blob/main/charts/devlake/Chart.yaml), change {{ version }}, {{ appVersion }} to current image tag
3. If we want to release a new chart without new release of devlake, we should increase both chart version and image tag.
   - For example, right now both versions are 0.16.1-beta1, if we make change on chart, we should set chart-version to 0.16.1-beta1, also, we need to crate new images for devlake with tag 0.16.1-beta1
4. If we release any new image for devlake, we just need to set a new version for chart.

