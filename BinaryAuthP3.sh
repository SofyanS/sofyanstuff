PROJECT_ID="$(gcloud config get-value project)"

# Update cluster specific policy to Disallow all images
echo "admissionWhitelistPatterns:
- namePattern: gcr.io/google_containers/*
- namePattern: gcr.io/google-containers/*
- namePattern: k8s.gcr.io/*
- namePattern: gke.gcr.io/*
- namePattern: gcr.io/stackdriver-agents/*
clusterAdmissionRules:
  us-central1-a.my-cluster-1:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: ALWAYS_DENY
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
name: projects/$PROJECT_ID/policy
updateTime: '2020-01-22T02:16:23.564511Z'" > policy.yaml

gcloud beta container binauthz policy import policy.yaml

# Add a path exception to binary auth
echo "admissionWhitelistPatterns:
- namePattern: gcr.io/google_containers/*
- namePattern: gcr.io/google-containers/*
- namePattern: k8s.gcr.io/*
- namePattern: gke.gcr.io/*
- namePattern: gcr.io/stackdriver-agents/*
- namePattern: gcr.io/$PROJECT_ID/nginx*
clusterAdmissionRules:
  us-central1-a.my-cluster-1:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: ALWAYS_DENY
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
name: projects/$PROJECT_ID/policy
updateTime: '2020-01-22T02:31:10.810819Z'" > policy.yaml

gcloud beta container binauthz policy import policy.yaml

# Set up Attestor
ATTESTOR="manually-verified"
ATTESTOR_NAME="Manual Attestor"
ATTESTOR_EMAIL="$(gcloud config get-value core/account)"
NOTE_ID="Human-Attestor-Note"
NOTE_DESC="Human Attestation Note Demo"
NOTE_PAYLOAD_PATH="note_payload.json"
IAM_REQUEST_JSON="iam_request.json"

cat > ${NOTE_PAYLOAD_PATH} << EOF
{
  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "${NOTE_DESC}"
    }
  }
}
EOF

curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @${NOTE_PAYLOAD_PATH}  \
    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"


PGP_PUB_KEY="generated-key.pgp"
sudo apt-get install rng-tools

sudo rngd -r /dev/urandom
gpg --quick-generate-key --yes ${ATTESTOR_EMAIL} 
#### STOP HERE and type the password ####

# Continue creating signing key
gpg --armor --export "${ATTESTOR_EMAIL}" > ${PGP_PUB_KEY}

# Registering the attestor in Binary Auth API
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors create "${ATTESTOR}" \
    --attestation-authority-note="${NOTE_ID}" \
    --attestation-authority-note-project="${PROJECT_ID}"

gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors public-keys add \
    --attestor="${ATTESTOR}" \
    --pgp-public-key-file="${PGP_PUB_KEY}" 

# Update Binary Auth Rule for Attestor                                                                    
echo "admissionWhitelistPatterns:
- namePattern: gcr.io/google_containers/*
- namePattern: gcr.io/google-containers/*
- namePattern: k8s.gcr.io/*
- namePattern: gke.gcr.io/*
- namePattern: gcr.io/stackdriver-agents/*
- namePattern: gcr.io/qwiklabs-gcp-00-a93ffb755ca2/nginx*
clusterAdmissionRules:
  us-central1-a.my-cluster-1:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: REQUIRE_ATTESTATION
    requireAttestationsBy:
    - projects/qwiklabs-gcp-00-a93ffb755ca2/attestors/manually-verified
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
name: projects/$PROJECT_ID/policy
updateTime: '2020-01-22T02:52:11.826286Z'" > policy.yaml

gcloud beta container binauthz policy import policy.yaml



# Create Nginx pod that will fail to create
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: "gcr.io/${PROJECT_ID}/nginx:latest"
    ports:
    - containerPort: 80
EOF

# Delete cluster
cd gke-binary-auth-demo/
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
./delete.sh -c my-cluster-1






