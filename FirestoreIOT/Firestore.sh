#$DEVSHELL_PROJECT_ID

# Set up variables and firebase
export REGISTRY_ID=config-demo
export CLOUD_REGION=us-central1 # or change to an alternate region;
export GCLOUD_PROJECT=$(gcloud config list project --format "value(core.project)")
no | firebase login --no-localhost

# Create a Pub/Sub a Pub/Sub topic
gcloud pubsub topics create device-events

# Create a Cloud IoT core Registry
gcloud iot registries create $REGISTRY_ID --region=$CLOUD_REGION --event-notification-config=subfolder="",topic=device-events

# Deploy the Relay Function
cd functions
firebase --project $GCLOUD_PROJECT functions:config:set \
  iot.core.region=$CLOUD_REGION \
  iot.core.registry=$REGISTRY_ID
firebase --project $GCLOUD_PROJECT deploy --only functions

# Create your device
cd ../sample-device
gcloud iot devices create sample-device --region $CLOUD_REGION --registry $REGISTRY_ID --public-key path=./ec_public.pem,type=ES256

# Modify the Configuration (First create Firestore DB)
#node build/index.js