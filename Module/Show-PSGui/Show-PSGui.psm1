param([switch]$NoVersionCheck)

#Is module loaded; if not load
if ((Get-Module Show-PSGui)){return}
    $psv = $PSVersionTable.PSVersion

    #verify PS Version
    if ($psv.Major -lt 5 -and !$NoVersionWarn) {
        Write-Warning ("Show-PSGui is listed as requiring 5; you have version $($psv).`n" +
        "Visit Microsoft to download the latest Windows Management Framework `n" +
        "To suppress this warning, change your include to 'Import-Module Show-PSGui -NoVersionCheck `$true'.")
        return
    }
. $PSScriptRoot\public\Get-ObjectSize.ps1
. $PSScriptRoot\public\Get-PSObjectParamTypes.ps1
. $PSScriptRoot\public\Get-StringSize.ps1
. $PSScriptRoot\public\Show-Psgui.ps1
Export-ModuleMember Get-ObjectSize
Export-ModuleMember Get-PSObjectParamTypes
Export-ModuleMember Get-StringSize
Export-ModuleMember Show-Psgui
