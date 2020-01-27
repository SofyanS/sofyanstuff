# Enable all APIs do this seperately in P1
gcloud services enable dialogflow.googleapis.com

# Import Agent
gcloud alpha dialogflow agent import --source="Helpdesk.zip"