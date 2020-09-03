## Datapower V10 Tekton Deployment
Tekton assets for deploying an instance of the operator based DataPower V10.


## Setup Pipeline

* Use `oc` to log into Openshift as user with ability to create related pipeline, secrets, routes, rolebindings, and other resources (e.g. cluster-admin user)

* Edit pipeline-setup.sh and fill in required variables
    ```
    ...
    # Insert your Git Access Token below
    GIT_TOKEN=<git-token>

    # Insert your Git UserName here
    GIT_USERNAME=dp-build-bot

    # Insert DP Password here
    DP_PASSWORD=<admin-dp-pw>
    ...
    ```

* Change the url in "git-repo-resource.yaml" in tekton directory to point to your own repo

* Run the setup script. This creates a new service-account and namespace for the pipeline to run. Deployment target namespace should already exist with datapower operator installed.
    ```
    # The arguments needed:
    ./pipeline-setup.sh <pipeline-serviceaccount-name> <pipeline-namespace> <datapower-deployment-target-ns>
    
    ./pipeline-setup.sh dp-deploy-sa dp-pipeline dp
    ```
* The trigger route needs to be created for the event listener service, and the new route will need to be added to Github webhooks to receive push events

* (Optional) If you called your service account with a name different than `dp-deploy-sa`, be sure to update it in the `./tekton/trigger.yaml` file. Also, you may want to change the pipeline `TriggerTemplate` with the service account name, or deploy a different configuration subdirectory.

    ```
    ...
    kind: EventListener
    metadata:
      name: dp-cicd
    spec:
      serviceAccountName: dp-deploy-sa
    ...

    and 

    ...
    resourcetemplates:
      - apiVersion: tekton.dev/v1alpha1
        kind: PipelineRun
        metadata:
          generateName: dp-cicd-run-
        spec:
          params:
          - name: TARGET_NAMESPACE
            value: dp
          - name: RELEASE_NAME
            value: dp-basic
          - name: DP_WORKSPACE_DIR
            value: dp/basic
          pipelineRef:
            name: deploy-dp-pipeline
          resources:
          - name: git-input-source
            resourceSpec:
              type: git
              params:
                - name: revision
                  value: $(params.gitrevision)
                - name: url
                  value: $(params.gitrepositoryurl)
          serviceAccountName: dp-deploy-sa
    ...
    ```
  
## Start Run

```
# Start a pipeline run to deploy and pass in custom configuration parameters 
tkn pipeline start deploy-dp-pipeline \
--serviceaccount dp-deploy-sa \
--param TARGET_NAMESPACE=dp \
--param RELEASE_NAME=dp-basic \
--param DP_WORKSPACE_DIR='dp/basic' \
--resource git-input-source=git-repo \
-n dp-pipeline

or the equivalent with oc/kubectl 

cat <<EOF | kubectl create -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  creationTimestamp: null
  generateName: deploy-dp-pipeline-run-
  namespace: dp-pipeline
spec:
  params:
  - name: TARGET_NAMESPACE
    value: dp
  - name: RELEASE_NAME
    value: dp-basic
  - name: DP_WORKSPACE_DIR
    value: dp/basic
  pipelineRef:
    name: deploy-dp-pipeline
  resources:
  - name: git-input-source
    resourceRef:
      name: git-repo
  serviceAccountName: dp-deploy-sa
EOF
```
