# Enable all APIs do this seperately in P1
gcloud services enable drive.googleapis.com

# Create storage bucket
gsutil mb gs://bucket_$DEVSHELL_PROJECT_ID/

# Upload credentials
gsutil cp credentials.json gs://bucket_$DEVSHELL_PROJECT_ID/

# Pull Credentials.json (I might be able to just have the file exist in github and this is unncessary)
mkdir gdrive_api_lab
cd gdrive_api_lab
gsutil cp gs://bucket_$DEVSHELL_PROJECT_ID/credentials.json .

# Create two google docs then run this
npm install
node .