param ([Parameter(Mandatory)][string]$Path)

$parts = $Path.Replace('/', '\') -split '\\'

$pld = -1
for ($i = 0; $i -lt $parts.Length; $i++) {
    if ($parts[$i] -ieq 'Metadata') { $pld = $i; break }
}

$rawType = $parts[$pld + 3]

$objectType = switch ($rawType) {
    'AxClass'              { 'class' }
    'AxConfigurationKey'   { 'configurationkey' }
    'AxEdt'                { 'edt' }
    'AxEnum'               { 'enum' }
    'AxForm'               { 'form' }
    'AxInfoPart'           { 'infopart' }
    'AxLicenseCode'        { 'licensecode' }
    'AxMacroDict'          { 'macrodict' }
    'AxMap'                { 'map' }
    'AxQuery'              { 'query' }
    'AxReport'             { 'report' }
    'AxSecurityPrivilege'  { 'securityprivilege' }
    'AxService'            { 'service' }
    'AxServiceGroup'       { 'servicegroup' }
    'AxTable'              { 'table' }
    'AxView'               { 'view' }
    default                { $rawType }
}

$result = [PSCustomObject]@{
    ModuleName = $parts[$pld + 1]
    ModelName  = $parts[$pld + 2]
    ObjectType = $objectType
}
Write-Output $result