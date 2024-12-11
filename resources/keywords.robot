*** Settings ***
Library           JSONLibrary
Library           Collections
Library           RequestsLibrary
Library           String
Library           SSHLibrary
Library           Process
Variables         ../config/Config.py  # Load environment, API headers, and payload configurations
         


*** Variables ***
${ENV}             # Default environment, can be overridden at runtime
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
&{KINESIS_SHARD_KEY_RESPONSE_STRUCTURE}    PartitionKey=    StreamName=    status=

${DEV4.PEM}             ../../RobotAutomation/config/dev4.pem  # Define the SSH PEM file
${CONTROL_PLANE_DOWN_COMMAND}    sudo /opt/bg/frontend/bin/frontend.sh offline    # Define the command to take the Control offline
${CONTROL_PLANE_UP_COMMAND}    sudo /opt/bg/frontend/bin/frontend.sh online      # Define the command to bring the Control onlinez

${SWG_LOGGING_DOWN_COMMAND}    docker stop swg-logging                 # Define the command to take the SWG logging down
${SWG_LOGGING_UP_COMMAND}    docker start swg-logging                 # Define the command to bring the SWG logging up

${CPU_EXHAUSTION_COMMAND}    stress --cpu 4 --timeout 60               # Define the command to exhaust the CPU
${RULE_CLEANED_UP_COMMAND}    sudo tc qdisc del dev ens5 root          # Define the command to clean up the network rules

${MEMORY_EXHAUSTION_COMMAND}    stress-ng --vm 2 --vm-bytes 80% --timeout 60s        # Define the command to exhaust the memory
${NETWORK_LATENCY_COMMAND}    sudo tc qdisc add dev ens5 root netem delay 800ms      # Define the command to add network latency    
${PACKET_LOSS_COMMAND}    sudo tc qdisc add dev ens5 root netem loss 30%              # Define the command to add packet loss

${STRESS_INSTALL_COMMAND}    sudo apt-get install stress
${STRESS-NG_INSTALL_COMMAND}    sudo apt-get install stress-ng

${HA_PROXY_LOG_COMMAND}    sudo tail -f /opt/bg/deploy/log/haproxy.log    | grep  -e "signed_kinesis_post" -e "kinesis_shard_key"
# ${HA_PROXY_LOG_COMMAND1}    sudo  tail  -f  /opt/bg/deploy/log/haproxy.log  arguments=|  grep  -e "signed_kinesis_post"  -e "kinesis_shard_key"

# ${JENKINS_COMMAND}     	sudo su jenkins
${first_part}    # Store the first part of the host name

${REDIS_CONNECTION_COMMAND}    redis-cli -h dev4-redis-swglogger.bgcloud.dev -p 6379


*** Keywords ***
Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName
    [Arguments]    ${alias}    ${api_name}    ${env}   ${response}    ${status_code}

    Send a Post request on the session                       mysession                        kinesis_shard_key     ${ENV}
    Set Suite Variable                                       ${KINESIS_SHARD_KEY_RESPONSE}    ${RESPONSE}
    Verify the response code                                 ${KINESIS_SHARD_KEY_RESPONSE}    ${status_code}
    Verify PartitionKey from JSON response and extract it    ${KINESIS_SHARD_KEY_RESPONSE}
    Verify StreamName from JSON response and extract it      ${KINESIS_SHARD_KEY_RESPONSE}
    

Send a Post request to the Signed Kinesis Post API to get the signed headers
    [Arguments]    ${alias}    ${api_name}    ${env}    ${payload_hash}    ${status_code}

    Create base64 encoded data for the log upload payload
    Create log upload payload using the required parameters  ${PARTITION_KEY}                             ${STREAM_NAME}        ${DATA}
    Generate SHA-256 Hash from the payload                   ${LOG_UPLOAD_PAYLOAD}
    Set Suite Variable                                       ${LOG_UPLOAD_PAYLOAD_HASH}                   ${PAYLOAD_HASH}
    Send a Post request on the session                       mysession                                    signed_kinesis_post   ${ENV}    ${PAYLOAD_HASH}
    Set Suite Variable                                       ${LOG_UPLOAD_SIGNED_KINESIS_POST_RESPONSE}   ${RESPONSE.text}
    Verify the response code                                 ${RESPONSE}                                  ${status_code}

Send a Post request to the Kinesis Log Upload API to verify the log upload
    [Arguments]    ${host}    ${headers}    ${payload}    ${status_code}

    Extract signed headers                 ${LOG_UPLOAD_SIGNED_KINESIS_POST_RESPONSE}
    Send a Post request                    ${KINESIS_HOST}                              ${LOG_UPLOAD_SIGNED_HEADERS}    ${LOG_UPLOAD_PAYLOAD}
    Set Suite Variable                     ${KINESIS_LOG_UPLOAD_RESPONSE}               ${RESPONSE}
    Verify the response code               ${KINESIS_LOG_UPLOAD_RESPONSE}               ${status_code}
    Verify log upload to kinesis response  ${KINESIS_LOG_UPLOAD_RESPONSE}

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
    Set Suite Variable     ${PARTITION_KEY}    ${partitionkey}

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
    Set Suite Variable     ${SEQUENCE_NUMBER}    ${sequence_number}

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

Open SSH Connection
    [Arguments]     ${env}    ${host_name}   ${user}    ${port}     ${DEV4.PEM}    
    ${env_data}=       Get environment configuration    ${env}
    ${ssh_host}=       Get From Dictionary    ${env_data}    ${host_name}
    ${ssh_user}=       Get From Dictionary    ${env_data}    ${user}
    ${ssh_port}=       Get From Dictionary    ${env_data}    ${port}
    Open Connection    ${ssh_host}    ${ssh_port}
    Login With Public Key    ${ssh_user}    ${DEV4.PEM}    
    Log    SSH connection established with ${ssh_host}

Run Command
    [Arguments]    ${command}
    ${output}=    Execute Command    ${command}
    Log   command executed. Output: ${output}
    
Fetching host from environment
    [Arguments]    ${env}    ${host_name}
    ${env_data}=       Get environment configuration    ${env}
    ${host}=           Get From Dictionary    ${env_data}    ${host_name}
    RETURN             ${host}
    
Split String by Period
    [Arguments]    ${env}    ${host_name}    
    ${env_data}=       Get environment configuration    ${env}
    ${split_list}=    Split String    ${host_name}    .
    ${first_part}=    Get From List    ${split_list}    0
    Log    ${first_part}
    Set Global Variable       ${first_part}

Verify Control Plane is Bypassed
    [Arguments]    ${env}    ${host_name}   ${user}    ${port}     ${PEM}    ${command}    ${control_plane_host_name}     ${swg_logging_host_name} 
    Open SSH Connection   ${env}    ${host_name}   ${user}    ${port}     ${PEM}
    ${stdout}=    Write    ${command}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    ${Logs_Output}=    Read    delay=10s
    log    ${Logs_Output}
    
    ${control_plane}=    Fetching host from environment    ${env}    ${control_plane_host_name}
    Split String by Period    ${env}    ${control_plane}
    Should Not Contain    ${Logs_Output}      ${first_part}

    ${swg}=    Fetching host from environment    ${env}    ${swg_logging_host_name}
    Split String by Period    ${env}    ${swg}    
    Should Contain    ${Logs_Output}      ${first_part}

   
    

