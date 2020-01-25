PROJECT_ID="$(gcloud config get-value project)"

# Create a secret (Not working)
kubectl create secret generic db-credentials \
--from-file=username=username-mysql-gce.txt \
--from-file=password=password-mysql-gce.txt

# Create a configmap
kubectl create configmap db-config --from-file=db-config=config/config.yaml


# Verify that the Deployment has been applied to the GKE cluster (Not working)
#gcloud builds submit --project=$PROJECT_ID --config deployment.yaml
kubectl create deployment app-server --image=gcr.io/$PROJECT_ID/app-server:0.1 # I need to modify the app.py file so it doesn't use config