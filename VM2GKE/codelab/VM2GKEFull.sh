# Deploy a regional two-node GKE cluster within the us-central1-a and us-central1-b zones
#gcloud beta container --project $DEVSHELL_PROJECT_ID clusters create "mycluster" --region "us-central1" --node-locations "us-central1-a","us-central1-b" --no-enable-basic-auth --cluster-version "1.13.11-gke.14" --machine-type "custom-1-1024" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "1" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/$DEVSHELL_PROJECT_ID/global/networks/default" --subnetwork "projects/$DEVSHELL_PROJECT_ID/regions/us-central1/subnetworks/default" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

gcloud beta container --project "$DEVSHELL_PROJECT_ID" clusters create "mycluster" --region "us-central1" --node-locations "us-central1-a","us-central1-b" --no-enable-basic-auth --cluster-version "1.13.11-gke.23" --machine-type "n1-standard-1" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "1" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/$DEVSHELL_PROJECT_ID/global/networks/default" --subnetwork "projects/$DEVSHELL_PROJECT_ID/regions/us-central1/subnetworks/default" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

# Push Docker Container to GCR
#docker build -t app-server:0.1 .
#docker tag app-server:0.1 gcr.io/$PROJECT_ID/app-server:0.1
#docker push gcr.io/$PROJECT_ID/app-server:0.1
docker build -t app-server:0.1 .
docker tag app-server:0.1 gcr.io/$DEVSHELL_PROJECT_ID/app:1.0.0
docker push gcr.io/$DEVSHELL_PROJECT_ID/app:1.0.0

# Select the right cluster
gcloud container clusters get-credentials mycluster --region us-central1

# Create a secret (Not working)
kubectl create secret generic db-credentials \
--from-file=username=username-mysql-gce.txt \
--from-file=password=password-mysql-gce.txt

# Create a configmap
kubectl create configmap db-config --from-file=db-config=config/config.yaml

# Use Sed to modify deployment.yaml so it inserts the project ID
sed -i "s/\$DEVSHELL_PROJECT_ID/$DEVSHELL_PROJECT_ID/g" deployment.yaml


# Verify that the Deployment has been applied to the GKE cluster
# Check with kubectl get pods and kubectl get deployments
#kubectl create deployment app-server --image=gcr.io/$DEVSHELL_PROJECT_ID/app:1.0.0
kubectl create -f deployment.yaml

# Create a separate node and then delete it
yes | gcloud container clusters delete mycluster --region us-central1