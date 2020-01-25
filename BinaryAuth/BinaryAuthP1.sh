PROJECT_ID="$(gcloud config get-value project)"

# Create repository
git clone https://github.com/GoogleCloudPlatform/gke-binary-auth-demo.git
cd gke-binary-auth-demo

# Set Region and Zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# Create cluster
./create.sh -c my-cluster-1