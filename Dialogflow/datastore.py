# Imports the Google Cloud client library
from google.cloud import datastore

# Instantiates a client
datastore_client = datastore.Client()

# The kind for the new entity
kind = 'ticket'
# The name/ID for the new entity
name = 'id=5634161670881280'
# The Cloud Datastore key for the new entity
task_key = datastore_client.key(kind, name)

# Prepares the new entity
task = datastore.Entity(key=task_key)
task['description'] = 'broken'
task['ticketNumber'] = '62591'
task['username'] = '	sofyan'

# Saves the entity
datastore_client.put(task)