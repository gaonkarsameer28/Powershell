# List of user principal names along with groups & Licenses from Azure AD or entra

$userPrincipalNames =@("user1@example.com", "user2@example.com", "user3@example.com")
# Initialize an array to store the results
$results = @()

foreach ($userPrincipalName in $userPrincipalNames) {
    Write-Output "Processing user: $userPrincipalName"
    
    # Get user object
    $user = Get-AzureADUser -ObjectId $userPrincipalName
    
    if ($null -eq $user) {
        Write-Output "User not found: $userPrincipalName"
        continue
    }
    
    # Get user groups
    $groups = Get-AzureADUserMembership -ObjectId $user.ObjectId | Select-Object -ExpandProperty DisplayName
    
    # Get user licenses
    $licenses = Get-AzureADUserLicenseDetail -ObjectId $user.ObjectId | ForEach-Object {
        $license = $_
        $sku = Get-AzureADSubscribedSku | Where-Object { $_.SkuId -eq $license.SkuId }
        [PSCustomObject]@{
            ProductName     = $sku.SkuPartNumber
            AssignmentPaths = ($license.AssignedPlans | Select-Object -ExpandProperty ServicePlanName) -join ", "
        }
    }
    
    # Add the results to the array
    foreach ($group in $groups) {
        $results += [PSCustomObject]@{
            UserPrincipalName = $userPrincipalName
            Group             = $group
            License           = $null
        }
    }
    
    foreach ($license in $licenses) {
        $results += [PSCustomObject]@{
            UserPrincipalName = $userPrincipalName
            Group             = $null
            License           = $license.ProductName + " (" + $license.AssignmentPaths + ")"
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "UserRolesGroupsLicenses.csv" -NoTypeInformation

Write-Output "Report generated: UserRolesGroupsLicenses.csv"
