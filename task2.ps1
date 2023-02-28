#Parameters declaration
param(
  [Parameter(Mandatory=$true)]
  [string]$FilePath
)

# Check if the file name is "accounts.csv"
if(-not($FilePath.EndsWith("\accounts.csv"))){
  Write-Error "Invalid file path. Please provide the absolute path to the 'accounts.csv' file."
}
#Import the CSV file with the given path
$inputFile = Import-Csv $FilePath
# Get the directory path of the input file
$dirPath = Split-Path $FilePath
$helpFile = Join-Path $dirPath "modified.accounts"
# Create the output file path in the same directory as the input file
$outputFile = Join-Path $dirPath "accounts_new.csv"
# If the output file already exists, delete it
if (Test-Path $outputFile) {
  Remove-Item $outputFile
}
#If the file "Accounts.info" already exists in the directory, delete it
if (Test-Path (Join-Path $dirPath "Accounts.info")) {
  Remove-Item (Join-Path $dirPath "Accounts.info") -Recurse -Force
}
#Create a new directory "Accounts.info"
New-Item -ItemType Directory (Join-Path $dirPath "Accounts.info")
#Create a new empty hash set to store email addresses
$Emails = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
#Loop through each line in the input file
foreach ($line in $inputFile) {
    #Write the id to a file and append it to the existing content
    $id = $line.id | Out-File (Join-Path (Join-Path $dirPath "Accounts.info") "id.accounts") -Append
    #Write the location_id to a file and append it to the existing content   
    $location_id = $line.location_id | Out-File (Join-Path (Join-Path $dirPath "Accounts.info") "locationid.accounts") -Append
    #Assign the value of the "name" property to a variable
    $name = $line.name
    #Write the title to a file and append it to the existing content
    $title = $line.title | Out-File (Join-Path (Join-Path $dirPath "Accounts.info") "title.accounts") -Append
    #Write the department to a file and append it to the existing content
    $department = $line.department |  Out-File (Join-Path (Join-Path $dirPath "Accounts.info") "department.accounts") -Append
    #Convert the name to lowercase and assign it to a variable
    $fullName = ""
if (![string]::IsNullOrEmpty($line.name)) {
    $fullName = $line.name.ToLower()
}
#Get the first name and capitalize the first letter
$firstName = $fullName.Substring(0,1).ToUpper() + $fullName.Substring(1).Split(" ")[0].ToLower()
#Get the last name and capitalize the first letter
$lastName = $fullName.Substring($fullName.IndexOf(" ") + 1,1).ToUpper() + $fullName.Substring($fullName.IndexOf(" ") + 2).ToLower()
if ($lastName.Contains("-")) {
    $lastNameParts = $lastName.Split("-")
    $capitalizedParts = @()
    # Capitalize each part of the double-surname
    foreach ($part in $lastNameParts) {
        $capitalizedParts += $part.Substring(0,1).ToUpper() + $part.Substring(1).ToLower()
    }$lastName = $capitalizedParts -join "-"
} else {
    $lastName = $lastName.Substring(0,1).ToUpper() + $lastName.Substring(1).ToLower()
}

#Combine the first and last name and assign it to the "name" property
$line.name = $firstName + " " + $lastName | Out-File (Join-Path (Join-Path $dirPath "Accounts.info") "full_name.accounts") -Append
    #Create email prefix and email variables for each person
    $email_prefix = ($firstName[0] + $lastName).toLower()
    $line.email = ($firstName[0] + $lastName + "@abc.com").toLower()
    }
#Convert input file to CSV format and replace quotes and commas with pipes
$csvString = $inputFile | ConvertTo-Csv -NoTypeInformation
$csvString = $csvString -replace  '"',''
$csvString = $csvString -replace ',','|'
$csvString | Out-File -FilePath $helpFile -Encoding UTF8

  #Get email addresses from helpFile and count the occurrences of each email
  $emails = Get-Content $helpFile  | ForEach-Object { $_.Split("@")[0] } | ForEach-Object { $_.Split("|")[-1] } 
  
 foreach ($mail in $emails) {
  $count = 0
  foreach ($lineToCheck in $emails) {
    if ($lineToCheck -eq $mail) {
      $count++
    }
    
  }
   #Write the email count to a file
  "$count $mail " |  Out-File (Join-Path (Join-Path $dirPath "Accounts.info") "counts.accounts") -Append
  }

  # Get the contents of the files
$counts = Get-Content -Path "$dirPath\Accounts.info\counts.accounts"
$locationids = Get-Content -Path "$dirPath\Accounts.info\locationid.accounts"


# Loop through each line in the counts file, starting with the second line
for ($i = 1; $i -lt $counts.Count; $i++) {
    # Get the location ID from the corresponding line in the locationids file
    $locationid = $locationids[$i-1]

    # Add the location ID to the end of the current line in the counts file
    $counts[$i] += "$locationid"
}

# Write the modified counts file 
$counts | Out-File "$dirPath/Accounts.info/counts.accounts" -Encoding UTF8
$counts_content =  Get-Content "$dirPath/Accounts.info/counts.accounts"  | Select-Object -Skip 1


foreach ($line in $counts_content) {
    # Split the line into the 3 columns
    $count, $email , $location_id= $line.Split(" ")

    # Build the email address with the corresponding location ID
    if ($count -gt 1) {
      
        $emailprefix = "$email$location_id@abc.com"
    } else {
        $emailprefix = "$email@abc.com"
    }
      $emailprefix | Out-File "$dirPath/Accounts.info/emails.accounts" -Append
    }
   #Get the contents of all account info files
   $columnemail = Get-Content "$dirPath/Accounts.info/emails.accounts"
   $columnid = Get-Content "$dirPath/Accounts.info/id.accounts" 
   $columnlocation_id = Get-Content "$dirPath/Accounts.info/locationid.accounts"
   $columnname = Get-Content "$dirPath/Accounts.info/full_name.accounts"
   $columntitle = Get-Content "$dirPath/Accounts.info/title.accounts"
   $columndepartment = Get-Content "$dirPath/Accounts.info/department.accounts"

   #Build the rows with all columns
   $rows = for ($i = 0; $i -lt $columnid.Count; $i++) {
    [PSCustomObject]@{
        id = $columnid[$i]
        location_id = $columnlocation_id[$i]
        name = $columnname[$i]
        title = $columntitle[$i]
        email = $columnemail[$i]
        department = $columndepartment[$i]
    }
}

# Remove created files and directories
Remove-Item "$dirPath/Accounts.info" -Recurse -Force
Remove-Item "$helpFile" -Recurse -Force 
 # Export the combined data to a CSV file  
$csvString = $rows | ConvertTo-Csv -NoTypeInformation
$csvString | Out-File -FilePath $outputFile -Encoding UTF8