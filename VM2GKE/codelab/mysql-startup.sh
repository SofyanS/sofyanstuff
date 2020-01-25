#!/usr/bin/env bash
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
apt-get update
# Vars to be used later
CONFIGURATION_BUCKET_NAME="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/configuration-bucket-name -H "Metadata-Flavor: Google")"
DB_PASS="$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-password -H "Metadata-Flavor: Google")"

# This allows us to set the root password for the MySQL server
echo "mysql-server-5.7 mysql-server/root_password password ${DB_PASS}" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password ${DB_PASS}" | sudo debconf-set-selections

apt-get install -y mysql-server-5.7

# Inject MySQL configuration
gsutil cp gs://"$CONFIGURATION_BUCKET_NAME"/tf-hol-09/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
gsutil cp gs://"$CONFIGURATION_BUCKET_NAME"/tf-hol-09/db_creation.sql .

service mysql restart

mysql -u root -p${DB_PASS} -e "GRANT REPLICATION SLAVE ON *.* TO 'sourcereplicator'@'%' IDENTIFIED BY '"${DB_PASS}"'";

mysql -u root -p${DB_PASS} -e "GRANT ALL PRIVILEGES ON *.* TO  'root'@'%' IDENTIFIED BY '"${DB_PASS}"' WITH GRANT OPTION;";

mysql -u root -p${DB_PASS} < db_creation.sql
