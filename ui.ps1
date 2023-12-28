Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Assembly System.Drawing

. .\spotify-c.ps1
. .\spotify-api.ps1

# # 1. 从文件中读取加密的密码
# $encryptedPassword = Get-Content -Path ".\pwd.txt"
# # 2. 将字符串转换为SecureString
# $securePassword = ConvertTo-SecureString -String $encryptedPassword
# # 3. 将加密的密码解密
# $accessToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
# # 输出解密后的密码
# Write-Output "Decrypted Password: $accessToken"

# 1. 从password.json 读取token和刷新token
$password = Get-Content -Path ".\password.json" | ConvertFrom-Json
$global:accessToken = $password.token
$reflushToken = $password.reflushToken
# 当前播放状态
$status = $false

# Write-Output $password.token
# Write-Output $password.reflushToken
# Write-Output $password | ConvertTo-Json

# 更新accessToken的示例
function UpdateAccessToken([ref]$accessToken) {
    $token = update-Token -RefreshToken $reflushToken -ClientId $clientID -ClientSecret $clientSecret
    if ($null -ne $token) {
        $accessToken.Value = $token
    }
}

# 获取主屏幕
$primaryScreen = [Windows.Forms.Screen]::PrimaryScreen
$screenWidth = $primaryScreen.Bounds.Width
$screenHeight = $primaryScreen.Bounds.Height

# 创建窗口
$window = New-Object Windows.Window
$window.ResizeMode = 'NoResize'
$window.WindowStyle = 'None'
$window.WindowStartupLocation = 'Manual'

# 设置窗口不在任务栏中显示
$window.ShowInTaskbar = $false

# 设置窗口一直置于顶层
$window.Topmost = $true

# 设置窗口透明
$window.AllowsTransparency = $true

# 设置窗口大小
$window.Width = 200
$window.Height = 80

# # 创建一个边框效果（Rectangle）
# $border = New-Object Windows.Shapes.Rectangle
# $border.Width = $window.Width
# $border.Height = $window.Height
# $border.Stroke = [Windows.Media.Brushes]::White  # 设置边框颜色
# $border.StrokeThickness = 2  # 设置边框宽度

# 创建按钮1
$buttonPlay = New-Object Windows.Controls.Button
$buttonPlay.Content = "⏮️"
$buttonPlay.Add_Click({
        # TODO: 添加播放逻辑
        $code = Spotify_C -action p -accessToken $global:accessToken
        switch ($code) {
            401 {
                $token = update-Token -RefreshToken $reflushToken -ClientId $clientID -ClientSecret $clientSecret
                if ($token -eq $null) {

                }
                else {
                    UpdateAccessToken -accessToken ([ref]$global:accessToken)
                    $code = Spotify_C -action p -accessToken $global:accessToken
                }
            }
            200 {
                UpdateText -s ([ref]$status)
            }
            400 {
                # 弹窗提醒
            }
            Default {}
        }
        Write-Host "点击了上一首按钮"
    })

# $icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Users\lwdut\Documents\autoStart\spotify-control\prev_icon.png")
# $bitmap = $icon.ToBitmap()

# # 转换 Bitmap 为 BitmapImage
# $bitmapStream = New-Object System.IO.MemoryStream
# $bitmap.Save($bitmapStream, [System.Drawing.Imaging.ImageFormat]::Png)
# $bitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage
# $bitmapImage.BeginInit()
# $bitmapImage.StreamSource = $bitmapStream
# $bitmapImage.EndInit()

# # 创建 ImageBrush
# $imageBrush = New-Object System.Windows.Media.ImageBrush
# $imageBrush.ImageSource = $bitmapImage

# $buttonPlay.Background = $imageBrush

# $buttonPlay.Background = [System.Drawing.Image]::FromFile("C:\Users\lwdut\Documents\autoStart\spotify-control\prev_icon.png") # 将图标转换为位图并设置为按钮的背景图像
# $button.BackgroundImageLayout = "Center"
# $buttonPlay.Image =  [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Users\lwdut\Documents\autoStart\spotify-control\prev_icon.png").ToBitmap()

# 创建按钮2
$buttonPause = New-Object Windows.Controls.Button
$buttonPause.Content = "⏸️"
$buttonPause.Add_Click({
        # TODO: 添加暂停逻辑
        $action = "c"
        if ($status) {
            $action = "u"
        }
        $code = Spotify_C -action $action -accessToken $global:accessToken
        switch ($code) {
            401 {
                $token = update-Token -RefreshToken $reflushToken -ClientId $clientID -ClientSecret $clientSecret
                if ($token -eq $null) {

                }
                else {
                    # $accessToken = $token
                    UpdateAccessToken -accessToken ([ref]$global:accessToken)
                    $code = Spotify_C -action $action -accessToken $global:accessToken
                }
            }
            200 {
                UpdateText -s ([ref]$status)
            }
            400 {
                # 弹窗提醒
            }
            Default {}
        }

        Write-Host "点击了暂停按钮"
    })

# 创建按钮3
$buttonStop = New-Object Windows.Controls.Button
$buttonStop.Content = "⏭️"
$buttonStop.Add_Click({
        $code = Spotify_C -action n -accessToken $global:accessToken
        switch ($code) {
            401 {
                $token = update-Token -RefreshToken $reflushToken -ClientId $clientID -ClientSecret $clientSecret
                if ($token -eq $null) {

                }
                else {
                    # $accessToken = $token
                    UpdateAccessToken -accessToken ([ref]$global:accessToken)
                    $code = Spotify_C -action n -accessToken $global:accessToken
                }
            }
            200 {
                UpdateText -s ([ref]$status)
            }
            400 {
                # 弹窗提醒
            }
            Default {}
        }
        Write-Host "点击了下一首按钮"
    })

# 创建一个堆栈面板，用于放置按钮
$stackPanel = New-Object Windows.Controls.StackPanel
$stackPanel.Children.Add($buttonPlay)
$stackPanel.Children.Add($buttonPause)
$stackPanel.Children.Add($buttonStop)

# 设置堆栈面板的对齐方式为居中
$stackPanel.VerticalAlignment = 'Center'
$stackPanel.HorizontalAlignment = 'Center'
$stackPanel.Orientation = 'Horizontal'

# 添加文本内容
$textBlock = New-Object Windows.Controls.TextBlock
$textBlock.Text = '待机中……'
$textBlock.LineHeight = 6.0
$textBlock.Foreground = [Windows.Media.Brushes]::White
$textBlock.FontSize = 12

# Function to update text based on play status
function UpdateText([ref]$s) {
    $resp = Get-Play-Status -token $global:accessToken
    if ($null -eq $resp) {
        UpdateAccessToken -accessToken ([ref]$global:accessToken)
        $resp = Get-Play-Status -token $global:accessToken
    }

    $s.Value = $resp.is_playing
    Write-Output $resp.item.name
    # if (-not [string]::IsNullOrEmpty($resp.item.name)) {
    #     $textBlock.Text = "待机中……"
    # } else {
    #     Write-Output "2"
    $textBlock.Text = $resp.item.name
    # }
}

UpdateText -s ([ref]$status)

# Create a DispatcherTimer
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(30)
$timer.Add_Tick({
        UpdateText -s ([ref]$status)
    })

# Start the timer
$timer.Start()

# Start-ThreadJob -ScriptBlock {
#     $resp = Get-Play-Status -token $accessToken

#     $textBlock.Text = $resp.item.name
# } -ArgumentList $accessToken

# 创建父堆栈面板
$stackPanelP = New-Object Windows.Controls.StackPanel
$stackPanelP.Children.Add($textBlock)
$stackPanelP.Children.Add($stackPanel)
$stackPanelP.Background = [Windows.Media.Brushes]::Transparent

$textBlock.TextAlignment = "Center"
# $textBlock.Foreground = [Windows.Media.Brushes]::White

# 设置透明背景色
$window.Background = [Windows.Media.Brushes]::Transparent

# 设置窗口内容为堆栈面板
$window.Content = $stackPanelP

# # 设置窗口内容为边框效果和堆栈面板
# $window.Content = $border
# $window.Content.AddChild($stackPanelP)

# 设置窗口背景色
# $window.Background = [Windows.Media.Brushes]::Blue

# 获取窗口宽度和高度
$windowWidth = $window.Width
$windowHeight = $window.Height

# 设置窗口位置为右下角
$window.Left = $screenWidth - $windowWidth
$window.Top = $screenHeight - $windowHeight - 20

# 显示窗口
$window.ShowDialog()
