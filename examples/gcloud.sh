#!/bin/bash

##### NO NEED TO EDIT THE VALUES BELOW #####
role_id=d9.autobrd
role_title="D9 Autobrd"
sa_id=d9-autobrd
##### NO NEED TO EDIT THE VALUES ABOVE #####

##### MUST EDIT THE VALUES BELOW #####
project_id=<your_project_id_goes_here>
d9_id=<your_d9_api_id_goes_here>
d9_secret=<your_d9_api_secret_goes_here>
psk=<your_psk_goes_here>
##### MUST EDIT THE VALUES ABOVE #####

cat << EOF > custom.role.yaml
title: $role_title
description: Custom role for d9-autobrd-gcp cloud function
includedPermissions:
- iam.serviceAccounts.actAs
EOF

cat << EOF > runtime.env.yaml
D9_ID: $d9_id
D9_SECRET: $d9_secret
PSK: $psk
EOF

cat << EOF > .gcloudignore
.gcloudignore
.git
.gitignore

gcloud.sh
gcloud-with-secrets.sh
custom.role.yaml
examples
LICENSE
node_modules
package-lock.json
README.md
runtime.env.yaml
EOF

gcloud services enable cloudbuild.googleapis.com --project=$project_id
gcloud services enable iam.googleapis.com --project=$project_id
gcloud services enable cloudresourcemanager.googleapis.com --project=$project_id

gcloud iam roles create $role_id --project=$project_id --file=custom.role.yaml

gcloud iam service-accounts create $sa_id --project=$project_id --description="The service account for the d9-autobrd-gcp cloud function" --display-name="D9 Autobrd"

gcloud projects add-iam-policy-binding $project_id --member="serviceAccount:$sa_id@$project_id.iam.gserviceaccount.com" --role="projects/$project_id/roles/$role_id"

for binding_project_id in $(gcloud projects list |grep PROJECT_ID |awk '{ print $2 }'); do
  gcloud projects add-iam-policy-binding $binding_project_id --member="serviceAccount:$sa_id@$project_id.iam.gserviceaccount.com" --role="roles/editor"
  gcloud projects add-iam-policy-binding $binding_project_id --member="serviceAccount:$sa_id@$project_id.iam.gserviceaccount.com" --role="roles/iam.securityAdmin"
done

gcloud functions deploy d9AutobrdOnboard --project $project_id --trigger-http --runtime nodejs14 --service-account $sa_id@$project_id.iam.gserviceaccount.com --allow-unauthenticated --max-instances 1 --timeout 540 --env-vars-file runtime.env.yaml

exit $?