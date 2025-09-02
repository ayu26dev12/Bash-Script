#!/bin/bash

# CONFIGURATION
CF_API_TOKEN="cloudflare_api"
ZONE_NAME="domain name"
RECORD_NAME="subdomain name"

# Get the current public IP
IP=$(curl -s http://ipv4.icanhazip.com)

# Get zone and record IDs
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

# Get current DNS record IP
CURRENT_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result.content')

# Only update if IP has changed
if [ "$IP" != "$CURRENT_IP" ]; then
  echo "Updating DNS record from $CURRENT_IP to $IP"

  UPDATE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\",\"ttl\":300,\"proxied\":false}")

  echo "$UPDATE" | jq
else
  echo "IP unchanged ($IP). No update needed."
fi

#######################################################################################################################################
#added cronjob to automatically public_ip update on cloudflare whenever instance will restart
@reboot /home/ubuntu/filename.sh >> /var/log/cloudflare-ddns.log 2>&1
