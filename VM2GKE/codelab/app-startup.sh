MYSQL_HOST=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/mysql-host -H "Metadata-Flavor: Google")

mkdir -p /boot/post_launch
mkdir -p /opt/app
cd /opt/app
if [ ! -f /root/INSTALLATION_DONE ]; then
gcloud compute images create ce-linux-boot-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-linux-boot-image-002  &
gcloud compute images create ce-linux-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-linux-data-image-002  &
gcloud compute images create ce-mssql-enterprise-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-mssql-enterprise-data-image-002  &
gcloud compute images create  ce-mssql-standard-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-mssql-standard-data-image-002  &
gcloud compute images create ce-mssql-web-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-mssql-web-data-image-002 &
gcloud compute images create  ce-rhel6-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-rhel6-data-image-002  &
gcloud compute images create ce-rhel7-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-rhel7-data-image-002  &
gcloud compute images create ce-win2003-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-win2003-data-image-002 &
gcloud compute images create ce-windows-boot-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-windows-data-image-002 &
gcloud compute images create ce-windows-data-image-002 --source-image https://www.googleapis.com/compute/v1/projects/qwiklabs-resources/global/images/ce-windows-data-image-002  &
    gsutil cp -r gs://accelerate2019-codelabs/tf-hol-09/* .
    echo "db-host: $MYSQL_HOST" > /opt/app/config/config.yaml
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    cp ce_post_launch.sh /boot/post_launch/
    chmod +rx /boot/post_launch/ce_post_launch.sh
    python get-pip.py
    pip install -r requirements.txt
    touch /root/INSTALLATION_DONE
fi

python app.py & 
