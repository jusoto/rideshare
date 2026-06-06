#!/bin/bash
set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Build all sub-project folders independently and tag the images with the appropriate names.



# This script builds all the docker images for the microservices in the project.
# Make sure to run this script from the root directory of the project.
find . -name gradlew -exec chmod +x {} \;
(cd ./discovery-service && ./gradlew build -x test)
docker build --tag aista/eureka:0.1 ./discovery-service/

docker build --tag aista/gmaps-adapter:0.1 ./gmaps-adapter/

docker build --tag aista/notification-service:0.1 ~/go/src/github.com/AITestingOrg/notification-service/
docker build --tag aista/calculation-service:0.1 ~/go/src/github.com/AITestingOrg/calculation-service/

(cd ./user-service && ./gradlew build -x test)
docker build --tag aista/user-service:0.1 ./user-service/

(cd ./edge-service && ./gradlew build -x test)
docker build --tag aista/edge-service:0.1 ./edge-service/

(cd ./trip-management-query && ./gradlew build -x test)
docker build --tag aista/trip-management-query:0.1 ./trip-management-query/

(cd ./trip-management-cmd && ./gradlew build -x test)
docker build --tag aista/trip-management-cmd:0.1 ./trip-management-cmd/

(cd ./driver-query && ./gradlew build -x test)
docker build --tag aista/driver-query:0.1 ./driver-query/

(cd ./driver-cmd && ./gradlew build -x test)
docker build --tag aista/driver-cmd:0.1 ./driver-cmd/

(cd ./passenger && ./gradlew build -x test)
docker build --tag aista/passenger:0.1 ./passenger/