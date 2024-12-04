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
    
Verify that the agent is able to get the required information and upload logs to Kinesis on a new session while control plane is down
    [Documentation]    This test case verifies that while control plane is down, on a new session, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API
    [Teardown]    Run Command                                                            ${CONTROL_PLANE_UP_COMMAND}

    Open SSH Connection                                                                  ${ENV}                           Control_Plane                 Default_User           Default_Port     ${PEM} 
    Run Command                                                                          ${CONTROL_PLANE_DOWN_COMMAND}
    Sleep    10 seconds
    Create API session                                                                   mysession                        kinesis_shard_key             ${ENV}    
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                        kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                        signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}                  ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200
    

Verify that the agent is able to get the required information and upload logs to Kinesis on an existing session while control plane is down
    [Documentation]    This test case verifies that while control plane is down, on an existing session, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API
    [Teardown]    Run Command                                                            ${CONTROL_PLANE_UP_COMMAND}

    Create API session                                                                   mysession                        kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                           Control_Plane                 Default_User           Default_Port     ${PEM} 
    Run Command                                                                          ${CONTROL_PLANE_DOWN_COMMAND}
    Sleep    10 seconds
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                        kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                        signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}                  ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200 
    

Verify that the agent is able to get the required information and upload logs to Kinesis when there is a network latency
    [Documentation]    This test case verifies that when there is a network latency, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API
    [Teardown]    Run Command                                                            ${RULE_CLEANED_UP_COMMAND}

    Create API session                                                                   mysession                    kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                       SWG_LOGGING_HOST3             Default_User           Default_Port     ${PEM}
    Run Command                                                                          ${NETWORK_LATENCY_COMMAND}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                    kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                    signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}              ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200    
    

Verify that the agent is able to get the required information and upload logs to Kinesis when there is a packet loss
    [Documentation]    This test case verifies that when there is a packet loss, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API
    [Teardown]    Run Command                                                            ${RULE_CLEANED_UP_COMMAND}
        
    Create API session                                                                   mysession                kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                   SWG_LOGGING_HOST3             Default_User           Default_Port     ${PEM}
    Run Command                                                                          ${PACKET_LOSS_COMMAND}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}          ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200    
    

