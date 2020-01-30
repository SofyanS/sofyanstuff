# Create a GCS bucket
gsutil mb -l us-central1 gs://$DEVSHELL_PROJECT_ID-upload/

# Create cloud function to process audio filess when uploaded to the bucket
# Figure out command to make a cloud function
cd saf-longrun-job-func
gcloud functions deploy safLongRunJobFunc --runtime nodejs8 --trigger-resource gs://$DEVSHELL_PROJECT_ID-upload --trigger-event google.storage.object.finalize
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
# Manually make DFaudio folder in GCS

# Deploy a Cloud Dataflow Pipeline (how?)
cd saf-longrun-job-dataflow
python -m virtualenv env -p python3
source env/bin/activate
pip install -r requirements.txt
python saflongrunjobdataflow.py --output_bigquery $DEVSHELL_PROJECT_ID:saf.transcripts --input_topic projects/$DEVSHELL_PROJECT_ID/topics/payload
cd ..

# Upload Sample Audio Files for Processing



# What is the TOP named entity in the 5 audio files processed by the pipeline? -> "Plan"


# Run a DLP Job https://cloud.google.com/bigquery/docs/scan-with-dlp