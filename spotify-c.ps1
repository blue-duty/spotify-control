# Spotify API相关信息
$redirectURI = "http://localhost:9000/callback"  # 可以随意设置，但必须在Spotify应用程序设置中配置相同的重定向URI
# Spotify的Access Token请求URL
$tokenEndpoint = "https://accounts.spotify.com/api/token"
# 播放控制url
$apiEndpoint = "https://api.spotify.com/v1/me/player"
$client = Get-Content -Path ".\client" | ConvertFrom-Json
$clientID = $client.clientID
$clientSecret = $client.clientSecret

function get-Token {
    Start-ThreadJob -ScriptBlock {
        param (
            $redirectUri,
            $clientId,
            $clientSecret,
            $tokenEndpoint
        )
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:9000/")
        $listener.Start()

        while ($true) {
            $context = $listener.GetContext()
            $request = $context.Request
            # 提取授权码
            $queryString = $request.Url.Query
            if ($queryString -match "code=([^&]+)") {
                $authorizationCode = $matches[1]

                # 回复给浏览器
                $response = $context.Response
                $content = [System.Text.Encoding]::UTF8.GetBytes("Authorization Code Received. You can close this window now.")
                $response.OutputStream.Write($content, 0, $content.Length)
                $response.Close()

                # 停止监听器
                $listener.Stop()

                # 构建POST请求的数据
                $body = @{
                    grant_type    = "authorization_code"
                    code          = $authorizationCode
                    redirect_uri  = $redirectUri
                    client_id     = $clientId
                    client_secret = $clientSecret
                }

                # 发送POST请求并获取响应
                $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body

                $response | Out-File -FilePath ".\tokens.json" -Force

                $password = [PSCustomObject]@{
                    token        = $response.access_token
                    reflushToken = $response.refresh_token
                }

                $password | ConvertTo-Json | Out-File ".\password.json"

                # $securePwd = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

                # # 2. 使用ConvertFrom-SecureString将密码加密并保存到文件
                # $encryptedPassword = $securePwd | ConvertFrom-SecureString
                # $encryptedPassword | Out-File -FilePath ".\pwd.txt"

                break  # 退出循环
            }
            else {
                # 如果没有找到授权码，返回错误页面或者其他处理
                $response = $context.Response
                $content = [System.Text.Encoding]::UTF8.GetBytes("Error: Authorization Code not found.")
                $response.OutputStream.Write($content, 0, $content.Length)
                $response.Close()
            }
        }
    }  -ArgumentList $redirectUri, $clientId, $clientSecret, $tokenEndpoint

    # 构建授权URL
    $authorizeUrl = "https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=user-modify-playback-state user-read-playback-state user-read-currently-playing"
    # 打开浏览器并导航到授权URL，用户登录并授权应用程序
    Start-Process $authorizeUrl
}

function update-Token {
    param (
        [string]$RefreshToken,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TokenEndpoint = "https://accounts.spotify.com/api/token"
    )

    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${ClientId}:${ClientSecret}"))

    $headers = @{
        'Content-Type'  = 'application/x-www-form-urlencoded'
        'Authorization' = "Basic $base64Auth"
    }

    $body = @{
        grant_type    = 'refresh_token'
        refresh_token = $RefreshToken
    }

    try {
        $response = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Headers $headers -Body $body

        # Update your token storage with the new access token and refresh token
        # For example, you can save them to a file or update global variables
        # $response | Out-File -FilePath ".\tokens.json" -Force

        Write-Output $response

        # Write-Output "success"

        $password = [PSCustomObject]@{
            token        = $response.access_token
            reflushToken = $RefreshToken
        }

        $password | ConvertTo-Json | Out-File ".\password.json"

        return $response.access_token

        # $securePwd = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
        # # 使用ConvertFrom-SecureString将密码加密并保存到文件
        # $encryptedPassword = $securePwd | ConvertFrom-SecureString
        # $encryptedPassword | Out-File -FilePath ".\pwd.txt"
    }
    catch {
        Write-Error "Error refreshing access token: $_"
        return $null
    }
}

function Spotify_C {
    param (
        [string]$action,
        [string]$accessToken
    )

    # 构建HTTP请求的Header
    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    $method = "POST"
    switch ($action) {
        "p" {
            $path = "/previous"
        }
        "n" {
            $path = "/next"
        }
        "u" {
            $path = "/pause"
            $method = "PUT"
        }
        "c" {
            $path = "/play"
            $method = "PUT"
        }
        default {
            Write-Host "无效的操作: $action"
            return
        }
    }
    $url = $apiEndpoint + $path
    # Write-Output $url
    try {
        Invoke-RestMethod -Uri $url -Method $method -Headers $headers -ResponseHeadersVariable Response
        return 200
    }
    catch {
        <#Do this if a terminating exception happens#>
        # Write-Output "报错"
        if ($_.Exception.StatusCode -eq 401) {
            # Write-Output "401"
            # update-Token -RefreshToken $reflushToken -ClientId $clientID -ClientSecret $clientSecret
            return 401
        }
        # Write-Output $_.Exception

        # $memStream = $_.Exception.Response.GetResponseStream()
        # $readStream = New-Object System.IO.StreamReader($memStream)
        # while ($readStream.Peek() -ne -1) {
        #     Write-Host $readStream.ReadLine()
        # }
        # $readStream.Dispose();

        return 400
    }
}

if (-not (Test-Path -Path ".\password.json")) {
    Get-Token
}



