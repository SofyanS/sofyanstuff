# Enable all APIs do this seperately in P1
gcloud services enable file.googleapis.com

# Create a Filestore Instance (Check 2)
gcloud filestore instances create hana-nfs \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-b \
    --tier=STANDARD \
    --file-share=name="hana",capacity=1TB \
    --network=name="demonetwork"\