# Authenticate to Intune Graph API (Sample using interactive login)
# Install the required modules: AzureAD and Microsoft.Graph.Intune
# Connect to Azure AD
Connect-AzureAD

# Authenticate to Intune (Interactive login)
$graphToken = Get-AzureADToken -ResourceUrl "https://graph.microsoft.com"
$accessToken = $graphToken.AccessToken

# API endpoint for Intune devices
$intuneDevicesURL = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"

# Get devices from Intune
$devices = Invoke-RestMethod -Uri $intuneDevicesURL -Headers @{Authorization = "Bearer $accessToken"} -Method Get

# Loop through devices and perform actions
foreach ($device in $devices.value) {
    # Fetch the last signed-in user and update device owner
    # This part requires additional code to fetch user info and update device ownership
    # Use appropriate Graph API endpoints and methods to accomplish this
    # Example:
    # $lastSignedInUser = FetchLastSignedInUser($device.id)
    # UpdateDeviceOwner($device.id, $lastSignedInUser)
}

# Function to fetch last signed-in user
function FetchLastSignedInUser($deviceId) {
    # Implement code to retrieve last signed-in user details for a specific device
    # Use Intune Graph API to get user details associated with the device
    # Example:
    # $userDetails = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/userId" -Headers @{Authorization = "Bearer $accessToken"} -Method Get
    # return $userDetails
}

# Function to update device owner
function UpdateDeviceOwner($deviceId, $userInfo) {
    # Implement code to update device ownership information
    # Use Intune Graph API to update device properties with user details
    # Example:
    # Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId" -Headers @{Authorization = "Bearer $accessToken"} -Method Patch -Body $userInfo
}
