# Create a Filestore Instance (Check 2)
gcloud filestore instances create hana-nfs \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-b \
    --tier=STANDARD \
    --file-share=name="hana",capacity=1TB \
    --network=name="demonetwork"\

# Configure the Filestore Instance for HANA (Check 3) - Use Startup script
# Get Filestore IP
gcloud filestore instances describe hana-nfs \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-b > fstore.txt
FILESTORE_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' fstore.txt)
gcloud beta compute --project=$DEVSHELL_PROJECT_ID instances create linux-client --zone=us-central1-b --machine-type=n1-standard-1 --subnet=subnet-us-central1 --network-tier=PREMIUM --metadata=startup-script=sudo\ su\ -$'\n'mkdir\ /hana$'\n'mount\ --source\ $FILESTORE_IP:/hana\ --target\ /hana$'\n'cd\ /hana$'\n'mkdir\ shared\ \&\&\ mkdir\ hanabackup$'\n'll$'\n'cd\ \~$'\n'umount\ /hana --maintenance-policy=MIGRATE --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=sap-ssh --image=sles-12-sp5-v20191209 --image-project=suse-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=linux-client --reservation-affinity=any