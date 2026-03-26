import json
import os
import io
import boto3
from PIL import Image

s3_client = boto3.client('s3')

OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET', 'processed-images-bucket')


def lambda_handler(event, context):
    try:
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        object_key = event['Records'][0]['s3']['object']['key']

        print(f"Processing image: s3://{source_bucket}/{object_key}")

        response = s3_client.get_object(Bucket=source_bucket, Key=object_key)
        image_data = response['Body'].read()

        image = Image.open(io.BytesIO(image_data))
        image_format = image.format if image.format else 'JPEG'

        grayscale_image = image.convert('L')

        output_buffer = io.BytesIO()
        grayscale_image.save(output_buffer, format=image_format)
        output_buffer.seek(0)

        output_key = f'processed-{object_key}'

        s3_client.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=output_buffer.getvalue(),
            ContentType=f'image/{image_format.lower()}'
        )

        print(f"Processed image saved: s3://{OUTPUT_BUCKET}/{output_key}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Image processed successfully',
                'input_bucket': source_bucket,
                'input_key': object_key,
                'output_bucket': OUTPUT_BUCKET,
                'output_key': output_key
            })
        }

    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing image',
                'error': str(e)
            })
        }
