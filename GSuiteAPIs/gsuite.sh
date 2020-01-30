# Move credentials file to correct folder
mv ~/credentials.json .

# Enable all APIs do this seperately in P1
gcloud services enable drive.googleapis.com

# Create storage bucket
gsutil mb gs://bucket_$DEVSHELL_PROJECT_ID/

# Upload credentials
gsutil cp credentials.json gs://bucket_$DEVSHELL_PROJECT_ID/

# Create two google docs before running this
#npm install
node .