## Datapower V10 Tekton Deployment

Tekton assets for deploying an instance of the operator based DataPower V10.


### Run

```
# Log into Openshift

# ./pipeline-setup.sh <pipeline-sa-name> <pipeline-namespace> <datapower deployment-target-ns>
./pipeline-setup.sh dp-deploy-sa dp-pipeline cp4i


# Start a pipeline run to deploy

tkn pipeline start deploy-dp-pipeline --serviceaccount dp-deploy-sa --param TARGET_NAMESPACE=cp4i --param RELEASE_NAME=dp-rel-ws --param DP_WORKSPACE_DIR='dp/fin-app-ws' --resource git-input-source=git-repo
```