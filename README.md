# Azure AD MFA PowerShell Utilities

This repo will contain a set of Azure AD MFA scripts for rolling out MFA to end-users. This is related to utilizing [Azure AD Identity Protection](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/overview-identity-protection) for a specific subset of users in your Azure AD tenant.

⚠️ Please keep in mind that this is not _**"production ready"**_. This repo is currently designed for my personal use only for the time being.

## Building

### Requirements

- [.NET SDK 5.0](https://dotnet.microsoft.com/download)
    - **Since I have not supplied a prebuilt module yet, this will be a requirement to build.**
- PowerShell
    - [x] **Recommended**: [PowerShell 7.0 or higher](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
    - [ ] At the minimum, `Windows PowerShell 5.1` should work; however, I have not done any testing with it.
- Platforms:
    - **Windows 10**
        - [x] _Tested on the `20H2` feature update release_
    - **macOS**
        - [x] _Tested on Big Sur `11.2.3`_
    - **Linux**
        - [ ] _Untested on any distro_

### Using Visual Studio Code

1. Open up the source code's directory with `Visual Studio Code`.
2. Run the build task by either:
    - Clicking `Terminal -> Run build task...` in the menu bar
    - Using the keyboard shortcut
        - **Windows/Linux**: `Shift+Ctrl+B`
        - **macOS**: `Shift+Cmd+B`
3. Wait for the build script to finish.
4. Once the build script is finished, the module will be located in the `/build/` directory.

### Using a PowerShell console

1. Set your current directory, using `cd` or `Set-Location`, in the console to the source code.
2. Run this command: `.\RunModuleBuild.ps1`
3. Wait for the build script to finish.
4. Once the build script is finished, the module will be located in the `/build/` directory.

### ⚠️ Note for Windows users ⚠️

If an error occurs on **Windows** platforms regarding the _"Execution Policy"_, then you need to change it. Easiest solution is to run this command before running the build script:

```powershell
Set-ExecutionPolicy -ExecutionPolicy "Unrestricted"
```

Once the execution policy has been changed, re-run the build script command.

❗ **Changing the execution policy to `Bypass` or `Unrestricted` can be a security risk. If your computer is managed by you workplace, the execution policy may be forced to not allow any unsigned code to execute.**

For more information about the PowerShell Execution Policy, you can read the [official documentation for it here](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

## PowerShell Dependencies

This module is dependant on two modules (At the moment):
- [Microsoft.Graph.Authentication](https://www.powershellgallery.com/packages/Microsoft.Graph.Authentication/)
- [Microsoft.Graph.Groups](https://www.powershellgallery.com/packages/Microsoft.Graph.Groups/)

The easiest solution to resolve these dependencies is to install the [Microsoft.Graph](https://www.powershellgallery.com/packages/Microsoft.Graph) module from PowerShell Gallery by running this command:

```powershell
Install-Module -Name "Microsoft.Graph"
```

The `Microsoft.Graph.Authentication` module is the primary work-horse for interacting with the Microsoft Graph API. The majority of API calls are made from the context created after `Connect-MgGraph` is ran, but not through the official cmdlets. The `System.Net.HttpClient` for making those API calls is created with the `Microsoft.Graph.PowerShell.Authentication.Helpers.HttpHelpers` class' `GetGraphHttpClient(<IAuthContext>authContext)` method.

## Configuring Microsoft.Graph

Due to the nature of how the Microsoft Graph API works, there are some scope permissions you have to configure before you can run the commands in this module successfully. Those scopes are:

- `User.Read.All`
- `UserAuthenticationMethod.Read.All`*
- `Group.Read.All`
- `GroupMember.Read.All`

_\* Additional tenant-level permissions are required for **delegated access** (This does not apply to application level access). You must have one of these roles assigned roles to your account:_ **Global Admin**, **Global Reader**, **Privileged authentication admin**, or **Authentication admin**.

To configure the `Microsoft.Graph` module's default application, which will utilize **delegated access**, you need to run this command:

```powershell
Connect-MgGraph -Scopes @("User.Read.All", "UserAuthenticationMethod.Read.All", "Group.Read.All", "GroupMember.Read.All")
```

Subsequent executions of `Connect-MgGraph` will utilize those scopes, so you don't need to always supply the `-Scopes` parameter.

If you're using an application registered to your Azure AD tenant, make sure the scopes mentioned about have been assigned to the application as **Application permission** and that you have a client authentication certificate registered to it on the system you will be running it from. To authenticate as that registered application you would run something like this:

```powershell
Connect-MgGraph -ClientId "<The ApplicationId of the app>" -TenantId "<Your TenantId>" -CertificateThumbprint "<The certificate's thumbprint>"
```

If you have the certificate stored directly in a variable, you substitute the `-CertificateThumbprint` parameter with the `-Certificate` parameter. Just make sure you supply the variable to the parameter!

## Usage

Once the module has been imported into your PowerShell session and you have ran `Connect-MgGraph`, you can run the following commands:

- `Get-AadUsersWithLicense`
- `Compare-AadUsersWithCorrectPolicies`
- `Get-AadUserMfaMethods`

### Example

```powershell
#Get users with UserPrincipalNames that end in '@contoso.com' and are licensed with 'Microsoft 365 A5 for Faculty'
$licensedUsers = Get-AadUsersWithLicense -DomainName "contoso.com" -SkuId "e97c048c-37a4-45fb-ab50-922fbf07a370"

#Get which users aren't in the group with an ID of '522c3e2b-8e39-4b3c-adf4-9b4aa4e0ec47'.
#This group would be the group that Azure AD Identity Protection policies are being applied to, if you're not targeting all users.
$usersNotEnabledForAadIdp = Compare-AadUsersWithCorrectPolicies -GroupId "522c3e2b-8e39-4b3c-adf4-9b4aa4e0ec47"

#Get details on the MFA methods of each user returned from the previous step.
$usersMfaMethods = Get-AadUserMfaMethods -UserObj $usersNotEnabledForAadIdp
```

## Resources

- [Microsoft Graph API Reference](https://docs.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0)
  - Endpoints used in module:
    - [/beta/users | List users](https://docs.microsoft.com/en-us/graph/api/user-list?view=graph-rest-beta&tabs=http)
    - [/v1.0/groups/{ GroupId } | Get group](https://docs.microsoft.com/en-us/graph/api/group-get?view=graph-rest-1.0&tabs=http)
    - [/v1.0/groups/{ GroupId }/transitiveMembers | Get transitive members of group](https://docs.microsoft.com/en-us/graph/api/group-list-transitivemembers?view=graph-rest-1.0&tabs=http)
    - [/beta/{ UserPrincipalName | UserId }/authentication/methods | List authentication methods for a user](https://docs.microsoft.com/en-us/graph/api/authentication-list-methods?view=graph-rest-beta&tabs=http)
    - [/$batch | Batching multiple requests](https://docs.microsoft.com/en-us/graph/json-batching?context=graph%2Fapi%2F1.0&view=graph-rest-1.0)
  - [Permissions Reference](https://docs.microsoft.com/en-us/graph/permissions-reference)
- [Microsoft.Graph PowerShell Module Repo](https://github.com/microsoftgraph/msgraph-sdk-powershell)
  - [Microsoft Docs - Microsoft.Graph PowerShell module - Get started](https://docs.microsoft.com/en-us/graph/powershell/get-started)
  - [Microsoft Docs - Microsoft.Graph PowerShell module - App-only authentication](https://docs.microsoft.com/en-us/graph/powershell/app-only?tabs=azure-portal)