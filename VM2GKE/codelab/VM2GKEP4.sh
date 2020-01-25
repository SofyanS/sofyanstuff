PROJECT_ID="$(gcloud config get-value project)"

# Verify that the old Application VM has been deleted (Can I just start by running this?)
yes | gcloud container clusters delete mycluster --region us-central1