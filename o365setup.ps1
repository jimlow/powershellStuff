$cred = Get-Credential
$mailbox = Read-Host 'What is the users mailbox *EXAMPLE jsmith@company'
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
Import-PSSession $Session

#Set users mailbox quotas and clutter settings
Get-Mailbox -Identity $mailbox | Set-Mailbox -IssueWarningQuota 23GB -ProhibitSendQuota 25GB | Set-Clutter -Enable $false

#Set E3 Licence
Connect-MsolService -Credential $cred
Set-MsolUser -UserPrincipalName $mailbox -UsageLocation US
Set-MsolUserLicense -UserPrincipalName $mailbox -AddLicenses <company:ENTERPRISEPACK>

#Set 17a-4 to have rights to users mailbox
Add-MailboxPermission -Identity $mailbox -User <Username@company.com> -AccessRights FullAccess

Remove-PSSession $Session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
Import-PSSession $Session

#set user to be part of the In place hold for Lync
Set-MailboxSearch -Identity "In Place Hold for Lync" -SourceMailboxes $mailbox

Get-PSSession | Remove-PSSession