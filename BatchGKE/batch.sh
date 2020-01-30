# Create a GCS bucket
gsutil mb -l us-central1  gs://$DEVSHELL_PROJECT_ID-bucket

# Create a filestore instance'
# yes to pipe enable file.googleapis.com
yes | gcloud filestore instances create batch-filestore \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-a \
    --tier=STANDARD \
    --file-share=name="fsname",capacity=1TB \
    --network=name=default

####################################################
# Configure the Login VM (ssh to hello-batch-login)#
####################################################
# Mount Filestore at /mnt/filestore #
#####################################
DEVSHELL_PROJECT_ID="qwiklabs-gcp-ml-0bc583e3798d" # Insert project ID

mkdir /mnt/filestore
gcloud filestore instances describe batch-filestore \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-a > fstore.txt
FILESTORE_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' fstore.txt)
mount --source $FILESTORE_IP:/fsname --target /mnt/filestore

# Install batch on GKE, Ksub, and create cluster
yum install nano
./install.sh

# Add the default values for projectID, clusterName, and, if you are not operating in the default namespace, namespace in .ksubrc:
# After running ./ksub --config --create-default.
# nano ~/.ksubrc

