#!/bin/bash

# This script is meant to execute n times a HTTP request

# If one command fails all the script fails
set -o errexit

# Global variables
times=$1
IFS=',' read -r -a test_cases <<< "$2"
hostname=$3
output_filename=$4

# Expected usage
# Example: test_cases.sh 100 1,2,3,4,5 localhost output_filename
main () {

  if [[ (-z "$times") || (-z "$test_cases") ]]
  then
    echo "ERROR:
  One or more parameters are missing.

  Usage: test_cases.sh 100 1,2,3,4,5 localhost output_filename

Aborting.
    "
    exit 1
  fi

  before_all

  for element in "${test_cases[@]}"
  do
      case $element in
        1)
          run_test_case_1
          ;;
        2)
          run_test_case_2
          ;;
        3)
          run_test_case_3
          ;;
        4)
          run_test_case_4
          ;;
        5)
          run_test_case_5
          ;;
      esac
  done

  after_all
}

before_all(){
  # Format to store HTTP response times
  format="%{http_code},%{time_namelookup},%{time_connect},%{time_appconnect},%{time_pretransfer},%{time_redirect},%{time_starttransfer},%{time_total}"
  file_header="http_code,time_namelookup,time_connect,time_appconnect,time_pretransfer,time_redirect,time_starttransfer,time_total"

  # Gateway port
  EDGESERVICE_PORT=8080
  local url="$hostname:8091/oauth/token"
  local response=$(curl -X POST -s $url \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Authorization: Basic ZnJvbnQtZW5kOmZyb250LWVuZA==' \
    -H 'Accept: application/json' \
    -d 'grant_type=password&scope=webclient&username=passenger&password=password')
  token=$( echo $response | jq -r '.access_token' )
}

after_all(){
  echo "All test cases were executed."
}

run_test_case_1(){
  local output_filename_1=$output_filename"_1.csv"
  rm -f $output_filename_1
  echo "1. Create Trip Use Case"
  echo $file_header |& tee -a $output_filename_1
  local url="$hostname:$EDGESERVICE_PORT/trip-cmd/v1/trip/"
  for ((i=1;i<=$times;i++)); 
  do
    local response=$(curl -X POST \
      -w "@curl-format.txt" \
      --silent $url \
		  --output /dev/null \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ' $token \
      -H 'Accept: application/json' \
      -d '{ "originAddress": "Weston, FL", "destinationAddress": "Miami, FL", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }')
    echo $response |& tee -a $output_filename_1
    local status=${response:0:3}
    if [[ "$status" -ge "200" && "$status" -lt "300" ]];
    then
      echo "PASS"
    else
      echo "FAILS"
    fi
  done
  echo "Test case(s) finished."
}

run_test_case_2(){
  local output_filename_2=$output_filename"_2.csv"
  rm -f $output_filename_2
  echo "2. Request Trip Estimate Use Case"
  echo $file_header |& tee -a $output_filename_2
  local url="$hostname:$EDGESERVICE_PORT/calculation/api/v1/cost"
  for ((i=1;i<=$times;i++)); 
  do
    local response=$(curl -X POST \
      -w "@curl-format.txt" \
      -s $url \
		  --output /dev/null \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ' $token \
      -H 'Accept: application/json' \
      -d '{ "origin": "Weston, FL", "destination": "Miami, FL", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }' )
    echo $response |& tee -a $output_filename_2
    local status=${response:0:3}
    if [[ "$status" -ge "200" && "$status" -lt "300" ]];
    then
      echo "PASS"
    else
      echo "FAILS"
    fi
  done
  echo "Test case(s) finished."
}

run_test_case_3(){
  local output_filename_3=$output_filename"_3.csv"
  rm -f $output_filename_3
  echo "3. Gmaps Adapter Request Use Case"
  echo $file_header |& tee -a $output_filename_3
  local url="$hostname:$EDGESERVICE_PORT/gmapsadapter/api/v1/directions/"
  for ((i=1;i<=$times;i++)); 
  do
    local response=$(curl -X POST \
      -w "@curl-format.txt" \
      -s $url \
		  --output /dev/null \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ' $token \
      -H 'Accept: application/json' \
      -d '{ "origin": "2250 N Commerce Pkwy, Weston, FL 33326", "destination": "11200 SW 8th St, Miami, FL 33199", "departureTime": "15220998650000000" }')
    echo $response |& tee -a $output_filename_3
    local status=${response:0:3}
    if [[ "$status" -ge "200" && "$status" -lt "300" ]];
    then
      echo "PASS"
    else
      echo "FAILS"
    fi
  done
  echo "Test case(s) finished."
}

run_test_case_4(){
  local output_filename_4=$output_filename"_4.csv"
  rm -f $output_filename_4
  echo "4. Update Destination Use Case"
  echo $file_header |& tee -a $output_filename_4

  # Get a valid tripId by creating a trip through the API
  local url="$hostname:$EDGESERVICE_PORT/trip-cmd//v1/trip/"
  local response=$(curl -X POST \
    -s $url \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer ' $token \
    -H 'Accept: application/json' \
    -d '{ "originAddress": "Weston, FL", "destinationAddress": "Miami, FL", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }')
  local tripId=${response:7:36}

  # Actual test case
  if [[ -z "$tripId" ]];
  then
    echo "tripId is empty. In order to execute this test case a tripId is required."
  else
    local url="$hostname:$EDGESERVICE_PORT/trip-cmd/v1/trip/update/"$tripId
    for ((i=1;i<=$times;i++)); 
    do
      local response=$(curl -X PUT \
        -w "@curl-format.txt" \
        -s $url \
		    --output /dev/null \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer ' $token \
        -H 'Accept: application/json' \
        --data-binary '{ "id": "'$tripId'", "originAddress": "Weston, FL", "destinationAddress": "11200 SW 8th St, Miami, FL 33199", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }' )
      echo $response |& tee -a $output_filename_4
      local status=${response:0:3}
      if [[ "$status" -ge "200" && "$status" -lt "300" ]];
      then
        echo "PASS"
      else
        echo "FAILS"
      fi
    done
  fi
  echo "Test case(s) finished."
}

run_test_case_5(){
  local output_filename_5=$output_filename"_5.csv"
  rm -f $output_filename_5
  echo "5. Request Trip Information Use Case"
  echo $file_header |& tee -a $output_filename_5

  # Get a valid tripId by creating a trip through the API
  local url="$hostname:$EDGESERVICE_PORT/trip-cmd/v1/trip/"
  local response=$(curl -X POST \
    -s $url \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer ' $token \
    -H 'Accept: application/json' \
    -d '{ "originAddress": "Weston, FL", "destinationAddress": "Miami, FL", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }')
  local tripId=${response:7:36}

  # Actual test case
  if [[ -z "$tripId" ]];
  then
    echo "tripId is empty. In order to execute this test case a tripID is required."
  else
    local url="$hostname:$EDGESERVICE_PORT/trip-query/v1/trip/"$tripId
    for ((i=1;i<=$times;i++)); 
    do
      local response=$(curl -X GET \
        -w "@curl-format.txt" \
        -s $url \
		    --output /dev/null \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer ' $token \
        -H 'Accept: application/json' )
      echo $response |& tee -a $output_filename_5
      local status=${response:0:3}
      if [[ "$status" -ge "200" && "$status" -lt "300" ]];
      then
        echo "PASS"
      else
        echo "FAILS"
      fi
    done
  fi
  echo "Test case(s) finished."
}

main "$@"
