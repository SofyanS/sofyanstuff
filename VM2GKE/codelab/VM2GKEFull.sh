PROJECT_ID="$(gcloud config get-value project)"

# Download prereq lab files
#mkdir codelab
#gsutil cp -r gs://spls/gsp307/codelab/* codelab/
#cd codelab

# Deploy a regional two-node GKE cluster within the us-central1-a and us-central1-b zones
gcloud beta container --project $PROJECT_ID clusters create "mycluster" --region "us-central1" --node-locations "us-central1-a","us-central1-b" --no-enable-basic-auth --cluster-version "1.13.11-gke.14" --machine-type "custom-1-1024" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "1" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/us-central1/subnetworks/default" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair


# Push Docker Container to GCR
docker build -t app-server:0.1 .
docker tag app-server:0.1 gcr.io/$PROJECT_ID/app-server:0.1
docker push gcr.io/$PROJECT_ID/app-server:0.1

# Create a secret (Not working)
#kubectl create secret generic db-credentials \
#--from-literal=username="root" \
#--from-literal=password="solution-admin"
kubectl create secret generic db-credentials \
--from-file=username=username-mysql-gce.txt \
--from-file=password=password-mysql-gce.txt

# Create a configmap
kubectl create configmap db-config --from-file=db-config=config/config.yaml


# Verify that the Deployment has been applied to the GKE cluster (Not working)
#gcloud builds submit --project=$PROJECT_ID --config deployment.yaml
kubectl create deployment app-server --image=gcr.io/$PROJECT_ID/app-server:0.1 # I need to modify the app.py file so it doesn't use config


# Verify that the old Application VM has been deleted (Can I just start by running this?)
yes | gcloud container clusters delete mycluster --region us-central1
