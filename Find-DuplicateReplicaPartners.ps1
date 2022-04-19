#Get-ADReplicationPartnerMetadata -Target "VEJX-DC-004v" -Partition "CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL" | Select-Object Server,Partner | Out-GridView

#AFNOAPPS.USAF.MIL/Configuration/Sites/VEJX-SCOTT-APC/Servers/VEJX-DC-004V/NTDS Settings/13206f12-9594-414e-a2d3-77328365a193

#get-adobject "CN=13206f12-9594-414e-a2d3-77328365a193,CN=NTDS Settings,CN=VEJX-DC-004V,CN=Servers,CN=VEJX-SCOTT-APC,CN=Sites,CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL" -filter {canonicalname -eq "AFNOAPPS.USAF.MIL/Configuration/Sites/VEJX-SCOTT-APC/Servers/VEJX-DC-004V/NTDS Settings/"}
cls
$outpath = "$env:userprofile\desktop\"
if ($env:COMPUTERNAME -eq "MUHJW-431MFQ") {$outpath = "C:\Users\1456084571E\Documents\PS Workshop\2012\Diagnostics"}
$timestamp = (Get-Date -Format yyyy-MM-dd.HH-mm-ss)
$dupeOutpath = "$outpath\duplicateReplicas_$timestamp.csv"
$goneOutPath = "$outpath\HangingNTDS_$timestamp.txt"
#Remove-Item $goneOutPath -Force -EA SilentlyContinue
Out-File -FilePath $dupeOutpath -InputObject "Server,FromPartner" -Encoding default -Force
Get-ADObject -filter {objectclass -eq "nTDSDSA"} -SearchBase "CN=Sites,CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL" <#| where {$_.DistinguishedName -like "*VEJX*"}#> | sort DistinguishedName | foreach {
    $servName = $_.DistinguishedName.split("=")[2].split(",")[0]
    write-host -f Green "$servname"
    try {$serv = Get-ADDomainController $servname | select Site}
    catch {
        try {$serv = Get-ADDomainController $servname -Server "afnoapps.usaf.mil" | select Site}
        catch {
            Out-File $goneOutPath -InputObject $servname -Encoding default -Append
            write-host -f red "__________________________________________________"
            return
            }
        }
    #return
    $location = "CN=NTDS Settings,CN=" + $servName + ",CN=Servers,CN=" + $serv.Site + ",CN=Sites,CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL"
    $ReplicaArray = @()
    get-adobject -filter * -searchbase $location -Properties fromServer | where {$_.Name -ne "NTDS Settings"} | sort fromServer | foreach { #$_.fromServer.split(",")[1].split("=")[1]} | sort
        if ($ReplicaArray -notcontains $_.fromServer.split(",")[1].split("=")[1]) { 
            $ReplicaArray += $_.fromServer.split(",")[1].split("=")[1]
            }
        else {
            Out-File -FilePath $dupeOutpath -InputObject ("$servName," + $_.fromServer.split(",")[1].split("=")[1]) -Encoding default -Append
            #Remove-ADObject $_.distinguishedName -Confirm:$false
            #Write-Host "Removed Replica Link for $servname from"($_.fromServer.split(",")[1].split("=")[1])
            }
        }
    write-host "__________________________________________________"
    }

if (((Get-Content $dupeOutpath) -join "") -eq "Server,FromPartner") {Remove-Item $dupeOutpath -Force -EA SilentlyContinue}

<#
#Holy Hell this is going to be complicated and convoluted.
#Find duplicate pairs, both server and source
#remove all matching pairs
#Add New replica connection for said pair
#Change to make it automatically managed (options = 1)
#???
#<strikethrough>Profit</strikethrough>

#Revised: Just delete the pairs with duplicates, and let KCC do its thing.
###I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC.
#>
if ($false) { #We only want this manually run for now.  highlight and run selection for now. 
    $List = Import-Csv $dupeOutpath
    $ServersWithDupes = $List.Server | Get-Unique
    foreach ($server in $ServersWithDupes) {
        $DupeLinks = ($List | Where {$_.Server -eq $server}).FromPartner | Get-Unique
        $location = "CN=NTDS Settings,CN=" + $server + ",CN=Servers,CN=" + (Get-ADDomainController $server).Site + ",CN=Sites,CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL"
        #Delete all pairs that have dupes
        get-adobject -filter * -searchbase $location -Properties fromServer | where {$_.Name -ne "NTDS Settings"} | sort fromServer | foreach {
            #if ($DupeLinks -contains $_.fromServer.split(",")[1].split("=")[1]) {Remove-ADObject $_.distinguishedName -confirm:$False}#{"Would delete " + $_.fromServer.split(",")[1].split("=")[1] + " from $server"}#
            }
        #Make new links
        ###I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC. I am not smarter than the KCC.
        <#foreach ($dupe in $DupeLinks) {
            $fromDN = "CN=NTDS Settings,CN=" + $dupe + ",CN=Servers,CN=" + (Get-ADDomainController $dupe).Site + ",CN=Sites,CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL"
            $connName = "$dupe`_" + (Get-Date -Format yyyy-MM-dd.hh-mm-ss)
                #CN=NTDS-Connection,CN=Schema,CN=Configuration,DC=AFNOAPPS,DC=USAF,DC=MIL
                New-ADObject -type nTDSConnection -Name $connName -path $location -OtherAttributes @{options=1;fromServer=$fromDN;enabledConnection=$false} -WhatIf #NEEDS SO MANY MORE ATTRIBUTES.
            }#>
        }
    }
