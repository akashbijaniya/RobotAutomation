*** Settings ***
Library           JSONLibrary
Library           Collections
Library           RequestsLibrary
Library           String
Variables         ../config/Config.py  # Load environment, API headers, and payload configurations


*** Variables ***
${ENV}            qac1  # Default environment, can be overridden at runtime
${PARTITION_KEY}        # Stores the partition key from the kinesis_shard_key API
${STREAM_NAME}          # Stores the stream name from the kinesis_shard_key API
${DATA}                 # Stores dynamically generated base64 encoded string

${SEQUENCE_NUMBER}      # Stores the sequence number from the log upload to kinesis response
${SHARD_ID}             # Stores the shard ID from the log upload to kinesis response
${SHARD_ITERATOR_TYPE}  AT_SEQUENCE_NUMBER
${KINESIS_HOST}    https://kinesis.us-west-2.amazonaws.com  # Change this to the correct Kinesis URL

${SIGNED_HEADERS}    # Stores the signed headers from the signed_kinesis_post API
${LOG_UPLOAD_SIGNED_HEADERS}    # Store the signed headers from the signed_kinesis_post API

${LOG_UPLOAD_PAYLOAD}
${PAYLOAD_HASH}   # Store the SHA-256 hash of the payload
${LOG_UPLOAD_PAYLOAD_HASH}   # Store the SHA-256 hash of the payload

${RESPONSE}    # Store the response from the API
${KINESIS_SHARD_KEY_RESPONSE}    # Store the response from the kinesis_shard_key API
${LOG_UPLOAD_SIGNED_KINESIS_POST_RESPONSE}    # Store the response from the signed_kinesis_post API
${KINESIS_LOG_UPLOAD_RESPONSE}    # Store the response from the kinesis_file_upload API
# ${KINESIS_SHARD_KEY_RESPONSE_STRUCTURE}    {"PartitionKey":"","StreamName":"","status":0}
&{KINESIS_SHARD_KEY_RESPONSE_STRUCTURE}    PartitionKey=    StreamName=    status=

*** Keywords ***

Create API session
    [Arguments]    ${alias}    ${api_name}    ${env}
    ${env_data}=      Get environment configuration    ${env}
    ${headers}=       Get API headers    ${api_name}    ${env}
    ${url}=           Get From Dictionary    ${env_data}    url
    Create Session    ${alias}    ${url}    headers=${headers}    verify=True

Send a Post request on the session
    [Arguments]    ${alias}    ${api_name}    ${env}    ${payload}=None
    ${env_data}=    Get environment configuration    ${env}
    ${final_payload}=    Run Keyword If    ${payload} is not None
    ...    Set Variable    ${payload}
    ...    ELSE
    ...    Get API Payload    ${api_name}    ${env}
    
    ${response}=    POST On Session    ${alias}    /api/${api_name}    json=${final_payload}
    Set Suite Variable    ${RESPONSE}    ${response}

Send a Post request
    [Arguments]    ${host}    ${headers}    ${payload}
    ${response}=    POST  ${host}    headers=${headers}    json=${payload}
    Set Suite Variable    ${RESPONSE}    ${response}

Create base64 encoded data for the log upload payload
    ${random_number}=    Generate Random String    16    [NUMBERS]
    ${plain_text}=       Set Variable    This is test number: ${random_number}
    ${encoded_text}=     Evaluate    base64.b64encode("${plain_text}".encode("utf-8")).decode("utf-8")    modules=base64    
    Set Suite Variable    ${DATA}    ${encoded_text}

Create log upload payload using the required parameters
    [Arguments]    ${PartitionKey}    ${StreamName}    ${Data}
    ${payload}=    Evaluate    {"Records": [{"Data": "${Data}", "PartitionKey": "${PartitionKey}"}], "StreamName": "${StreamName}"}    modules=json
    Set Suite Variable    ${LOG_UPLOAD_PAYLOAD}    ${payload}
    Log    ${LOG_UPLOAD_PAYLOAD}

Generate SHA-256 Hash from the payload
    [Arguments]    ${payload}
    ${sha256_hash}=    Evaluate  json.dumps(${payload})    modules=json
    ${sha256_hash}=    Convert Json To String    ${sha256_hash}
    Log    Converted Hash: ${sha256_hash}
    ${sha256_hash}=    Evaluate    hashlib.sha256(${sha256_hash}.encode('utf-8')).hexdigest()    modules=hashlib
    ${sha256_hash}    Set Variable    {"payload_hash": "${sha256_hash}"}
    ${sha256_hash}=    Convert String To Json    ${sha256_hash}
    Set Suite Variable    ${PAYLOAD_HASH}    ${sha256_hash}
    Log    ${PAYLOAD_HASH}

Extract signed headers
    [Arguments]    ${response}
    ${response_json}=    Convert String To Json    ${response}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}
    ${signed_ headers}=    Get From Dictionary    ${response_dictionary}    headers
    Set Suite Variable    ${LOG_UPLOAD_SIGNED_HEADERS}    ${signed_headers}
    Log    ${LOG_UPLOAD_SIGNED_HEADERS}

Validate Json Structure
    [Arguments]    ${actual_response}    ${expected_structure}
    ${response_json}=    Convert String To Json    ${actual_response.text}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}
    ${expected_structure}=    Convert To Dictionary    ${expected_structure}    
    Dictionary Should Contain Sub Dictionary    ${response_dictionary}    ${expected_structure}

Validate Json Structure Recursively
    [Arguments]    ${actual}    ${expected}
    FOR    ${key}    IN    @{expected.keys()}
        Run Keyword If    ${key} not in ${actual}    Fail    Missing key: ${key}
        Run Keyword If    Is Dictionary    ${expected[key]}
        ...    Validate Json Structure Recursively    ${actual[key]}    ${expected[key]}
    END

Verify the response code
    [Arguments]    ${response}    ${expected_code}
    Should Be Equal As Integers    ${response.status_code}    ${expected_code}

Verify PartitionKey from JSON response and extract it
    [Arguments]    ${response}
    ${response_json}=    Convert String To Json    ${response.text}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}

    ${partitionKey}=    Get From Dictionary    ${response_dictionary}    PartitionKey
    Should Not Be Empty    ${partitionKey}    PartitionKey is missing or empty
    Should Match Regexp    ${partitionKey}    ^[A-Za-z0-9]{32}$    PartitionKey is not alphanumeric or does not have a length of 32
    Set Suite Variable    ${PARTITION_KEY}    ${partitionkey}

Verify StreamName from JSON response and extract it
    [Arguments]    ${response}
    ${response_json}=    Convert String To Json    ${response.text}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}

    ${streamName}=    Get From Dictionary    ${response_dictionary}    StreamName
    Should Be String    ${streamName}    StreamName is not a string
    Should Start With    ${streamName}    sase-raw-logs-    StreamName does not start with 'sase-raw-logs-'

    ${env_data}=      Get Environment Configuration    ${env}
    ${environmentSuffix}=    Get From Dictionary    ${env_data}    environmentSuffix
    Should End With    ${streamName}    ${environmentSuffix}    StreamName does not end with environment suffix ${environmentSuffix}
    Set Suite Variable    ${STREAM_NAME}    ${streamName}

Verify log upload to kinesis response
    [Arguments]    ${response}

    ${response_json}=    Convert String To Json    ${response.text}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}
    
    # Verify 'FailedRecordCount'
    Dictionary Should Contain Key    ${response_dictionary}    FailedRecordCount
    Should Be Equal As Numbers    ${response_dictionary['FailedRecordCount']}    0    "'FailedRecordCount' should be 0"

    # Verify 'Records'
    Dictionary Should Contain Key    ${response_dictionary}    Records

    # Extract and verify the single record
    ${record}=    Get From List    ${response_dictionary['Records']}    0

    # Verify 'SequenceNumber'
    Dictionary Should Contain Key    ${record}    SequenceNumber
    ${sequence_number}=    Set Variable    ${record['SequenceNumber']}
    Should Match Regexp    ${sequence_number}    ^\\d{56}$    "SequenceNumber should be a 56-digit number"
    Set Suite Variable    ${SEQUENCE_NUMBER}    ${sequence_number}

    # Verify 'ShardId'
    Dictionary Should Contain Key    ${record}    ShardId
    ${shard_id}=    Set Variable    ${record['ShardId']}
    Should Match Regexp    ${shard_id}    ^shardId-\\d{12}$    "ShardId should match format 'shardId-<12 digits>'"
    Set Suite Variable    ${SHARD_ID}    ${shard_id}


Get environment configuration
    [Arguments]    ${env}
    ${env_data}=     Get From Dictionary    ${environments}    ${env}
    Run Keyword If    ${env_data} is None    Fail    Invalid environment: ${env}
    RETURN         ${env_data}

Get API headers
    [Arguments]    ${api_name}    ${env}
    ${headers_data}=     Get From Dictionary    ${api_headers}    ${api_name}
    Run Keyword If    ${headers_data} is None    Fail    Invalid API name: ${api_name}

    ${headers}=       Get From Dictionary    ${headers_data}    ${env}
    Run Keyword If    ${headers} is None    Fail    No headers defined for API: ${api_name} in environment: ${env}
    RETURN         ${headers}

Get API payload
    [Arguments]    ${api_name}    ${env}
    ${payload_data}=     Get From Dictionary    ${api_payloads}    ${api_name}
    Run Keyword If    ${payload_data} is None    Fail    Invalid API name: ${api_name}

    ${payload}=       Get From Dictionary    ${payload_data}    ${env}
    Run Keyword If    ${payload} is None    Fail    No payload defined for API: ${api_name} in environment: ${env}
    RETURN         ${payload}