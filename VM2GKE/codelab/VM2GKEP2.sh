# Push Docker Container to GCR
#docker build -t app-server:0.1 .
#docker tag app-server:0.1 gcr.io/$PROJECT_ID/app-server:0.1
#docker push gcr.io/$PROJECT_ID/app-server:0.1
docker build -t app-server:0.1 .
docker tag app-server:0.1 gcr.io/$DEVSHELL_PROJECT_ID/app:1.0.0
docker push gcr.io/$DEVSHELL_PROJECT_ID/app:1.0.0