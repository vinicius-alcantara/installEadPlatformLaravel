#!/usr/bin/env bash
P_USER=${P_USER:-"admin"}
P_PASS=${P_PASS:-"xxxxx"}
P_URL=${P_URL:-"xxxxx"}
P_PRUNE=${P_PRUNE:-"false"}

if [ -z ${1+x} ]; then
  echo "Parameter #1 missing: stack name "
  exit 1
fi
TARGET="$1"

if [ -z ${2+x} ]; then
  echo "Parameter #2 missing: path to yml"
  exit
fi
TARGET_YML="$2"

echo "Creating $TARGET.........."
sleep 2;
echo "Logging in.........."
P_TOKEN=$(curl -s -X POST -H "Content-Type: application/json;charset=UTF-8" -d "{\"username\":\"$P_USER\",\"password\":\"$P_PASS\"}" "$P_URL/api/auth")
if [[ $P_TOKEN = *"jwt"* ]]; then
  echo " ....... success"
else
  echo "Result: failed to login!!!"
  exit 1
fi
T=$(echo $P_TOKEN | awk -F '"' '{print $4}')
#echo "Token: $T"

INFO=$(curl -s -H "Authorization: Bearer $T" "$P_URL/api/endpoints/1/docker/info")
#CID=$(echo "$INFO" | awk -F '"Cluster":{"ID":"' '{print $2}' | awk -F '"' '{print $1}')
#echo "Cluster ID: $CID"

#existing_env_json="$(echo -n "$TARGET"|jq ".Env" -jc)"

dcompose=$(cat "$TARGET_YML")
dcompose=${dcompose//$'\r'/''}
dcompose=${dcompose//$'"'/'\"'}

#echo "/-----READ_YML--------"

#echo "$dcompose"
#echo "\---------------------"
dcompose=${dcompose//$'\n'/'\n'}
data_prefix="{\"Name\":\"$TARGET\",\"StackFileContent\":\""
data_suffix="\",\"Env\":[]}"
sep="'"
echo "Converted JSON.........." 
sleep 2;
#echo "$data_prefix$dcompose$data_suffix"
#echo "\~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$data_prefix$dcompose$data_suffix" > json.tmp

echo "Creating stack.........."
CREATE=$(curl -s \
"$P_URL/api/stacks?endpointId=1&method=string&type=2" \
-X POST \
-H "Authorization: Bearer $T" \
-H "Content-Type: application/json;charset=UTF-8" \
            -H 'Cache-Control: no-cache'  \
            --data-binary "@json.tmp"
        )
rm json.tmp
#echo "Got response: $CREATE"
if [ -z ${CREATE+x} ]; then
  echo "Result: failure  to create"
  exit 1
else
  echo "Result: successfully created"
  docker container exec -d $TARGET sh /home/deploy/nochalks3-install.sh > nochalks3-install.log
  exit 0

fi



