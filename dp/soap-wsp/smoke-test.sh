#!/bin/bash

# For running locally
# export RELEASE_NAME=dp-pipe-rr
# export TARGET_NAMESPACE=integration

export SOUP_ROUTE_HTTPS=$(oc get route $RELEASE_NAME-calc-https -ojsonpath='{.spec.host}' -n $TARGET_NAMESPACE)

curl -k -X POST \
https://$SOUP_ROUTE_HTTPS/calculator.asmx \
-H 'Content-Type: text/xml' \
-H 'SOAPAction: http://tempuri.org/Add' \
-d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
<soapenv:Header/>
<soapenv:Body>
    <tem:Add>
        <tem:intA>123</tem:intA>
        <tem:intB>100</tem:intB>
    </tem:Add>
</soapenv:Body>
</soapenv:Envelope>'

ERR_CODE=$?

if [[ ERR_CODE -ne 0 ]]; then
    echo "Exit code not zero"
    exit 1
fi

