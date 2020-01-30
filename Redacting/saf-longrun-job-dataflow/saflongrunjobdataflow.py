# Copyright 2019 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START SAF pubsub_to_bigquery]
import argparse
import logging
import json
import time

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions
from apache_beam.options.pipeline_options import StandardOptions


# function to get STT data from long audio file using asynchronous speech recognition
def stt_output_response(data):
    from oauth2client.client import GoogleCredentials
    from googleapiclient import discovery
    credentials = GoogleCredentials.get_application_default()
    pub_sub_data = json.loads(data)
    speech_service = discovery.build('speech', 'v1p1beta1', credentials=credentials)
    get_operation_response = speech_service.operations().get(name=pub_sub_data['sttnameid'])
    response = get_operation_response.execute()

    # handle polling of STT
    if pub_sub_data['duration'] != 'NA':
        sleep_duration = round(int(float(pub_sub_data['duration'])) / 2)
    else:
        sleep_duration = 5
    logging.info('Sleeping for: %s', sleep_duration)
    time.sleep(sleep_duration)

    retry_count = 10
    while retry_count > 0 and not response.get('done', False):
        retry_count -= 1
        time.sleep(120)
        response = get_operation_response.execute()

    # return response to include STT data and agent search word
    response_list = [pub_sub_data['agentsearchword'],
                     response,
                     pub_sub_data['fileid'],
                     pub_sub_data['filename'],
                     pub_sub_data['agentid'],
                     pub_sub_data['date'],
                     pub_sub_data['year'],
                     pub_sub_data['month'],
                     pub_sub_data['day'],
                     pub_sub_data['starttime'],
                     pub_sub_data['duration'],
                     pub_sub_data['stereo'],
                     pub_sub_data['agentchannel']
                     ]

    return response_list


# function to get enrich stt_output function response
def stt_parse_response(stt_data):

    def truncate(n, decimals=0):
        multiplier = 10 ** decimals
        return int(n * multiplier) / multiplier

    parse_stt_output_response = {
        'fileid': stt_data[2],
        'filename': stt_data[3],
        'agentid': stt_data[4],
        'date': stt_data[5],
        'year': stt_data[6],
        'month': stt_data[7],
        'day': stt_data[8],
        'starttime': stt_data[9],
        'duration': int(stt_data[10]) * 60,
        'agentspeaking': None,
        'clientspeaking': None,
        'silencesecs': None,
        'silencevalue': None,
        'silencescore': None,
        'nlcategory': None,
        'sentimentscore': None,
        'magnitude': None,
        'transcript': None,
        'words': [],
        'entities': [],
        'sentences': [],
    }
    string_transcript = ''
    total_speaking_time = 0
    total_agent_speaking = 0
    total_client_speaking = 0
    agent_search_word = stt_data[0]
    client_speaker_tag = 0
    agent_speaker_tag = 0

    # get transcript from stt_data
    for i in stt_data[1]['response']['results']:
        if 'transcript' in i['alternatives'][0]:
            string_transcript += str(i['alternatives'][0]['transcript']) + ' '
    parse_stt_output_response['transcript'] = string_transcript[:-1]  # remove the ending whitespace

    # check if the audio file is stereo
    if stt_data[11] == 'true':
        logging.info('Audio file is stereo')
        if int(stt_data[12]) == 1:
            agent_speaker_tag = 1
            client_speaker_tag = 2
        if int(stt_data[12]) == 2:
            agent_speaker_tag = 2
            client_speaker_tag = 1

    # check if the audio file is mono
    if stt_data[11] == 'false':
        logging.info('Audio file is mono')
        # find the agent and the user speaker tag
        for element in range(20):
            if stt_data[1]['response']['results'][-1]['alternatives'][0]['words'][element][
                'word'].lower() == agent_search_word.lower():
                logging.info('SAF Message: Found the agent search word of %s', agent_search_word)
                agent_speaker_tag = stt_data[1]['response']['results'][-1]['alternatives'][0]['words'][element][
                    'speakerTag']
                if int(stt_data[12]) == 1:
                    agent_speaker_tag = 1
                    client_speaker_tag = 2
                if int(stt_data[12]) == 2:
                    agent_speaker_tag = 2
                    client_speaker_tag = 1
                break
            else:
                agent_speaker_tag = 1
                client_speaker_tag = 2

    # check if the audio file is stereo
    if stt_data[11] == 'true':
        logging.info(agent_speaker_tag)
        logging.info(client_speaker_tag)
        # get words from stt_data and enrich data
        for element in stt_data[1]['response']['results']:
            for word in element['alternatives'][0]['words']:
                total_speaking_time += float(word['endTime'].strip('s')) - float(word['startTime'].strip('s'))
                if element['channelTag'] == agent_speaker_tag:
                    total_agent_speaking += float(word['endTime'].strip('s')) - float(word['startTime'].strip('s'))
                    parse_stt_output_response['words'].append(
                        {'word': word['word'], 'startsecs': word['startTime'].strip('s'),
                         'endsecs': word['endTime'].strip('s'), 'speakertag': element['channelTag'],
                         'confidence': word['confidence']})
                if element['channelTag'] == client_speaker_tag:
                    total_client_speaking += float(word['endTime'].strip('s')) - float(word['startTime'].strip('s'))
                    parse_stt_output_response['words'].append(
                        {'word': word['word'], 'startsecs': word['startTime'].strip('s'),
                         'endsecs': word['endTime'].strip('s'), 'speakertag': element['channelTag'],
                         'confidence': word['confidence']})
        parse_stt_output_response['silencesecs'] = float(
            stt_data[1]['response']['results'][-1]['alternatives'][0]['words'][-1]['endTime'].strip(
                's')) - total_speaking_time
        parse_stt_output_response['silencescore'] = truncate(
            parse_stt_output_response['silencesecs'] /
            float(stt_data[1]['response']['results'][-1]['alternatives'][0]['words'][-1]['endTime'].strip('s')) * 100)


    # check if the audio file is mono
    if stt_data[11] == 'false':
        # get words from stt_data and enrich data
        for element in stt_data[1]['response']['results'][-1]['alternatives'][0]['words']:
            total_speaking_time += float(element['endTime'].strip('s')) - float(element['startTime'].strip('s'))
            if element['speakerTag'] == agent_speaker_tag:
                total_agent_speaking += float(element['endTime'].strip('s')) - float(element['startTime'].strip('s'))
            if element['speakerTag'] == client_speaker_tag:
                total_client_speaking += float(element['endTime'].strip('s')) - float(element['startTime'].strip('s'))
            parse_stt_output_response['words'].append(
                {'word': element['word'], 'startsecs': element['startTime'].strip('s'),
                 'endsecs': element['endTime'].strip('s'), 'speakertag': element['speakerTag'],
                 'confidence': element['confidence']})
        parse_stt_output_response['silencesecs'] = float(
            stt_data[1]['response']['results'][-1]['alternatives'][0]['words'][-1]['endTime'].strip(
                's')) - total_speaking_time

    parse_stt_output_response['silencevalue'] = parse_stt_output_response['silencesecs'] / total_speaking_time
    parse_stt_output_response['agentspeaking'] = total_agent_speaking
    parse_stt_output_response['clientspeaking'] = total_client_speaking

    # place holder for Google AutoML NLP
    parse_stt_output_response['nlcategory'] ='NA'

    return parse_stt_output_response


# function to get NLP Sentiment and Entity
def get_nlp_output(parse_stt_output):
    get_nlp_output_response = parse_stt_output
    from oauth2client.client import GoogleCredentials
    from googleapiclient import discovery
    credentials = GoogleCredentials.get_application_default()
    nlp_service = discovery.build('language', 'v1beta2', credentials=credentials)

    # [START NLP analyzeSentiment]
    get_operation_response_sentiment = nlp_service.documents().analyzeSentiment(
        body={
            'document': {
                'type': 'PLAIN_TEXT',
                'content': parse_stt_output['transcript']
            }
        })
    response_sentiment = get_operation_response_sentiment.execute()

    get_nlp_output_response['sentimentscore'] = response_sentiment['documentSentiment']['score']
    get_nlp_output_response['magnitude'] = response_sentiment['documentSentiment']['magnitude']

    for element in response_sentiment['sentences']:
        get_nlp_output_response['sentences'].append({
            'sentence': element['text']['content'],
            'score': element['sentiment']['score'],
            'magnitude': element['sentiment']['magnitude']
        })
    # [END NLP analyzeSentiment]

    # [START NLP analyzeEntitySentiment]
    get_operation_response_entity = nlp_service.documents().analyzeEntitySentiment(
        body={
            'document': {
                'type': 'PLAIN_TEXT',
                'content': parse_stt_output['transcript']
            }
        })
    response_entity = get_operation_response_entity.execute()

    for element in response_entity['entities']:
        get_nlp_output_response['entities'].append({
            'name': element['name'],
            'type': element['type'],
            'sentiment': element['sentiment']['score']
        })
    # [END NLP analyzeEntitySentiment]

    return get_nlp_output_response


def run(argv=None, save_main_session=True):
    """Build and run the pipeline."""
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--input_topic',
        help=('Input PubSub topic of the form '
              '"projects/<PROJECT>/topics/<TOPIC>".'))
    group.add_argument(
        '--input_subscription',
        help=('Input PubSub subscription of the form '
              '"projects/<PROJECT>/subscriptions/<SUBSCRIPTION>."'))
    parser.add_argument('--output_bigquery', required=True,
                        help='Output BQ table to write results to '
                             '"PROJECT_ID:DATASET.TABLE"')
    known_args, pipeline_args = parser.parse_known_args(argv)

    pipeline_options = PipelineOptions(pipeline_args)
    pipeline_options.view_as(SetupOptions).save_main_session = save_main_session
    pipeline_options.view_as(StandardOptions).streaming = True
    p = beam.Pipeline(options=pipeline_options)

    # Read from PubSub into a PCollection.
    if known_args.input_subscription:
        messages = (p
                    | beam.io.ReadFromPubSub(
                    subscription=known_args.input_subscription)
                    .with_output_types(bytes))
    else:
        messages = (p
                    | beam.io.ReadFromPubSub(topic=known_args.input_topic)
                    .with_output_types(bytes))

    decode_messages = messages | 'DecodePubSubMessages' >> beam.Map(lambda x: x.decode('utf-8'))

    # Get STT data from function for long audio file using asynchronous speech recognition
    stt_output = decode_messages | 'SpeechToTextOutput' >> beam.Map(stt_output_response)

    # Parse and enrich stt_output response
    parse_stt_output = stt_output | 'ParseSpeechToText' >> beam.Map(stt_parse_response)

    # Get NLP Sentiment and Entity response
    nlp_output = parse_stt_output | 'NaturalLanguageOutput' >> beam.Map(get_nlp_output)

    # nlp_output | 'bigquerywrite' >> beam.ParDo(bigquery_write)

    # Write to BigQuery
    bigquery_table_schema = {
        "fields": [
            {
                "mode": "NULLABLE",
                "name": "fileid",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "filename",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "agentid",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "date",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "year",
                "type": "INTEGER"
            },
            {
                "mode": "NULLABLE",
                "name": "month",
                "type": "INTEGER"
            },
            {
                "mode": "NULLABLE",
                "name": "day",
                "type": "INTEGER"
            },
            {
                "mode": "NULLABLE",
                "name": "starttime",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "duration",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "silencesecs",
                "type": "FLOAT"
            },
            {
                "mode": "NULLABLE",
                "name": "silencevalue",
                "type": "FLOAT"
            },
            {
                "mode": "NULLABLE",
                "name": "sentimentscore",
                "type": "FLOAT"
            },
            {
                "mode": "NULLABLE",
                "name": "silencescore",
                "type": "INTEGER"
            },
            {
                "mode": "NULLABLE",
                "name": "agentspeaking",
                "type": "FLOAT"
            },
            {
                "mode": "NULLABLE",
                "name": "clientspeaking",
                "type": "FLOAT"
            },
            {
                "mode": "NULLABLE",
                "name": "nlcategory",
                "type": "STRING"
            },
            {
                "mode": "NULLABLE",
                "name": "magnitude",
                "type": "FLOAT"
            },
            {
                "mode": "NULLABLE",
                "name": "transcript",
                "type": "STRING"
            },
            {
                "fields": [
                    {
                        "mode": "NULLABLE",
                        "name": "name",
                        "type": "STRING"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "type",
                        "type": "STRING"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "sentiment",
                        "type": "STRING"
                    }
                ],
                "mode": "REPEATED",
                "name": "entities",
                "type": "RECORD"
            },
            {
                "fields": [
                    {
                        "mode": "NULLABLE",
                        "name": "word",
                        "type": "STRING"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "startSecs",
                        "type": "STRING"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "endSecs",
                        "type": "STRING"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "speakertag",
                        "type": "STRING"
                    }
                ],
                "mode": "REPEATED",
                "name": "words",
                "type": "RECORD"
            },
            {
                "fields": [
                    {
                        "mode": "NULLABLE",
                        "name": "sentence",
                        "type": "STRING"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "score",
                        "type": "FLOAT"
                    },
                    {
                        "mode": "NULLABLE",
                        "name": "magnitude",
                        "type": "FLOAT"
                    }
                ],
                "mode": "REPEATED",
                "name": "sentences",
                "type": "RECORD"
            }
        ]
    }
    nlp_output | 'WriteToBigQuery' >> beam.io.WriteToBigQuery(
            known_args.output_bigquery,
            schema=bigquery_table_schema,
            create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
            write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND)

    p.run()


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.DEBUG)
    run()
# [END SAF pubsub_to_bigquery]