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
    [Tags]    Sanity    Regression    API    SSE-3067
    Create API session                                                                   mysession        kinesis_shard_key             ${ENV}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession        kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession        signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}  ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200
    
Verify that on a new session when control plane is down, agent is able to get the required information and upload logs to Kinesis
    [Documentation]    This test case verifies that while control plane is down, on a new session, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API    SSE-3068
    [Teardown]    Run Command                                                            ${CONTROL_PLANE_UP_COMMAND}

    Open SSH Connection                                                                  ${ENV}                           CONTROL_PLANE_HOST                 Default_User           Default_Port     ${DEV4.PEM} 
    Run Command                                                                          ${CONTROL_PLANE_DOWN_COMMAND}
    Sleep    10 seconds
    Create API session                                                                   mysession                        kinesis_shard_key             ${ENV}    
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                        kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                        signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}                  ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200
    

Verify that on an existing session when control plane is down, agent is able to get the required information and upload logs to Kinesis
    [Documentation]    This test case verifies that while control plane is down, on an existing session, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API    SSE-3069
    [Teardown]    Run Command                                                            ${CONTROL_PLANE_UP_COMMAND}

    Create API session                                                                   mysession                        kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                           CONTROL_PLANE_HOST                 Default_User           Default_Port     ${DEV4.PEM} 
    Run Command                                                                          ${CONTROL_PLANE_DOWN_COMMAND}
    Sleep    10 seconds
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                        kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                        signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}                  ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200 
    

Verify that when there is a network latency, agent is still able to get the required information and upload logs to Kinesis
    [Documentation]    This test case verifies that when there is a network latency, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API    SSE-3070
    [Teardown]    Run Command                                                            ${RULE_CLEANED_UP_COMMAND}

    Create API session                                                                   mysession                    kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                       SWG_LOGGING_HOST3             Default_User           Default_Port     ${DEV4.PEM}
    Run Command                                                                          ${NETWORK_LATENCY_COMMAND}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                    kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                    signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}              ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200    
    

Verify that when there is a packet loss, the agent is still able to get the required information and upload logs to Kinesis when there is a packet loss
    [Documentation]    This test case verifies that when there is a packet loss, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API    SSE-3071
    [Teardown]    Run Command                                                            ${RULE_CLEANED_UP_COMMAND}
        
    Create API session                                                                   mysession                kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                   SWG_LOGGING_HOST3             Default_User           Default_Port     ${DEV4.PEM}
    Run Command                                                                          ${PACKET_LOSS_COMMAND}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}          ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200    
    
Verify that when CPU is stressed out on swg-logging service, the agent is still able to get the required information and upload logs to Kinesis
    [Documentation]    This test case verifies that when CPU is stressed out on swg-logging service, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API    SSE-3072
    [Teardown]    Run Command                                                            ${RULE_CLEANED_UP_COMMAND}
        
    Create API session                                                                   mysession                kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                   SWG_LOGGING_HOST3             Default_User           Default_Port     ${DEV4.PEM}
    Run Command                                                                          ${STRESS_INSTALL_COMMAND}
    Run Command                                                                          ${CPU_EXHAUSTION_COMMAND}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}          ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200

Verify that when Memory is stressed out on swg-logging service, the agent is still able to get the required information and upload logs to Kinesis
    [Documentation]    This test case verifies that when Memory is stressed out on swg-logging service, the shard key api returns valid partition key and stream name, signed kinesis post api returns valid signed headers and log upload api successfully uploads logs to kinesis.
    [Tags]    Sanity    Regression    API    SSE-3073
    [Teardown]    Run Command                                                            ${RULE_CLEANED_UP_COMMAND}
        
    Create API session                                                                   mysession                kinesis_shard_key             ${ENV} 
    Open SSH Connection                                                                  ${ENV}                   SWG_LOGGING_HOST3             Default_User           Default_Port     ${DEV4.PEM}
    Run Command                                                                          ${STRESS-NG_INSTALL_COMMAND}
    Run Command                                                                          ${MEMORY_EXHAUSTION_COMMAND}
    Send a Post request to the Kinesis Shard Key API to get PartitionKey and StreamName  mysession                kinesis_shard_key             ${ENV}                 ${RESPONSE}      200
    Send a Post request to the Signed Kinesis Post API to get the signed headers         mysession                signed_kinesis_post           ${ENV}                 ${PAYLOAD_HASH}  200
    Send a Post request to the Kinesis Log Upload API to verify the log upload           ${KINESIS_HOST}          ${LOG_UPLOAD_SIGNED_HEADERS}  ${LOG_UPLOAD_PAYLOAD}  200

Verify that the agent is able to get the required information and upload logs to Kinesis while the control plane is bypassed.
    [Documentation]    This test case verifies that the agent is able to get the required information and upload logs to Kinesis while the control plane is bypassed.
    [Tags]    Sanity    Regression    API    SSE-
    
    Create API session                                                                 mysession                         kinesis_shard_key         ${ENV} 
    Verify Control Plane is Bypassed                                                 ${ENV}                            HA_PROXY_HOST             Default_User           Default_Port     ${DEV4.PEM}    ${HA_PROXY_LOG_COMMAND}    CONTROL_PLANE_HOST          SWG_LOGGING_HOST3

    # Open SSH Connection                                                              ${ENV}                            JENKINS_HOST              Default_User           Default_Port     ${DEV4.PEM}
    # Run Command                                                                      ${JENKINS_COMMAND}
    # Run Command                                                                      ${HA_PROXY_LOG_COMMAND}
    # Verify Control Plane is Bypassedd                                                  ${ENV}                            JENKINS_HOST              Default_User           Default_Port     ${DEV4.PEM}    ${IDENTITY_FILE}    ${JENKINS_COMMAND}         ${HA_PROXY_LOG_COMMAND1}    CONTROL_PLANE_HOST    SWG_LOGGING_HOST3