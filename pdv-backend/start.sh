#!/bin/bash
set -a
source .env
set +a
java -Dspring.profiles.active=prod -jar app.jar