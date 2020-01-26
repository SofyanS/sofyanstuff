# Get Filestore IP
gcloud filestore instances describe hana-nfs \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-b > fstore.txt
FILESTORE_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' fstore.txt)

# HANA nodes Deployment (Check 4)
sed -i "s/\10.194.236.34/$FILESTORE_IP/g" hana_scaleout_na
gcloud deployment-manager deployments create hanascaleoutdemo  --config hana_scaleout_na.yaml