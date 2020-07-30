#!/bin/bash

set -eu

API_KEY=$1
COURSE_TEST_URL=$2
USER_KEY=$3

export INPUT_GRADE="good job, contact me @frozen6heart"
export INPUT_URL="good job, contact me @frozen6heart"
export INPUT_TOKEN="good job, contact me @frozen6heart"

TEST=${COURSE_TEST_URL##*/test-}
TEST_FULL="$TEST/test-"
SOLUTION="solution"
COURSE_ID=173

SOLUTION_URL="https://$USER_KEY@github.com/${GITHUB_REPOSITORY}"
TEST_URL="https://$USER_KEY@github.com/${COURSE_TEST_URL}"

printf "📝 hello $GITHUB_ACTOR\n"
printf "⚙️  building enviroment\n"
printf "⚙️  cloning solutions\n"
git clone $SOLUTION_URL $SOLUTION
git clone $TEST_URL $TEST
printf "⚙️  cloning finished\n"

find $TEST -type f -name '*test*' -print0 | xargs -n 1 -0 -I {} bash -c 'set -e; f={}; cp $f $0/${f:$1}' $SOLUTION ${#TEST_FULL}
curl_course=$(curl -w '' -s https://lrn.dev/api/curriculum/courses/${COURSE_ID} | jq -c '.lessons[] | select(.type=="project") | {name: .name, index: .index}')

send_result(){
    data=$(jq -aRs . <<< ${5})
    curl -s -X POST "https://lrn.dev/api/service/grade" -H "x-grade-secret: ${1}" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"username\":\"${2}\", \"lesson\":\"${3}\", \"status\": \"${4}\", \"logs\": ${data}}"
    echo ""
}

for project in $curl_course; do
    LESSON_NAME=$(echo $project | jq -r '.name' | sed s/-docker//g)
    echo $LESSON_NAME

    set +e
    result=$(echo "your test command" 2>&1)
    last="$?"
    set -e
    echo "${result}"
    
    if [[ $last -eq 0 ]]; then
        printf "✅ $LESSON_NAME-$TEST passed\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "done" "${result}"
    else
        printf "🚫 $LESSON_NAME-$TEST failed\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "failed" "${result}"
        exit 1
    fi
done

printf "👾👾👾 done 👾👾👾\n"
