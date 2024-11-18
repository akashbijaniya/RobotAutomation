*** Settings ***
Library           JSONLibrary
Library           Collections
Library           RequestsLibrary
Library           String
Variables         ../config/Config.py  # Load environment, API headers, and payload configurations

*** Variables ***
${ENV}            qac1  # Default environment, can be overridden at runtime

*** Test Cases ***
Test Kinesis Shard Key API
    ${response}=  Send API Request    kinesis_shard_key    ${ENV}
    Verify PartitionKey    ${response}
    Verify StreamName    ${response}

Test Signed Kinesis Post API
    ${response}=  Send API Request    signed_kinesis_post    ${ENV}
    Log    ${response.status_code}
    Log    ${response.text}

*** Keywords ***
Send API Request
    [Arguments]    ${api_name}    ${env}
    ${env_data}=      Get Environment Configuration    ${env}
    ${headers}=       Get API Headers    ${api_name}    ${env}
    ${payload}=       Get API Payload    ${api_name}    ${env}
    ${url}=           Get From Dictionary    ${env_data}    url

    ${response}=      POST    ${url}/api/${api_name}    headers=${headers}    json=${payload}
    RETURN          ${response}

Verify PartitionKey
    [Arguments]    ${response}
    ${response_json}=    Convert String To Json    ${response.text}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}

    ${partitionKey}=    Get From Dictionary    ${response_dictionary}    PartitionKey
    Should Be Empty    ${partitionKey}    PartitionKey is missing or empty
    Should Match Regexp    ${partitionKey}    ^[A-Za-z0-9]{36}$    PartitionKey is not alphanumeric or does not have a length of 32

Verify StreamName
    [Arguments]    ${response}
    ${response_json}=    Convert String To Json    ${response.text}
    ${response_dictionary}=    Convert To Dictionary    ${response_json}

    ${streamName}=    Get From Dictionary    ${response_dictionary}    StreamName
    Should Be String    ${streamName}    StreamName is not a string
    Should Start With    ${streamName}    sase-raw-logs-    StreamName does not start with 'sase-raw-logs-'

    ${env_data}=      Get Environment Configuration    ${env}
    ${environmentSuffix}=    Get From Dictionary    ${env_data}    environmentSuffix
    Should End With    ${streamName}    ${environmentSuffix}    StreamName does not end with environment suffix ${environmentSuffix}

Get Environment Configuration
    [Arguments]    ${env}
    ${env_data}=     Get From Dictionary    ${environments}    ${env}
    Run Keyword If    ${env_data} is None    Fail    Invalid environment: ${env}
    RETURN         ${env_data}

Get API Headers
    [Arguments]    ${api_name}    ${env}
    ${headers_data}=     Get From Dictionary    ${api_headers}    ${api_name}
    Run Keyword If    ${headers_data} is None    Fail    Invalid API name: ${api_name}

    ${headers}=       Get From Dictionary    ${headers_data}    ${env}
    Run Keyword If    ${headers} is None    Fail    No headers defined for API: ${api_name} in environment: ${env}
    RETURN         ${headers}

Get API Payload
    [Arguments]    ${api_name}    ${env}
    ${payload_data}=     Get From Dictionary    ${api_payloads}    ${api_name}
    Run Keyword If    ${payload_data} is None    Fail    Invalid API name: ${api_name}

    ${payload}=       Get From Dictionary    ${payload_data}    ${env}
    Run Keyword If    ${payload} is None    Fail    No payload defined for API: ${api_name} in environment: ${env}
    RETURN         ${payload}
