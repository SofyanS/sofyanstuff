echo "db-host: target-mysql-primary" > /opt/app/config/config.yaml
PROJECT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/project/project-id  -H "Metadata-Flavor: Google")
echo "nameserver 169.254.169.254" > /etc/resolv.conf
echo "search c.${PROJECT_ID}.internal google.internal" >> /etc/resolv.conf

killall python
cd /opt/app
python app.py &
