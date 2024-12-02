*** Settings ***
Library           JSONLibrary
Library           Collections
Library           RequestsLibrary
Library           String
Library           OperatingSystem
Variables         ../config/Config.py  # Load environment, API headers, and payload configurations
Resource          ../resources/keywords.robot

*** Test Cases ***

Verify that the agent is able to get the required information and upload logs to Kinesis
    [Documentation]    This test case verifies that the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API
    Create API session                                                                   mysession        kinesis_shard_key             ${ENV}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession        kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession        signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}  ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200