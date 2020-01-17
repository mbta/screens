#!/bin/bash
set -e -x -u

# bash script should be called with aws environment (e.g.: ./semaphore/deploy.sh dev)
# other required configuration:
# * APP
# * DOCKER_REPO

function get_running_taskdef_arns() {
  # returns an array of the task definition ARNs for each running task in the cluster, or "none"
  runningtasks="$(aws ecs list-tasks --region us-east-1 --cluster $APP --service-name $awsenv --desired-status RUNNING | jq -r '.taskArns[]')"
  if [ "${runningtasks}" != "" ]; then
    echo "$(aws ecs describe-tasks --region us-east-1 --cluster $APP --tasks $runningtasks | jq -r -c '.tasks | map(.taskDefinitionArn)')"
  else
    echo "none"
  fi
}

awsenv=$APP-$1

githash=$(git rev-parse --short HEAD)
gitmsg=$(git log -1 --pretty=%s)

# ensure the image exists on AWS. This command will fail if it does not.
aws ecr describe-images --region us-east-1 --repository-name $APP --image-ids "imageTag=git-$githash"

# get JSON describing task definition currently running on AWS
# use it as basis for new revision, but replace image with the one built above
taskdefinition=$(aws ecs describe-task-definition --region us-east-1 --task-definition $awsenv)
taskdefinition=$(echo $taskdefinition | jq ".taskDefinition | del(.status) | del(.taskDefinitionArn) | del(.requiresAttributes) | del(.revision) | del(.compatibilities)")
newcontainers=$(echo $taskdefinition | jq ".containerDefinitions | map(.image=\"$DOCKER_REPO:git-$githash\")")
aws ecs register-task-definition --region us-east-1 --family $awsenv --cli-input-json "$taskdefinition" --container-definitions "$newcontainers"
newtaskdef=$(aws ecs describe-task-definition --region us-east-1 --task-definition $awsenv)
newrevision=$(echo $newtaskdef | jq -r '.taskDefinition.revision')
newtaskdefarn=$(echo $newtaskdef | jq -r '.taskDefinition.taskDefinitionArn')

# Update the ECS service to use the new revision of the task definition. Check periodically to see
# if the task is running yet, and signal deploy failure if it doesn't start up in a reasonable time.
aws ecs update-service --region us-east-1 --cluster $APP --service $awsenv --task-definition $awsenv:$newrevision

checks=0
# the right-hand side of this test is intentionally formatted as an array
# to match the output of the function call on the left-hand side
until [[ `get_running_taskdef_arns` = "[\"${newtaskdefarn}\"]" ]]; do
  echo "waiting for task to be updated to new revision"
  # wait for up to 5 minutes
  if [[ $checks -ge 15 ]]; then
    echo "$awsenv took too long to update"
    exit 1
  fi
  sleep 20
  checks=$((checks+1))
done
