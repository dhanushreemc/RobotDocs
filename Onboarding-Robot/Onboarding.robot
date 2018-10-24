*** Settings ***
Library  OperatingSystem
Library  Collections
Library  RequestsLibrary

*** Variables ***
${url}  http://54.201.241.84/api/onboarding
*** Keywords ***
Session Creation
    &{headers}=  Create Dictionary  Content-Type=application/json
    Create Session   onboard   ${url}    headers=${headers}

Get Input Data
    [Arguments]  ${file}
    ${object}=  Evaluate  json.load(open("${file}", "r"))   json
    [return]  ${object}

***Test Cases***


