#!/bin/bash

# This script is meant to execute n times a HTTP request

# If one command fails all the script fails
set -o errexit

# Global variables
times=$1
IFS=',' read -r -a test_cases <<< "$2"
hostname=$3
mkdir -p output
output_filename="/lclhome/jsoto128/$4"
echo "test_cases: $test_cases"

# Format to store HTTP response times
format="%{http_code},%{time_namelookup},%{time_connect},%{time_appconnect},%{time_pretransfer},%{time_redirect},%{time_starttransfer},%{time_total}"
file_header="http_code,time_namelookup,time_connect,time_appconnect,time_pretransfer,time_redirect,time_starttransfer,time_total"

#keep track of test cases that have finished
test1_finished=true
test2_finished=true
test3_finished=true
test4_finished=true
test5_finished=true

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
          test1_finished=true
          ;;
        2)
          run_test_case_2
          test2_finished=true
          ;;
        3)
          run_test_case_3
          test3_finished=true
          ;;
        4)
          run_test_case_4
          test4_finished=true
          ;;
        5)
          run_test_case_5
          test5_finished=true
          ;;
      esac
  done

  after_all
}

before_all(){
  # Services
  USERSERVICE="userservice"
  EDGESERVICE="edgeservice"
  TRIPMANAGEMENTCMD="tripmanagementcmd"
  TRIPMANAGEMENTQUERY="tripmanagementquery"
  CALCULATIONSERVICE="calculationservice"
  GMAPSADAPTER="gmapsadapter"

  # Gateway port
  EDGESERVICE_PORT=8080

  # Get token
  local url="$hostname:8091/oauth/token"
  local response=$(curl -X POST -s $url \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Authorization: Basic ZnJvbnQtZW5kOmZyb250LWVuZA==' \
    -H 'Accept: application/json' \
    -d 'grant_type=password&scope=webclient&username=passenger&password=password')
  token=$( echo $response | jq -r '.access_token' )

  # Get a valid tripId by creating a trip through the API
  local url="$hostname:$EDGESERVICE_PORT/$TRIPMANAGEMENTCMD/api/v1/trip"
  local response=$(curl -X POST \
    -s $url \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer ' $token \
    -H 'Accept: application/json' \
    -d '{ "originAddress": "Weston, FL", "destinationAddress": "Miami, FL", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }')
  tripId_tc4=${response:7:36}
}

after_all(){
  
  if($test1_finished && $test2_finished && $test3_finished && $test4_finished && $test5_finished); then
    echo "All test cases were executed."
  else
    echo "Some test cases were not executed."
  fi

  if [ "$test1_finished" != true ]; then
    echo "Test case 1 was not executed."
  fi
  if [ "$test2_finished" != true ]; then
    echo "Test case 2 was not executed."
  fi
  if [ "$test3_finished" != true ]; then
    echo "Test case 3 was not executed."
  fi
  if [ "$test4_finished" != true ]; then
    echo "Test case 4 was not executed."
  fi
  if [ "$test5_finished" != true ]; then
    echo "Test case 5 was not executed."
  fi

}

run_test_case_1(){
  test1_finished=false
  echo "Test case 1 started."
  local output_filename_1=$output_filename"_1.csv"
  rm -f $output_filename_1
  echo "1. Create Trip Use Case"
  echo $file_header |& tee -a $output_filename_1
  local url="$hostname:$EDGESERVICE_PORT/$TRIPMANAGEMENTCMD/api/v1/trip"
  for ((i=1;i<=$times;i++)); 
  do
    local response=$(curl -X POST \
      -w $format \
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
  echo "Test case 1 finished."
}

run_test_case_2(){
  test2_finished=false
  echo "Test case 2 started."
  local output_filename_2=$output_filename"_2.csv"
  rm -f $output_filename_2
  echo "2. Request Trip Estimate Use Case"
  echo $file_header |& tee -a $output_filename_2
  #local url="$hostname/api/v1/cost"
  local url="$hostname:$EDGESERVICE_PORT/$CALCULATIONSERVICE/api/v1/cost"
  for ((i=1;i<=$times;i++)); 
  do
    local response=$(curl -X POST \
      -w $format \
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
  echo "Test case 2 finished."
}

run_test_case_3(){
  test3_finished=false
  echo "Test case 3 started."
  local output_filename_3=$output_filename"_3.csv"
  rm -f $output_filename_3
  echo "3. Gmaps Adapter Request Use Case"
  echo $file_header |& tee -a $output_filename_3
  local url="$hostname:$EDGESERVICE_PORT/$GMAPSADAPTER/api/v1/directions/"
  for ((i=1;i<=$times;i++)); 
  do
    local response=$(curl -X POST \
      -w $format \
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
  echo "Test case 3 finished."
}

run_test_case_4(){
  test4_finished=false
  echo "Test case 4 started."
  local output_filename_4=$output_filename"_4.csv"
  rm -f $output_filename_4
  echo "4. Update Destination Use Case"
  echo $file_header |& tee -a $output_filename_4
  local tripId=$tripId_tc4

  # Update tripId_tc4 information with new destination address
  if [[ -z "$tripId" ]];
  then
    echo "tripId is empty. In order to execute this test case a tripId is required."
  else
    local url="$hostname:$EDGESERVICE_PORT/$TRIPMANAGEMENTCMD/api/v1/trip/update/$tripId"
    echo "url: $url"
    for ((i=1;i<=$times;i++)); 
    do
      local response=$(curl -X PUT \
        -w $format \
        -s $url \
		    --output /dev/null \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer ' $token \
        -H 'Accept: application/json' \
        --data-binary '{ "id": "'"$tripId"'", "originAddress": "Weston, FL", "destinationAddress": "11200 SW 8th St, Miami, FL 33199", "userId": "4eaf29bc-3909-49d4-a104-3d17f68ba672" }' )
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
  echo "Test case 4 finished."
}

run_test_case_5(){
  test5_finished=false
  echo "Test case 5 started."
  local output_filename_5=$output_filename"_5.csv"
  rm -f $output_filename_5
  echo "5. Request Trip Information Use Case"
  echo $file_header |& tee -a $output_filename_5
  local tripId=$tripId_tc4

  # Actual test case
  if [[ -z "$tripId" ]];
  then
    echo "tripId is empty. In order to execute this test case a tripID is required."
  else
    local url2="$hostname:$EDGESERVICE_PORT/$TRIPMANAGEMENTQUERY/api/v1/trip/$tripId"
    echo "url2: $url2"
    for ((i=1;i<=$times;i++)); 
    do
      local response=$(curl -X GET \
        -w $format \
        -s $url2 \
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
  echo "Test case 5 finished."
}

main "$@"
