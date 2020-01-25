# Create a secret (Not working)
kubectl create secret generic db-credentials \
--from-file=username=username-mysql-gce.txt \
--from-file=password=password-mysql-gce.txt

# Create a configmap
kubectl create configmap db-config --from-file=db-config=config/config.yaml

# Use Sed to modify deployment.yaml so it inserts the project ID
sed -i "s/\$DEVSHELL_PROJECT_ID/$DEVSHELL_PROJECT_ID/g" deployment.yaml


# Verify that the Deployment has been applied to the GKE cluster (Not working)
#gcloud builds submit --project=$DEVSHELL_PROJECT_ID --config deployment.yaml
# Check with kubectl get pods and kubectl get deployments
#kubectl create deployment app-server --image=gcr.io/$DEVSHELL_PROJECT_ID/app:1.0.0
kubectl create -f deployment.yaml