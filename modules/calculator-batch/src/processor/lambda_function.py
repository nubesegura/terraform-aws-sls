import os
import csv
import json
import boto3
import urllib.parse
from decimal import Decimal

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    table_name = os.environ.get('DYNAMODB_TABLE_NAME')
    if not table_name:
        raise ValueError("DYNAMODB_TABLE_NAME environment variable is missing")
        
    table = dynamodb.Table(table_name)
    processed_records = 0
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
        
        print(f"Processing s3://{bucket}/{key}")
        
        try:
            response = s3_client.get_object(Bucket=bucket, Key=key)
            csv_content = response['Body'].read().decode('utf-8').splitlines()
            reader = csv.DictReader(csv_content)
            
            with table.batch_writer() as batch:
                for row in reader:
                    # Dynamodb no soporta floats nativamente, convertimos a Decimal o String
                    item = {
                        'pk': row['pk'],
                        'sk': row['sk'],
                        'user_id': row['user_id'],
                        'txn_id': row['txn_id'],
                        'timestamp': row['timestamp'],
                        'operation': row['operation'],
                        'device': row['device'],
                        'region': row['region'],
                        'account_id': row['account_id']
                    }
                    
                    if row.get('operand_1'):
                        item['operand_1'] = Decimal(str(row['operand_1']))
                    if row.get('operand_2'):
                        item['operand_2'] = Decimal(str(row['operand_2']))
                    if row.get('result'):
                        item['result'] = Decimal(str(row['result']))
                        
                    item['is_error'] = row['is_error'].lower() == 'true'
                    
                    batch.put_item(Item=item)
                    processed_records += 1
                    
        except Exception as e:
            print(f"Error processing object {key} from bucket {bucket}. Event: {json.dumps(event, indent=2)}")
            print(e)
            raise e
            
    print(f"Successfully processed {processed_records} records.")
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully processed {processed_records} records.')
    }
