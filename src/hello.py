#coding: UTF-8
import json

def lambda_handler(event, context):
    response = f"Hello, {event['queryStringParameters']['Name']}!"
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(response),
    }
