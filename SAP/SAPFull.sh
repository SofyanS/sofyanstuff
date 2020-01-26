# Enable all APIs
gcloud services enable file.googleapis.com

# Networking Setup
gcloud compute networks create demonetwork --subnet-mode=custom
gcloud compute networks subnets create subnet-us-central1 --network=demonetwork --region=us-central1 --range=10.128.0.0/20
gcloud compute firewall-rules create icmp --network=demonetwork --action=allow --target-tags=icmp,sap-ports --source-ranges=10.128.0.0/20 --rules=tcp,icmp,udp
gcloud compute firewall-rules create rdp --network=demonetwork --action=allow --target-tags=rdp --source-ranges=0.0.0.0/0 --rules=tcp:3389
gcloud compute firewall-rules create sap-ssh --network=demonetwork --action=allow --target-tags=sap-ssh --source-ranges=0.0.0.0/0 --rules=tcp:22

# Create the RDP VM (Check 1)
gcloud compute instances create rdp-client --zone=us-central1-a \
--machine-type=n1-standard-4 \
--image-project=windows-cloud \
--image-family=windows-2019 \
--network=demonetwork \
--subnet=subnet-us-central1 \
--tags=rdp,http-server,https-server \
--boot-disk-type=pd-ssd \
--metadata windows-startup-script-ps1='
gsutil cp  gs://scripts-for-demos/hanainstall/master.ps1 "C:\Program Files\master.ps1"
& "C:\Program Files\master.ps1"
'

# Install SAP HANA Studio (Can I skip this? Looks like yes)
# Create a Filestore Instance (Check 2)
gcloud filestore instances create hana-nfs \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-b \
    --tier=STANDARD \
    --file-share=name="hana",capacity=1TB \
    --network=name="demonetwork"


# Configure the Filestore Instance for HANA (Check 3) - Use Startup script
# EDIT 10.194.236.34 to Filestore IP Address. Use script to list and get filestore IP address
# FILESTORE_IP = "10.194.236.34" # TBD Real Command (If the next line doesn't work, it's probably because FILESTORE_IP Failed)
gcloud filestore instances describe hana-nfs \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=us-central1-b > fstore.txt
FILESTORE_IP = grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' fstore.txt
gcloud beta compute --project=$DEVSHELL_PROJECT_ID instances create linux-client --zone=us-central1-b --machine-type=n1-standard-1 --subnet=subnet-us-central1 --network-tier=PREMIUM --metadata=startup-script=sudo\ su\ -$'\n'mkdir\ /hana$'\n'mount\ --source\ $FILESTORE_IP:/hana\ --target\ /hana$'\n'cd\ /hana$'\n'mkdir\ shared\ \&\&\ mkdir\ hanabackup$'\n'll$'\n'cd\ \~$'\n'umount\ /hana --maintenance-policy=MIGRATE --service-account=486952412480-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=sap-ssh --image=sles-12-sp5-v20191209 --image-project=suse-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=linux-client --reservation-affinity=any


# HANA nodes Deployment (Check 4)
#gsutil cp gs://scripts-for-demos/yaml_files/hana_scaleout/NA/* ./

sed -i "s/\10.194.236.34/$FILESTORE_IP/g" hana_scaleout_na
gcloud deployment-manager deployments create hanascaleoutdemo  --config hana_scaleout_na.yaml
