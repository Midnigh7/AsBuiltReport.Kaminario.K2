
function Invoke-AsBuiltReport.Kaminario.K2 {
    <#
    .SYNOPSIS
        PowerShell script which documents the configuration of Kaminario K2 Storage Arrays in Word/HTML/XML/Text formats
    .DESCRIPTION
        Documents the configuration of Kaminario K2 Arrays in Word/HTML/XML/Text formats using PScribo.
    .NOTES
        Version:        1.0
        Author:         Nick Lpeore
        Twitter:        @Midnigh7
        Github:         https://github.com/midnigh7
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/
    #>

    #region Script Parameters
    [CmdletBinding()]
    param (
        [string[]] $Target,
        [pscredential] $Credential,
		$StylePath
    )

    # If custom style not set, use default style
    if (!$StylePath) {
        & "$PSScriptRoot\..\..\AsBuiltReport.Kaminario.K2.Style.ps1"
    }

    $K2Arrays = $Target.split(",")
    foreach ($K2 in $K2Arrays) {
        Try {
            $K2User = ($Credential).Username
            $K2Password = ($Credential.GetNetworkCredential()).password 
            $ConnectedK2 = Connect-k2array -k2array $K2 -Username $K2User -Password $K2Password
        } Catch {
            Write-Verbose "Unable to connect to the $K2 Array"
        }
    $Script:arrays =get-k2state
        if ($ConnectedK2) {
                        $Array = get-k2state
                        $Volumes = Get-k2volume
                        $VolumeGroups = Get-k2volumegroup
                        $SystemCapacity = Get-K2SystemCapacity 
                        $Snaps = Get-k2snapshot
                        $Hosts = Get-K2Host | Sort-Object name
                        $HostGroups = Get-K2HostGroup | Sort-Object name
                        $RetentionPolicy = Get-K2RetentionPolicy | Sort-Object name 
                        $StandaloneHosts = $Hosts | where {$_.host_group -eq $null} 
                        $NTP = Get-K2NTPServer
                        try{
                        $ReplicationArrays = Get-K2ReplicationPeer | Sort-Object name 
                        } Catch {
                            Write-Verbose "WARNING: Could not find peer K2 array"
                        }
                        Try{
                            $ReplicationVolumes = Get-K2ReplicationPeerVolume | Sort-Object name 
                        } Catch {
                            Write-Verbose "WARNING: Could not find peer K2 Volume(s)"
                        }
                        
                        

                Section -Style Heading1 $Array.system_name {
                    Section -Style Heading2 'System Summary' {
                        Paragraph "The following section provides a summary of the array configuration for $($Array.system_name)."
                        BlankLine
                        $ArraySummary = [PSCustomObject] @{
                            'Name' = $Array.system_name
                            'Serial' = $Array.serial
                            'ID' = $Array.system_id
                            'Connectivity Type' = $Array.system_connectivity_type
                            'Version' = $Array.system_version
                            'State' = $Array.state
                            'NTP Server' = $NTP.server
                            'NTP Offset' = $NTP.offset
                            'NTP Reachable' = $NTP.reachable
                            'NTP In Sync' = $NTP.in_sync
                        }
                        $ArraySummary | Table -Name 'Array Summary'
                        } #End Array Summary

                        Section -Style Heading2 'Storage Summary' {
                            Paragraph "The following section provides a summary of the array storage for $($Array.system_name)."
                            BlankLine
                            $ArrayStorageSummary = [PSCustomObject] @{
                                'Raw Capacity' = "$([math]::Round(($SystemCapacity.physical) / 1TB, 2)) TB"
                                'Usable Capacity' = "$([math]::Round(($SystemCapacity.logical) / 1TB, 2)) TB"
                                'Used' = "$([math]::Round(($SystemCapacity.provisioned) / 1TB, 2)) TB"
                                'Free' = "$([math]::Round(($SystemCapacity.free) / 1TB, 2)) TB"
                                'State' = $SystemCapacity.state
                            }
                            $ArrayStorageSummary | Table -Name 'Array Storage Summary'
                    } #End Section Heading2 'System Summary'

                    Section -Style Heading3 'Snapshot Summary' {
                        Paragraph "The following section provides a summary of the Snapshots in $($Array.system_name)."
                        BlankLine
                        $SnapshotSummary = foreach ($Snap in $Snaps){
                            [PSCustomObject] @{
                                'ID' = $Snap.id
                                'Name' = $Snap.short_name
                                'Deleted' = $SSnap.is_deleted
                                'Auto Delete' = $Snap.is_auto_deleteable
                                'Creation Time' = $Snap.creation_time
                            }
                        }
                        $SnapshotSummary | Table -Name 'Snapshot Summary'
                    }#End Section Heading3 'Snapshot Summary'
                
                    Section -Style Heading3 'Hosts' {
                        Paragraph "The following section provides a summary of the Hosts in $($Array.system_name)."
                        BlankLine
                        $HostSummary = foreach ($Host in $Hosts){
                            [PSCustomObject] @{
                                'Name' = $Host.Name
                                'Type' = $Host.type
                            }
                        }
                        $HostSummary | Table -Name 'Hosts' 
                    }#End Section Heading3 'Hosts'
                 
                    Section -Style Heading3 'Host Groups' {
                        Paragraph "The following section provides a summary of the Host Groups in $($Array.system_name)."
                        BlankLine
                        $HostGroupSummary = foreach ($HG in $HostGroups){
                            [PSCustomObject]@{
                                'Host Group' = $HG.name
                                'Allow Different Host Types' = $HG.allow_different_host_types
                            }
                        }
                        $HostgroupSummary | Table -Name 'Host Groups' #-ColumnWidths 50, 50 
                    
                    }#End Section Heading3 'Host Groups'
                    Section -Style Heading2 'Volume Summary' {
                        Section -Style Heading3 'Volumes' {
                            $VolumeSummary = foreach ($Vol in $Volumes) {
                                [PSCustomObject]@{
                                    'Name' = $Vol.name
                                    'Description' = $Vol.description
                                    'Size' = "$([math]::Round(($Vol.size) / 1GB, 2)) GB"
                                    'Is DeDupe' = $Vol.is_dedup
                                    'VMWare Support' = $Vol.vmware_support
                                }
                            } 
                            $VolumeSummary | Table -Name 'Volumes'
                        }   #End Section Heading3 'Volumes'
                    
                        Section -Style Heading3 'Volume Groups' {
                            $VolumeGroupSummary = foreach ($VG in $VolumeGroups) {
                                [PSCustomObject]@{
                                    'Name' = $VG.name
                                    'Description' = $VG.description
                                    'Size' = "$([math]::Round(($VG.size) / 1GB, 2)) GB"
                                    'Is DeDupe' = $VG.is_dedup
                                }
                            } 
                            $VolumeGroupSummary | Table -Name 'Volume Groups'
                        }   #End Section Heading3 'Volume Group Summary'

                        
            }#End Section Heading2 'Volume Summary'
                    Section -Style Heading2 'Protection Summary' {
                        Section -Style Heading3 'Retention Polices' {
                            $RetentionPolicySummary = foreach ($RenPol in $RetentionPolicy){
                                [PSCustomObject] @{
                                    'Name' = $RenPol.name
                                    'Snapshots to Keep' = $RenPol.num_snapshots
                                    'Hours' = $RenPol.hours
                                    'Days' = $RenPol.days
                                    'Weeks' = $RenPol.weeks
                                }
                            }
                            $RetentionPolicySummary | Table -Name 'Retention Policies'
                        }#End Section Heading3 'Retention Policies'
                        If ($ReplicationArrays){
                            Section -Style Heading3 'Replication Connected Arrays' {
                                $ConnectedArraySymmary = foreach ($RepArray in $ReplicationArrays){
                                    [PSCustomObject]@{
                                        'Remote Name' = $RepArray.Name
                                        'K2 Management IP' = $RepArray.mgmt_ip
                                        'State' = $RepArray.mgmt_connectivity_state
                                    }
                                }
                                $ConnectedArraySymmary | Table -Name 'Replication Arrays'
                            }#End Section 'Replication Connected Arrays'
                        } #End IF Replication Peer
                        if  ($ReplicationVolumes){
                            Section -Style Heading3 'Replicated Volumes' {
                                $ReplicaionVolSummary = foreach ($RepVol in $ReplicationVolumes){
                                    [PSCustomObject] @{
                                        'Name' = $RepVol.name
                                    }
                                }
                                $ReplicationVolSummary | Table -Name 'Replicated Volumes'
                            }#End Section 'Replicated Volumes'
                        }#End If Replication Volumes

                        }#End Section Heading2 'Protection Summary'
                } #End Section Heading1 '$Array.system_name
            } #End ConnectedK2
            $Null = Disconnect-K2Array -ErrorAction SilentlyContinue
       } #End ForEach K2
    }  #End Function

