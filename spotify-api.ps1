
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

        $artirts = @()
        $response.item.artists | ForEach-Object {
            $artirts += $_.name
        }

        $artistAll = $artirts -join ", "
        $name = $response.item.name
        # Write-Host "${artistAll} - ${name}"

        # 当前的播放进度
        # $progress_ms = $response.progress_ms
        # # 整首歌的进度
        # $duration_ms = $response.item.duration_ms
        # $timeSpan = [TimeSpan]::FromSeconds($duration_ms / 1000)
        # # 格式化时间
        # $formattedTime = '{0:D2}:{1:D2}:{2:D2}' -f $timeSpan.Hours, $timeSpan.Minutes, $timeSpan.Seconds
        # Write-Host $formattedTime
        return [PSCustomObject]@{
            is_playing = $response.is_playing
            name    = "${artistAll} - ${name}"
            # progress   = ($duration_ms - $progress_ms) / 1000 - 5
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        return $null
    }
}

# Get-Play-Status -token "BQAqLN5hj5uRmLBo8CaUbySZiPWXrCwZrhZLRIpKugLFnTgQg9WOFLiO9FEbxhzZ5qqSqv0J_j3bj2cK1gAdMTsIbWs4ih4IBJ2PPh08ZBWLeFmc4NZqQBDv5G0K-X8GPj7Pt4aWPB33Fs-9KNn56eOvdZVFlU_wwZXZW9Mc6F-UlZ7Ph2DXNcEfG1vOldKCx7PFnBiTbOBeC16EkSegnA" | ConvertTo-Json
