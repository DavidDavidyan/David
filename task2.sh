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
number_of_test=$(cat "$INPUT_FILE" | tail -n 1 | cut -d ')' -f 1  | cut -d ' ' -f 3)
tests=$(tail -n +3 "$INPUT_FILE" | head -n -2)
results=$(tail -n 1 "$INPUT_FILE")
# Output the start of the JSON file with the test name.
echo "{
\"testName\": \"$test_name\",
\"test\": [" >> "$OUTPUT_FILE"
# Use a loop to read each line of the input file corresponding to the test cases.
# Set the input file separator as every new line.
IFS=$'\n'
x=1
# Check the status of each test and set the status variable to true or false accordingly.
    for i in $tests; do
        if [[ $i == not* ]]; then
            status=false
        else
            status=true
        fi
# Extract the name of the test from the input file and store it in the name variable.
        if [[ $i =~ expecting(.+?)[0-9] ]]; then
            var=${BASH_REMATCH[0]}
            name=${var%,*}
        fi
# Extract the duration of the test from the input file and store it in the duration variable.
        if [[ $i =~ [0-9]*ms ]]; then
            duration=${BASH_REMATCH[0]}
        fi
# Output the test data in JSON format.
	if [[ "$x" -eq "$number_of_test" ]]; then
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
  ((x++))
done
    for l in $results; do
# Extract the number of successful tests from the input file and store it in the success variable.
        if [[ $l =~ [0-9]+ ]]; then
            success=${BASH_REMATCH[0]}
        fi
# Extract the number of failed tests from the input file and store it in the failed variable
        if [[ $l =~ ,.[0-9]+ ]]; then
            v=${BASH_REMATCH[0]}
            failed=${v:2}
        fi
# Extract the rate and full duration
        if [[ $l =~ [0-9]+.[0-9]+% ]] || [[ $l =~ [0-9]+% ]]; then
            va=${BASH_REMATCH[0]}
            rate=${va%%%}
        fi
        if [[ $l =~ [0-9]*ms ]]; then
            full_duration=${BASH_REMATCH[0]}
        fi
echo "],
\"summary\": {
\"success\": \"$success\",
\"failed\":  \"$failed\",
\"rating\": \"$rate\",
\"duration\": \"$full_duration\"
}
}" >> "$OUTPUT_FILE"
done
else
# If the input file  doesnt equal to the path for file output.txt output an error message.
echo "Error (Please try to provide the full path of output.txt file  as an  argument)."
fi
