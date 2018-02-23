##############################################
# This script is Designed to create a        #
# Folder on a server and change it to a      #
# shared drive. It then assigns full control #
# to a user you specify.                     #
#                                            #
##############################################

# Assigns your access and varables to get to that server that hosts your file share

$creds = Get-Credential -message "Please enter your Domain Administrator account info"
$session = new-pssession -Credential $creds -computername walton
$user = Read-Host 'What is the users login ID *example jdoe'

# This block creates the folder on the remote share
Invoke-Command -Session $session -ScriptBlock{param($user) $user = "$user"} -ArgumentList $user
Invoke-Command -Session $session -ScriptBlock{$username = "<domain>\$user"}
Invoke-Command -Session $session -ScriptBlock{new-item "H:\Home\$user" -Type Directory}

# This block changes the folder to a share and then assigns your user modify rights to it
Invoke-Command -Session $Session -ScriptBlock{$directory = Get-Item -Path "H:\Home\$user"}
Invoke-Command -Session $session -ScriptBlock{$acl = Get-Acl "H:\Home\$user"}
Invoke-Command -Session $session -ScriptBlock{(Get-WmiObject Win32_Share -List).Create("H:\Home\$user","$user$",0)}
Invoke-Command -Session $session -ScriptBlock{$permissions = New-Object System.Security.AccessControl.FileSystemAccessRule($username,Modify,ContainerInherit,ObjectInherit,None,Allow)}
Invoke-Command -Session $Session -ScriptBlock{$acl.AddAccessRule($permissions)}
Invoke-Command -Session $Session -ScriptBlock{Set-Acl $directory $acl}

# This block sets up a new security descriptor and then sets your user to it. It then applies it to your share you created
# This will also overwrite the "Everyone" group that is assigned there.
#AccessMasks: codes for reference
#2032127 = Full Control
#1245631 = Change
#1179817 = Read

Invoke-Command -Session $Session -ScriptBlock{$sd = ([WMIClass] "Win32_SecurityDescriptor").CreateInstance()}
#------------------------------------------------------------------------
Invoke-Command -Session $Session -ScriptBlock{$ACE = ([WMIClass] "Win32_ACE").CreateInstance()}
Invoke-Command -Session $Session -ScriptBlock{$Trustee = ([WMIClass] "Win32_Trustee").CreateInstance()}
Invoke-Command -Session $Session -ScriptBlock{$Trustee.Name = $user}#Assigns your user as a trustee
Invoke-Command -Session $Session -ScriptBlock{$Trustee.Domain = "<domain>"}#sets the domain of your trustee
Invoke-Command -Session $Session -ScriptBlock{$ace.AccessMask = 2032127}#sets the access level of your trustee *see masks above
Invoke-Command -Session $Session -ScriptBlock{$ace.AceFlags = 3}
Invoke-Command -Session $Session -ScriptBlock{$ace.AceType = 0}
Invoke-Command -Session $Session -ScriptBlock{$ACE.Trustee = $Trustee}#assigns your trustee to the ACE array
Invoke-Command -Session $Session -ScriptBlock{$sd.DACL += $ACE.psObject.baseobject}# kicks the new ace back up to the Security descriptor
#----------------------------------------------------------------------
# note you can add more users and permissions to the share by copying the above block and changing the values to suit your needs

Invoke-Command -Session $Session -ScriptBlock{$mc = Get-WmiObject -Class Win32_Share -Filter "Path='H:\\Home\\$user'"}# This grabs your share folder that you created
Invoke-Command -Session $Session -ScriptBlock{$mc.SetShareInfo($Null, $Null, $sd)}# This line assigns your security Descriptor to the folder you created
Get-PSSession | Remove-PSSession # This kills your remote session so no floating sessions are left open.