#!/bin/bash


# This script reads input from a CSV file and outputs the data in a JSON format.
# Check if a file named "output.json" exists in the same directory as the input file provided as an argument.
if [ -e "$(dirname "$1")/output.json" ]; then
    # If it exists, remove the file.
    rm "$(dirname "$1")/output.json" >/dev/null
fi
# Set the input and output file paths.
INPUT_FILE="$1"
OUTPUT_FILE="$(dirname "$1")/output.json"
# Cheks if the INPUT_FILE is path to output.txt 
if [[ "$INPUT_FILE" == "$(dirname "$1")/output.txt" || "$INPUT_FILE" == "$(realpath "$1")" || "$INPUT_FILE" = "output.txt" ]];then
# Extract various data from the input file using the cut command and store it in variables.
test_name=$(cut -d ',' -f 1 "$INPUT_FILE" | cut -d '[' -f 2 | cut -d ']' -f 1 | head -n 1)
test=$(cut -d ',' -f 2 "$INPUT_FILE" | cut -d ' ' -f 3 | head -n 1)
pordzeri_qanak=$(cut -d ',' -f 2 "$INPUT_FILE" | cut -d ' ' -f 2 | cut -b 4- | head -n 1)
success=$(cut -d '(' -f1 "$INPUT_FILE" | tail -n 1 )
failed=$(cut -d ',' -f 2  "$INPUT_FILE" | cut -d ' ' -f 2 | tail -n 1)
rate=$(cut -d ',' -f 3 "$INPUT_FILE" | cut -d ' ' -f 4 | tail -n 1)
full_duration=$(cut -d ',' -f 4 "$INPUT_FILE" | cut -d ' ' -f 3 | tail -n 1)
# Output the start of the JSON file with the test name and test cases array.
echo "{
        \"testName\": \"$test_name\",
        \"test\": [" >> "$OUTPUT_FILE"
# Use a loop to read each line of the input file corresponding to the test cases.
i=1
cat "$INPUT_FILE" | head -n $((pordzeri_qanak + 2)) | tail -n "$pordzeri_qanak" |  while read -r line; do
    # Determine if the current test case failed or passed.
    if echo "$line" | grep -q "^not" ; then
        status="false"
    else
        status="true"
    fi
    # Extract the duration and name fields from the current test case line.
    duration=$(echo "$line" | awk -F ',' '{print $NF}')
    name=$(echo "$line" |  awk -F '[0-9]*' '{print $(NF-1)}' | sed 's/,\s*$//')
    # Output the current test case as a JSON file part .
    if [ $i -eq $pordzeri_qanak ]; then
        echo "{
            \"name\": \"$name\",
            \"status\": $status,
            \"duration\": \"$duration\"
         }" >> "$OUTPUT_FILE"
    else
        echo "{
            \"name\": \"$name\",
            \"status\": $status,
            \"duration\": \"$duration\"
         }," >> "$OUTPUT_FILE"
    fi
    ((i++))
done
# Output the summary section of the JSON file with the success, failed, rating, and duration fields.
echo "],
            \"summary\": {
            \"success\": \"$success\",
            \"failed\":  \"$failed\",
            \"rating\": \"$rate\",
            \"duration\": \"$full_duration\"
        }
}" >> "$OUTPUT_FILE"
else
    # If the input file  doesnt equal to the path for file output.txt output an error message.
    echo "Error (Please try to provide the full path of output.txt file  as an  argument)."
fi
