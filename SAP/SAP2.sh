# Networking Setup
gcloud compute networks create demonetwork --subnet-mode=custom
gcloud compute networks subnets create subnet-us-central1 --network=demonetwork --region=us-central1 --range=10.128.0.0/20
gcloud compute firewall-rules create icmp --network=demonetwork --action=allow --target-tags=icmp,sap-ports --source-ranges=10.128.0.0/20 --rules=tcp,icmp,udp
gcloud compute firewall-rules create rdp --network=demonetwork --action=allow --target-tags=rdp --source-ranges=0.0.0.0/0 --rules=tcp:3389
gcloud compute firewall-rules create sap-ssh --network=demonetwork --action=allow --target-tags=sap-ssh --source-ranges=0.0.0.0/0 --rules=tcp:22
