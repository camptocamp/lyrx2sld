#! /bin/bash -eu

SERVICE="http://localhost/v1/lyrx2sld/"
INPUT_FILE="tests/data/withicons.lyrx"
OUTPUT_FILE="/tmp/output.zip"

STATUS_CODE=$(curl --write-out %{http_code} -v -d @$INPUT_FILE -H 'Content-Type: application/json' -o $OUTPUT_FILE $SERVICE)

if [ -f "$OUTPUT_FILE" ] && [ $STATUS_CODE = 200 ]; then
    echo "Output file has been created and request status code is 200"
    exit 0
else
    echo "The service did not respond as expected"
    exit 1
fi
