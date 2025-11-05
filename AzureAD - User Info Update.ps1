#The following Script is useful to Mass Update User info in Azure/365/Entra
#The Script will scan a CSV called "Users.csv" and search for the following columns, userPrincipleName, displayName, JobTitle, Department, OfficeLocation, BusinessPhones
#It will upload the info in each cell for each User, if a cell is blank it will skip that cell and move on

# Import required modules
Import-Module Microsoft.Graph.Users
Import-Module AzureAD

# Connect to Microsoft Graph
Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Connect to Azure AD
Connect-AzureAD

# Path to your CSV file
$csvPath = "C:\Path\To\Your\Users.csv"

# Import CSV
$users = Import-Csv -Path $csvPath

# Loop through each user in the CSV
foreach ($user in $users) {
    try {
        # Check if userPrincipleName is empty or null
        if ([string]::IsNullOrWhiteSpace($user.userPrincipleName)) {
            Write-Host "Skipping row with empty userPrincipleName: $($user.displayName)"
            continue
        }

        # Step 1: Update JobTitle, Department, and OfficeLocation using Microsoft Graph
        $userParams = @{}

        # Add JobTitle if not empty
        if (-not [string]::IsNullOrWhiteSpace($user.'Job Title')) {
            $userParams['JobTitle'] = $user.'Job Title'
        }

        # Add Department if not empty
        if (-not [string]::IsNullOrWhiteSpace($user.Department)) {
            $userParams['Department'] = $user.Department
        }
        else {
            Write-Host "Department is empty for $($user.userPrincipleName). Skipping Department update."
        }

        # Add OfficeLocation if not empty
        if (-not [string]::IsNullOrWhiteSpace($user.Location)) {
            $userParams['OfficeLocation'] = $user.Location
        }

        # Only update if there are non-empty fields
        if ($userParams.Count -gt 0) {
            Update-MgUser -UserId $user.userPrincipleName -BodyParameter $userParams
            Write-Host "Successfully updated JobTitle, Department, and OfficeLocation (if provided) for: $($user.userPrincipleName)"
        }
        else {
            Write-Host "No non-empty fields to update for JobTitle, Department, or OfficeLocation for: $($user.userPrincipleName)"
        }

        # Step 2: Attempt to update BusinessPhones using AzureAD
        $phoneNumber = $user.'Direct Numbers'
        if (-not [string]::IsNullOrWhiteSpace($phoneNumber)) {
            # Remove spaces, dashes, and parentheses (basic cleanup)
            $phoneNumber = $phoneNumber -replace '[\s\-\(\)]', ''
            # No +44 prefix

            try {
                # Update BusinessPhones using Set-AzureADUser
                Set-AzureADUser -ObjectId $user.userPrincipleName -TelephoneNumber $phoneNumber
                Write-Host "Successfully updated BusinessPhones for: $($user.userPrincipleName) using AzureAD"
            }
            catch {
                Write-Host "Error updating BusinessPhones for $($user.userPrincipleName) using AzureAD: $($_.Exception.Message). Other fields updated successfully."
            }
        }
        else {
            Write-Host "No phone number provided for $($user.userPrincipleName). Skipping BusinessPhones update."
        }
    }
    catch {
        if ($_.Exception.Message -match "Authorization_RequestDenied") {
            Write-Host "Permission denied for user $($user.userPrincipleName). Skipping entirely."
        }
        else {
            Write-Host "Error updating user $($user.userPrincipleName): $($_.Exception.Message)"
        }
    }
}

# Disconnect from Microsoft Graph and Azure AD
Disconnect-MgGraph
Disconnect-AzureAD
