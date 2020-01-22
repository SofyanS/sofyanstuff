PROJECT_ID="$(gcloud config get-value project)"

# Enable Binary Auth API
gcloud services enable \
    container.googleapis.com \
    containeranalysis.googleapis.com \
    binaryauthorization.googleapis.com
    
# Create policy
gcloud beta container binauthz policy export > policy.yaml

# Create deny policy in UI
echo "admissionWhitelistPatterns:
- namePattern: gcr.io/google_containers/*
- namePattern: gcr.io/google-containers/*
- namePattern: k8s.gcr.io/*
- namePattern: gke.gcr.io/*
- namePattern: gcr.io/stackdriver-agents/*
clusterAdmissionRules:
  us-central1-a.my-cluster-1:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: ALWAYS_ALLOW
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
name: projects/$PROJECT_ID/policy" > policy.yaml

# Run Deny Policy
gcloud beta container binauthz policy import policy.yaml

# Pull down latest nginx container
docker pull gcr.io/google-containers/nginx:latest
gcloud auth configure-docker
docker tag gcr.io/google-containers/nginx "gcr.io/${PROJECT_ID}/nginx:latest"
docker push "gcr.io/${PROJECT_ID}/nginx:latest"