#!/bin/bash
# Check if a file named "accounts_new.csv" exists in the same directory as the input file provided as an argument.
if [ -e "$(dirname "$1")/accounts_new.csv" ]; then
    rm "$(dirname "$1")/accounts_new.csv" >/dev/null
fi
# Check if a file named "Accounts.info" exists in the same directory as the input file provided as an argument and remove it.
if [ -e "$(dirname "$1")/Accounts.info" ]; then
    rm -rf "$(dirname "$1")/Accounts.info" >/dev/null
fi
# Check if a file named "modified_accounts" exists in the same directory as the input file provided as an argument and remove it.
if [ -e "$(dirname "$1")/modified_accounts" ]; then
    rm -rf "$(dirname "$1")/modified_accounts" >/dev/null
fi
# Get the passed argument.
INPUT_FILE="$1"
# Set the HELP_FILE and OUTPUT_FILE variables to the paths where the script will output information.
HELP_FILE="$(dirname "$1")/modified_accounts"
OUTPUT_FILE="$(dirname "$1")/accounts_new.csv"
# Create a directory named "Accounts.info".
mkdir "$(dirname "$1")"/Accounts.info
# Check if the provided argument is the absolute or relative path to  accounts.csv.  
if [[ "$INPUT_FILE" == "$(dirname "$1")/accounts.csv" || "$INPUT_FILE" == "$(realpath "$1")" || "$INPUT_FILE" == "accounts.csv" ]]; then
    # Write the header of the input file to the OUTPUT_FILE.
    head -n 1 "$INPUT_FILE" > "$OUTPUT_FILE"
    # With sed command change the commas in the double quotes with ':'.
    # Use a pipe (|) to send the output to the next command.
    # Change the delimiter  from comma to '|'
    # Delete the empty space between the last word of comma and the following delimiter
    # Use tail command to skip the header line, and the while loop that  reads each line of the output.
    sed 's/"\([^"]*\),\([^"]*\)"/"\1:\2"/g'  "$INPUT_FILE" | column -s , -o '|' -t | sed 's/ \+|/|/g' | tail -n +2 | while read -r line; do 
	# Extract the values of the different columns of the INPUT_FILE and save them into variables. 
	# Also write some of these values into separate files located in the "Accounts.info" directory.
        id=$(echo "$line" | cut -d '|' -f 1) 
        echo "$id" >>  "$(dirname "$1")"/Accounts.info/id.accounts 
        location_id=$(echo "$line" | cut -d '|' -f 2) 
        name=$(echo "$line" | cut -d '|' -f 3) 
        title=$(echo "$line" | cut -d '|' -f 4 | sed 's/:/,/g' ) 
        echo "$title" >> "$(dirname "$1")"/Accounts.info/title.accounts
        email=$(echo "$line" | cut -d '|' -f 5)
        department=$(echo "$line" | cut -d '|' -f 6) 
        echo "$department" >> "$(dirname "$1")"/Accounts.info/department.accounts
	# Extract the first and last names from the "name" column.
	# Capitalize the first letter and lower remaining letters of each name, and concatenate them.
        first_name=$(echo "$name" | cut -d " " -f 1 | sed 's/\([[:alpha:]]\)\([[:alpha:]]*\)/\U\1\L\2/g') 
	last_name=$(echo "$name" | cut -d " " -f 2 | sed 's/\([[:alpha:]]\)\([[:alpha:]]*\)/\U\1\L\2/g')
	full_name=$(echo "$first_name $last_name")
	echo "$full_name" >> "$(dirname "$1")"/Accounts.info/full_name.accounts
	# Generate the email prefix from the first letter of the first name and the last name.
	# Convert it to lowercase, and append the domain name.
        first_letter_of_first_name=$(echo "$first_name" | cut -b1)
        email_prefix=$(echo "$first_letter_of_first_name$last_name" | tr '[:upper:]' '[:lower:]')
        formatted_email=$(echo "$email_prefix@abc.com")
	# Write the processed fields to the HELP_FILE.
        echo "$id|$location_id|$full_name|$title|$formatted_email|$department" >> "$HELP_FILE" 
    done
    # Extract the email prefix from each line in the $HELP_FILE and output only the text before the '@' character.
    # Extract the last field from each (email prefix) line of output produced from first part of command by using the '|' character as the field separator.
    # The last part of code is a  command that  counts the number of occurrences of each unique email prefix produced in action before.
    # It does that by using an associative array a to store the count of each email prefix, and another array b to store the corresponding email prefix  name.
    # And then  print out the frequency count and the email prefix name for each unique email prefix found in the input file.
    cut -d "@" -f1 "$HELP_FILE" | awk -F '|'  '{print $NF}' | awk '{a[$0]++; b[NR]=$0} END {for (i=1;i<=NR;i++) print a[b[i]], b[i]}'  > "$(dirname "$1")"/Accounts.info/counts.txt
    # Extract the location_ids from the HELP_FILE and save them to a file called location_ids in the Accounts.info directory. 
    cut -d '|' -f 2 "$HELP_FILE"  > "$(dirname "$1")"/Accounts.info/location_ids  
 	# Loop through each line in the HELP_FILE and generate a new line of output for each one.
	# For each line, the id, location_id, full_name, title, department  are extracted.
	# The email is formatted based on the number of occurrences of the email domain and the location_id.
	# The line of output is then written to the OUTPUT_FILE.
        while read -r line; do
        count=$(echo "$line" | cut -d '|' -f 1 | awk   '{print $1}')
        mails=$(echo "$line" | cut -d '|' -f 1 | awk  '{print $2}')
        location_id=$(echo "$line" | awk -F '|' '{print $2}')
	id=$(echo "$line" | awk  -F '|' '{print $3}')
	department=$(echo "$line" | awk -F '|' '{print $6}')
	full_name=$(echo "$line" | awk -F '|' '{print $4}')
	title=$(echo "$line" | awk  -F '|' '{print $5}')
	# Format the email based on the number of occurrences of the email domain and the location_id.
        if [[ "$count" -eq 1 ]]; then
            final_email=$(echo "$mails@abc.com")
        else
            final_email=$(echo "$mails$location_id@abc.com")
        fi
	# Write the line of output to the OUTPUT_FILE.
        echo "$id,$location_id,$full_name,$title,$final_email,$department" >> "$OUTPUT_FILE"
    done < <(paste -d '|' "$(dirname "$1")"/Accounts.info/counts.txt "$(dirname "$1")"/Accounts.info/location_ids  "$(dirname "$1")"/Accounts.info/id.accounts  "$(dirname "$1")"/Accounts.info/full_name.accounts "$(dirname "$1")"/Accounts.info/title.accounts  "$(dirname "$1")"/Accounts.info/department.accounts )
# Remove the HELP_FILE and the Accounts.info directory.
rm -rf  "$HELP_FILE"
rm -rf  "$(dirname "$1")"/Accounts.info

# If the input file is not "accounts.csv" or path to "accounts.csv", print an error message.
else 
    echo "Error: Provided argument is the path  path to accounts.csv file."
    echo "(Please  provide the  path to the accounts.csv file as an  argument.) ."
fi
