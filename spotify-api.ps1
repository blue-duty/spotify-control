
function Get-Play-Status {
    param (
        [string]$token
    )

    $uri = "https://api.spotify.com/v1/me/player"

    $headers = @{
        'Authorization' = "Bearer $token"
    }

    try {
        $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    }
    catch {
        <#Do this if a terminating exception happens#>
        $response = $null
    }

    return $response
}

# Get-Play-Status -token "BQD90kZfP651ZiXTiPxxAP8MX2_R6WIm7lEmwt4DTHoFcgzQSiAnJ7iheE7kPtylbbA3DC82meUGG_8T_vgJXYA6eDRvyGLHrxnUfwd3bHeOg_nHoof8ktb5O13I18xaS2TgV2jFVk-wbgk6E4LmoJuXX9b8tDFQE8nhMoaCz4uIVOL8kwgEkOzqgimeo4JPhxEyf4tBU586E4EJ6os" | ConvertTo-Json
