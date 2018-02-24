
<#PSScriptInfo

.VERSION 1.0

.GUID ffa2403f-ed00-4b34-a82c-a4e3513a69cc

.AUTHOR Adam Malleo

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Gather market cap data for ERC20 tokens using an Ethereum address.

#> 
Param(
    [Parameter(Mandatory=$true)]
    [string]$Address
)

$ethplorerApi = "https://api.ethplorer.io/getAddressInfo/$($address)?apiKey=freekey"

$coinMarketCapApi = "https://api.coinmarketcap.com/v1/ticker/?limit=0"

# Force powershell to use TLS 1.2
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
catch {
    Write-Host "Error: Powershell does not support TLS 1.2." -ForegroundColor Red
    exit 1
}

function validateAddress ($address) {
    if ($address.Trim() -match "^(0x)[0-9a-f]{40}$") {
        $true
    }
    else {
        Write-Host "Error: Address is invalid. Must include 0x prefix." -ForegroundColor Red
        exit 1
    }
}

function request ($uri) {
    try {
        Invoke-RestMethod -Method Get -DisableKeepAlive -Uri $uri
    }
    catch {
        Write-Host "Error: Unable to connect to $uri" -ForegroundColor Red
        exit 1
    }
}

function addToken ($object, $token) {
    $object | Add-Member -MemberType NoteProperty -Name Name -Value $token.name
    $object | Add-Member -MemberType NoteProperty -Name Symbol -Value $token.symbol
    if ($token.price_usd -ne "") {
        $object | Add-Member -MemberType NoteProperty -Name USD -Value ([decimal]$token.price_usd).ToString("C")
    }
    else {
        $object | Add-Member -MemberType NoteProperty -Name USD -Value "N/A"
    }
    if ($token.market_cap_usd -ne "") {
        $object | Add-Member -MemberType NoteProperty -Name "Market Cap" -Value ([decimal]$token.market_cap_usd).ToString("C")
    }
    else {
        $object | Add-Member -MemberType NoteProperty -Name "Market Cap" -Value "N/A"
    }
    Write-Output $object
}

validateAddress -address $address > $null

$wallet = request -uri $ethplorerApi

$tokens = $wallet.tokens.tokeninfo.symbol | Where-Object {$_}

$cap = request -uri $coinMarketCapApi

$output = @()

foreach ($item in $tokens) {
    if ($item -in $cap.symbol) {
        $object = New-Object -TypeName psobject
        
        $token = ($cap | Where-Object symbol -eq $item)

        $output += addToken -object $object -token $token
    }
}

Write-Output $output | Sort-Object Name