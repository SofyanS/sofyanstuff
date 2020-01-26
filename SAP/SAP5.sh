# HANA nodes Deployment (Check 4)
sed -i "s/\10.194.236.34/$FILESTORE_IP/g" hana_scaleout_na
gcloud deployment-manager deployments create hanascaleoutdemo  --config hana_scaleout_na.yaml