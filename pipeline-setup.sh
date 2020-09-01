#!/bin/bash

# Example call
# ./pipeline-setup.sh <choose-service-account-name> <pipeline-namespace> <dp-target-namespace>
# ./pipeline-setup.sh dp-deploy-sa dp-pipeline cp4i

# Make sure arguments exist
if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
    echo "Not enough arguments supplied."
    echo './pipeline-setup.sh <choose-service-account-name> <pipeline-namespace> <dp-target-namespace>'
    echo "The target deployment namespaces should have the DataPower Operator already installed."
    echo ""
    exit 1
fi

PIPELINE_SA=$1
PIPELINE_NS=$2
TARGET_NS=$3

GIT_SECRET_NAME=dp-git-secret

# Insert your Git Access Token below
GIT_TOKEN=<git-token>

# Insert your Git UserName here
GIT_USERNAME=dp-build-bot

# Insert DP Password here
DP_PASSWORD=<admin-dp-pw>

# Create the pipeline namespace
oc new-project $PIPELINE_NS

# Change to the new namespace
oc project $PIPELINE_NS

# create the git secret
oc secret new-basicauth $GIT_SECRET_NAME --username=$GIT_USERNAME --password $GIT_TOKEN

# create dp secret
oc create secret generic dp-admin-credentials --from-literal=password=$DP_PASSWORD -n $TARGET_NS

# annotate the secret
oc annotate secret $GIT_SECRET_NAME tekton.dev/git-0=github.com

# create serviceaccount to run the pipeline and associate the git secret with the serviceaccount
oc apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $PIPELINE_SA
secrets:
- name: $GIT_SECRET_NAME
EOF

# Create these ClusterRoleBindings
oc create clusterrolebinding dp-pipelinetektonpipelinesadminbinding --clusterrole=tekton-pipelines-admin --serviceaccount=$PIPELINE_NS:$PIPELINE_SA
oc create clusterrolebinding dp-pipelinetektontriggersadminbinding --clusterrole=tekton-triggers-admin --serviceaccount=$PIPELINE_NS:$PIPELINE_SA

oc create clusterrolebinding dp-pipelinepullerbinding --clusterrole=system:image-puller --serviceaccount=$PIPELINE_NS:$PIPELINE_SA
oc create clusterrolebinding dp-pipelinebuilderinding --clusterrole=system:image-builder --serviceaccount=$PIPELINE_NS:$PIPELINE_SA

oc create clusterrolebinding dp-pipelineqmeditbinding --clusterrole=datapowerservices.datapower.ibm.com-v1beta1-edit --serviceaccount=$PIPELINE_NS:$PIPELINE_SA
oc create clusterrolebinding dp-pipelineqmviewbinding --clusterrole=datapowerservices.datapower.ibm.com-v1beta1-view --serviceaccount=$PIPELINE_NS:$PIPELINE_SA

oc create rolebinding dp-pipeline-admin --clusterrole=admin --serviceaccount=$PIPELINE_NS:$PIPELINE_SA -n $TARGET_NS

oc create clusterrolebinding dp-pipelineviewerbinding --clusterrole=view --serviceaccount=$PIPELINE_NS:$PIPELINE_SA

# Add the serviceaccount to privileged SecurityContextConstraint
oc adm policy add-scc-to-user privileged system:serviceaccount:$PIPELINE_NS:$PIPELINE_SA


# Add tekton resources
oc apply -f ./tekton/
