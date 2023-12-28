# spotify-control
方便在Windows下快速控制spotify的播放状态

# 用法
> [!WARNING]
> 目前的所有信息均为明文保存，请自行注意密码安全
1. 需要你拥有Spotify Premium，申请[Spotidy开发者](https://developer.spotify.com/dashboard)权限
2. 在Dashboard创建一个app，拥有Web API即可，记得设置它的redirectURI
3. 在仓库所在的目录下创建`client`文件，格式如下：
    ```json
    {
        "clientID" : "**********************",
        "clientSecret": "**********************",
        "redirectURI": "http://localhost:9000/callback"
    }
    ```
4. 运行`ui.ps1`，第一次启动会跳转浏览器进行授权，授权完成后即可正常使用

# 效果

![](show.png)
