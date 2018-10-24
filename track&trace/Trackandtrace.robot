*** Settings ***
Library  OperatingSystem
Library  Collections
Library  RequestsLibrary
Library  String

*** Variables ***
${url}   http://34.217.161.150/api/trackandtrace

*** Keywords ***
Session Creation
   &{headers}=  Create Dictionary  Content-Type=application/json
   Create Session   track   ${url}    headers=${headers}

Get Input Data
   [Arguments]  ${file}
   ${object}=  Evaluate  json.load(open("${file}", "r"))   json
   [return]  ${object}

Get Binary Data
   [Arguments]   ${file}
   ${data}=  Get binary file  ${file}
   [return]  ${data}

Get Result Data For Rate
   [Arguments]   ${data}
   ${result}=  Post Request  track  /fedex/rate  data=${data}
   [return]   ${result}


API Call To Get Response For Rate
   @{a}=  create list  fedex2dayam.json  fedexground.json   fedex2day.json   firstovernight.json   standardovernight.json  fedexxpress.json
   :FOR   ${i}  ${item}   IN ENUMERATE  @{a}
   \   ${data}=  Get Binary Data  ${item}
   #\   Log to Console  ${data}
   \   ${result}=  Get Result Data For Rate  ${data}
   \   ${object}=  Get Input Data  ${item}
   \   ${result}=  Get Result Data For Rate  ${data}
   #\   Log to Console  ${result.content}
   \   Run Keyword If  "${object['data']['RequestedShipment']['ServiceType']}" == "${result.json()['RateReplyDetails'][0]['ServiceType']}"  Should Be Equal  ${result.status_code}  ${200}
   \   Run Keyword If  "${object['data']['RequestedShipment']['RequestedPackageLineItems']['Weight']['Value']}" == "${result.json()['RateReplyDetails'][0]['RatedShipmentDetails'][0]['ShipmentRateDetail']['TotalBillingWeight']['Value']}"  Should Be Equal  ${result.status_code}  ${200}  
   

API Call To Get Response For Rate Limits
   @{a}=  create list  fedex2dayam.json  fedexground.json   fedex2day.json   firstovernight.json   standardovernight.json  fedexxpress.json
   :FOR   ${i}  ${item}   IN ENUMERATE  @{a}
   \   ${data}=  Get Binary Data  ${item}
   \   ${result}=  Get Result Data For Rate  ${data}
   \   ${object}=  Get Input Data  ${item}
   \   ${result}=  Get Result Data For Rate  ${data}
   \   ${length}=  Set Variable   ${object['data']["RequestedShipment"]["RequestedPackageLineItems"]["Dimensions"]["Length"]}
   \   ${width}=  Set Variable   ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Dimensions']['Width']}
   \   ${height}=  Set Variable   ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Dimensions']['Height']}
   \   ${valid}=  Evaluate  ${length}+2*(${height}+${width})
   #\   Log to Console  ${result.json()}
   \   Run Keyword If  ${valid} <= ${165}   Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   \    ...   ELSE   Should Be Equal   ${result.json()['HighestSeverity']}   ERROR

Get Rate Dimensions Details for fedexground
   ${object}=  Get Input Data  fedexground.json
   ${data}=  Get Binary Data  fedexground.json
   ${result}=  Get Result Data For Rate  ${data}
   ${length}=  Set Variable   ${object['data']["RequestedShipment"]["RequestedPackageLineItems"]["Dimensions"]["Length"]}
   ${width}=  Set Variable   ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Dimensions']['Width']}
   ${height}=  Set Variable   ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Dimensions']['Height']}
   ${valid}=  Evaluate  ${length}+2*(${height}+${width})
   Run Keyword If  ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Weight']['Value']} <= 150  Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   ...   ELSE  Should Be Equal   ${result.json()['HighestSeverity']}   ERROR
   Run Keyword If  ${object['data']["RequestedShipment"]["RequestedPackageLineItems"]["Dimensions"]["Length"]} <= 108  Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   ...   ELSE  Should Be Equal   ${result.json()['HighestSeverity']}   ERROR
   Run Keyword If  ${valid} <= ${165}   Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   ...   ELSE   Should Be Equal   ${result.json()['HighestSeverity']}   ERROR

Get Rate Dimensions Details for Express services
   @{a}=  create list  fedex2dayam.json  fedex2day.json   firstovernight.json   standardovernight.json  fedexxpress.json
   :FOR   ${i}  ${item}   IN ENUMERATE  @{a}
   \   ${data}=  Get Binary Data  ${item}
   \   ${result}=  Get Result Data For Rate  ${data}
   \   ${object}=  Get Input Data  ${item}
   \   ${result}=  Get Result Data For Rate  ${data}
   \   ${length}=  Set Variable   ${object['data']["RequestedShipment"]["RequestedPackageLineItems"]["Dimensions"]["Length"]}
   \   ${width}=  Set Variable   ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Dimensions']['Width']}
   \   ${height}=  Set Variable   ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Dimensions']['Height']}
   \   ${valid}=  Evaluate  ${length}+2*(${height}+${width})
   #\   Log to Console  ${result.json()}
   \   Run Keyword If  ${object['data']['RequestedShipment']['RequestedPackageLineItems']['Weight']['Value']} <= 150  Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   \   ...   ELSE   Should Be Equal   ${result.json()['HighestSeverity']}   ERROR 
   \   Run Keyword If  ${length} <= 119   Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   \   ...  ELSE  Should Be Equal   ${result.json()['HighestSeverity']}   ERROR
   \   Run Keyword If  ${valid} <= 165   Should Be Equal   ${result.json()['HighestSeverity']}   SUCCESS
   \    ...   ELSE   Should Be Equal   ${result.json()['HighestSeverity']}   ERROR



***Test Cases***

Fedex rate-services
   [Tags]  services
   Session Creation
   API Call To Get Response For Rate

Fedex rate : to check estimation will not be calculated if dimentions exceeds the limits 
   [Tags]  limits
   Session Creation
   API Call To Get Response For Rate Limits

Fedex rate : to check estimation will not be calculated if dimentions exceeds the limits for fedex ground
   [Tags]   ground
   Session Creation
   Get Rate Dimensions Details for fedexground

Fedex rate : to check estimation will not be calculated if dimentions exceeds the limits for fedex express
   [Tags]   express
   Session Creation
   API Call To Get Response For Rate Limits

Fedex Track: to track a shipment
   [Tags]   Track
   Session Creation
   ${data}=  Evaluate  json.load(open("track.json", 'r'))   json
   #${data}  create dictionary  data=${data["data"]}
   Log to console  ${data}
   ${result}=  Post Request  track  /fedex/track  data=${data}
   #Log to Console  ${result.content}

   #Log to Console  ${result.json()['CompletedTrackDetails'][0]['TrackDetails'][0]['TrackingNumber']}
   Run Keyword If  "${result.json()['CompletedTrackDetails'][0]['TrackDetails'][0]['TrackingNumber']}"=="${data['SelectionDetails']['PackageIdentifier']['Value']}"  Should Be Equal  ${result.status_code}  ${200}
   #Log to Console  ${result.json()['CompletedTrackDetails'][0]['TrackDetails'][0]['StatusDetail']['Description']}
   Run Keyword If  "${result.json()['CompletedTrackDetails'][0]['TrackDetails'][0]['StatusDetail']['Description']}"=="Delivered"  Should Be Equal  ${result.status_code}  ${200}



   


