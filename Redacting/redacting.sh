
# Copy from source repo
# gcloud source repos clone accelerate20-challenge-lab --project=accelerate20-challenge-lab-3

# Create a GCS bucket
gsutil mb -l us-central1 gs://$DEVSHELL_PROJECT_ID-upload/

# Create cloud function to process audio filess when uploaded to the bucket
yes | gcloud functions deploy safLongRunJobFunc --runtime nodejs8 --trigger-resource gs://$DEVSHELL_PROJECT_ID-upload --trigger-event google.storage.object.finalize --source=saf-longrun-job-func
cd ..

# Create BQ Dataset
cd bigquery
bq mk saf
bq mk --table $DEVSHELL_PROJECT_ID:saf.transcripts schema.json
cd ..

# Create Cloud Pub/Sub Topic
gcloud pubsub topics create payload

# Create a Cloud Storage Bucket for Staging Contents
gsutil mb -l us-central1 gs://$DEVSHELL_PROJECT_ID-staging/
# Make DFaudio folder in UI

# Deploy a Cloud Dataflow Pipeline (how?)
cd saf-longrun-job-dataflow
python -m virtualenv env -p python3
source env/bin/activate
pip install -r requirements.txt
python saflongrunjobdataflow.py --output_bigquery=$DEVSHELL_PROJECT_ID:saf.transcripts --input_topic=projects/$DEVSHELL_PROJECT_ID/topics/payload --region=us-central1 --project=$DEVSHELL_PROJECT_ID --temp_location=gs://$DEVSHELL_PROJECT_ID-staging/ --staging_location=gs://$DEVSHELL_PROJECT_ID-staging/ --runner=DataflowRunner
cd ..

# Upload Sample Audio Files for Processing
gsutil cp sample-audio/transcript1.wav gs://$DEVSHELL_PROJECT_ID-upload
gsutil cp sample-audio/transcript2.wav gs://$DEVSHELL_PROJECT_ID-upload
gsutil cp sample-audio/transcript3.wav gs://$DEVSHELL_PROJECT_ID-upload
gsutil cp sample-audio/transcript4.wav gs://$DEVSHELL_PROJECT_ID-upload
gsutil cp sample-audio/transcript5.wav gs://$DEVSHELL_PROJECT_ID-upload

# What is the TOP named entity in the 5 audio files processed by the pipeline? -> "Plan"


# Run a DLP Job https://cloud.google.com/bigquery/docs/scan-with-dlp
