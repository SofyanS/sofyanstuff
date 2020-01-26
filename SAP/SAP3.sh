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