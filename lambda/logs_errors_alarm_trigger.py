import boto3

from base64 import b64encode, b64decode
from botocore.exceptions import ClientError
from datetime import datetime
from gzip import decompress
from json import dumps, loads
from os import environ
from re import compile, escape
from time import time


MAX = int(environ['MAX'])


def aws_url_encode(text):
    replace_map = {
        '/' : '$252F',
        '[' : '$255B',
        '$' : '$2524',
        ']' : '$255D'
    }
    rx = compile('|'.join(map(escape, replace_map)))
    def one_xlat(match):
        return replace_map[match.group(0)]
    return rx.sub(one_xlat, text)
    

def logpayload(event):
    compressed_payload = b64decode(event['awslogs']['data'])
    uncompressed_payload = decompress(compressed_payload)
    log_payload = loads(uncompressed_payload)
    return log_payload


def error_details(payload):
    log_event = payload["logEvents"][0]
    message = loads(payload["message"])
    
    error_details = {
        "log_group" : payload['logGroup'],
        "log_stream" : payload['logStream'],
        "owner" : payload["owner"],
        "timestamp" : log_event['timestamp'],
        "message" : payload["message"]
    }

    if "trace_id" in message:
        error_details["trace_id"] = message["trace_id"]

    if "request_id" in message:
        error_details["request_id"] = message["request_id"]
    
    return error_details


def error_analysis(error_msg):
    dynamodb_client = boto3.client('dynamodb')
    is_trigger = False
    counter = 0
    item = dynamodb_client.get_item(
                TableName=environ['DYNAMODB_TABLE'],
                Key={
                    'error_hash': {"S" : str(b64encode(error_msg.encode('utf-8')))}
                }
            )
            
    try:
        counter = int(item['Item']['counter']['N'])
        if int(time()) > int(item['Item']['timestamp']["N"]):
            dynamodb_client.update_item(
                TableName=environ['DYNAMODB_TABLE'],
                Key={
                    'error_hash': {"S" : str(b64encode(error_msg.encode('utf-8')))}
                },
                UpdateExpression='SET #timestamp = :val1, #n = :val2, #m = :val3, #ttl = :val4, #counter = :val5',
                ExpressionAttributeNames={
                    '#timestamp': 'timestamp',
                    '#n': 'n',
                    '#m': 'm',
                    '#ttl': 'ttl',
                    '#counter': 'counter'
                },
                ExpressionAttributeValues={
                    ':val1': {"N" : str(int(time()) + min(int(item['Item']['n']["N"]) + int(item['Item']['m']["N"])*60, MAX))},
                    ':val2': {"N" : item['Item']['m']["N"]},
                    ':val3': {"N" : str(int(item['Item']['m']["N"]) + int(item['Item']['n']["N"]))},
                    ':val4': {"N" : str(int(time()) + (2 * min(int(item['Item']['n']["N"]) + int(item['Item']['m']["N"])*60, MAX)))},
                    ':val5': {"N" : "0"}
                }
            )
            is_trigger = True
        else:
            dynamodb_client.update_item(
                TableName=environ['DYNAMODB_TABLE'],
                Key={
                    'error_hash': {"S" : str(b64encode(error_msg.encode('utf-8')))}
                },
                UpdateExpression='SET #counter = :val3',
                ExpressionAttributeNames={
                    '#counter': 'counter'
                },
                ExpressionAttributeValues={
                    ':val3': {"N" : str(int(item['Item']['counter']["N"]) + 1)}
                }
            )         
    except KeyError as e:
        dynamodb_client.put_item(
            TableName=environ['DYNAMODB_TABLE'],
            Item={
                'error_hash': { "S" : str(b64encode(error_msg.encode('utf-8')))},
                'timestamp': {"N" : str(int(time()) + 60)},
                'n' : {"N" : "1"},
                'm' : {"N" : "1"},
                'counter' : {"N" : "0"},
                'ttl' : {"N" : str(int(time()) + 120)}
            }
        )
        is_trigger = True

    return is_trigger, counter


def publish_message(details, counter):
    sns_client = boto3.client('sns')
    datetime_error = datetime.fromtimestamp(details['timestamp']/1000)
    
    try:
        slack_message = {
            "version": "1.0",
            "source": "custom",
            "content": {
                "textType": "client-markdown",
                "title": f":alert: Error on `{details['log_group'].split('/')[-1]}` | Account: `{details['owner']}` | The: `{datetime_error.strftime('%d-%m-%Y')}` at `{datetime_error.strftime('%H:%M:%S')}`",
                "description": f'''
                    :arrow_right: Timestamp: `{datetime_error.strftime('%d-%m-%Y %H:%M:%S')} UTC` \n
                    :arrow_right: Log stream: <https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/{details['log_group'].replace('/', '%252F')}/log-events/{aws_url_encode(details['log_stream'])}|{details['log_stream']}> \n
                    :arrow_right: Error: `{details['message']}` \n
                    :arrow_right: Beginning of the error message: \n ```{details['full_message'][:25]}...```
                '''
            }
        }
        
        if counter != 0:
            slack_message["content"]["description"] += f"\n :warning: Number of errors since last notification: `{counter}`"

        if "trace_id" in details and details["trace_id"] != "1-00000000-000000000000000000000000":
            slack_message["content"]["description"] += f"\n :informations-source: Trace ID: <https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#xray:traces/{details['trace_id']}|{details['trace_id']}>"
        
        if "request_id" in details:
            slack_message["content"]["description"] += f"\n :informations-source: Request ID: `{details['request_id']}`"

        sns_client.publish(
            TopicArn=environ['SNS_ARN'],
            Subject=f'Cloudwatch Logs Error',
            Message=dumps({'default': dumps(slack_message)}),
            MessageStructure='json'
        )

    except ClientError as e:
        print("An error occured: %s" % e)


def lambda_handler(event, context):
    payload = logpayload(event)
    details = error_details(payload)
    trigger, counter = error_analysis(details["message"] + "-" + details["log_group"])

    if trigger:
        publish_message(details, counter)