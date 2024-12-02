*** Settings ***
Library           JSONLibrary
Library           Collections
Library           RequestsLibrary
Library           String
Library           OperatingSystem
Variables         ../config/Config.py  # Load environment, API headers, and payload configurations
Resource          ../resources/keywords.robot

*** Test Cases ***

Verify that a POST API call to "/api/kinesis_shard_key/" endpoint returns a valid PartitionKey and StreamName
    [Documentation]    Verifies that the kinesis_shard_key API returns a valid PartitionKey and StreamName
    [Tags]    Sanity    Regression    API
    Create API session                                       mysession                        kinesis_shard_key     ${ENV}
    Send a Post request on the session                       mysession                        kinesis_shard_key     ${ENV}
    Set Suite Variable                                       ${KINESIS_SHARD_KEY_RESPONSE}    ${RESPONSE}
    Verify the response code                                 ${KINESIS_SHARD_KEY_RESPONSE}    200
    Verify PartitionKey from JSON response and extract it    ${KINESIS_SHARD_KEY_RESPONSE}
    Verify StreamName from JSON response and extract it      ${KINESIS_SHARD_KEY_RESPONSE}
    # Create base64 encoded data for the log upload payload
    # Create log upload payload using the required parameters  ${PARTITION_KEY}                 ${STREAM_NAME}        ${DATA}
    # Generate SHA-256 Hash from the payload                   ${LOG_UPLOAD_PAYLOAD}
    # Set Suite Variable                                       ${LOG_UPLOAD_PAYLOAD_HASH}       ${PAYLOAD_HASH}
    
Verify that a POST API call to "/api/signed_kinesis_post/" endpoint returns valid authorization headers
    [Documentation]    Verifies that the signed_kinesis_post API returns valid authorization headers
    [Tags]    Sanity    Regression    API
    Create base64 encoded data for the log upload payload
    Create log upload payload using the required parameters  ${PARTITION_KEY}                             ${STREAM_NAME}        ${DATA}
    Generate SHA-256 Hash from the payload                   ${LOG_UPLOAD_PAYLOAD}
    Set Suite Variable                                       ${LOG_UPLOAD_PAYLOAD_HASH}                   ${PAYLOAD_HASH}
    Send a Post request on the session                       mysession                                    signed_kinesis_post   ${ENV}    ${PAYLOAD_HASH}
    Set Suite Variable                                       ${LOG_UPLOAD_SIGNED_KINESIS_POST_RESPONSE}   ${RESPONSE.text}
    Verify the response code                                 ${RESPONSE}                                  200
    
Verify that the log is successfully uploaded to Kinesis
    [Documentation]    Verifies that the log is successfully uploaded to Kinesis
    [Tags]    Sanity    Regression    API
    Extract signed headers                 ${LOG_UPLOAD_SIGNED_KINESIS_POST_RESPONSE}
    Send a Post request                    ${KINESIS_HOST}                              ${LOG_UPLOAD_SIGNED_HEADERS}    ${LOG_UPLOAD_PAYLOAD}
    Set Suite Variable                     ${KINESIS_LOG_UPLOAD_RESPONSE}               ${RESPONSE}
    Verify the response code               ${KINESIS_LOG_UPLOAD_RESPONSE}               200
    Verify log upload to kinesis response  ${KINESIS_LOG_UPLOAD_RESPONSE}
