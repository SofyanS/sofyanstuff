PROJECT_ID="$(gcloud config get-value project)"

# Push Docker Container to GCR
docker build -t app-server:0.1 .
docker tag app-server:0.1 gcr.io/$PROJECT_ID/app-server:0.1
docker push gcr.io/$PROJECT_ID/app-server:0.1