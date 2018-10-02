 
# 介绍
Mob Cordova版本 的 qq，wechat，weibo 分享插件。

# 基础
使用了Mob.com 官方最新的4.1.3 sharesdk 。需要先注册登录获取appkey。
！使用gradle集成引用，未使用jar包集成！

参考了：

[Luomusha](https://github.com/Luomusha/cordova-plugin-sharesdk)  （具有授权登录功能）
[kuaimacode](https://github.com/kuaimacode/cordova-plugin-sharesdk)（此插件有会报错，但是具有最新的一键登录功能，修改后可用）

目前支持微信、腾讯QQ、新浪微博、邮件、短信、复制。以及登录授权（~未测试~）。

# 安装
```
ionic cordova plugin add "git-url或者下载到本地路径安装" --save --variable Mob_AppKey=xxx --variable Mob_AppSecret=xxx --variable QQAPPID_ANDROID=xxx --variable QQAPPKEY_ANDROID=xxx --variable QQAPPID_IOS=xxx --variable QQAPPKEY_IOS=xxx --variable QQURLSCHEME=xxx --variable WECHATAPPID=xxx --variable WECHATAPPSECRET=xxx --variable WBAPPKEY=xxx --variable WBAPPSECRET=xxx --variable WBREDIRECTURL=url_回调地址
```

# 使用
typescript 项目中需要，以便编译通过：
```
declare let cordova: any;
declare let cordova.plugins.ShareSDKPlugin: any;
```
## 分享
```js
function share() {
        var param = [
            '测试分享标题',
            '你们好啊这里是测试分享',
            'http://cdn.qiyestore.com/openapi/upload/2015/12/25/EYZZ17L785.png',
            'http://www.qiyestore.com'
        ];
        var success = function(result){
            console.log('share success!!',JSON.stringify(result))
        };
        var error = function(result){
            console.log('share error!!',JSON.stringify(result))
        };
	    cordova.plugins.ShareSDKPlugin.share(success,error,param);
}
```
|参数|说明|
|---|---|
|success|成功回调|
|error|失败回调|
|param-参数1|标题|
|param-参数2|文字内容|
|param-参数3|图片URL|
|param-参数4|分享查看URL|

目前分享成功后应用会提示A回到应用，B留在微信/QQ/微博.如果选择回到应用，则调用success回调函数。
如果点击留在微信/QQ/微博，则调用error回调函数。

## 授权
授权功能为像第三方平台请求授权。有安装应用的拉起第三方应用，没应用的开启网页版授权，用户同意后返回用户信息。
```js
function auth() {
        function success(result){
            console.log('auth success!!',JSON.stringify(result));
        }
        function error(result){
            console.log('auth error!!',JSON.stringify(result))
        }
        var platform  = 'QQ'//QQ/Sina/Wechat
        cordova.plugins.ShareSDKPlugin.auth(success,error,platform );
}

```
|参数|说明|
|---|---|
|参数1|成功回调|
|参数2|失败回调|
|参数3|平台，不区分大小写qq/sina/wechat|

## 登陆

授权功能为像第三方平台请求授权。有安装应用的拉起第三方应用，没应用的开启网页版授权，用户同意后返回用户信息。
与auth不同的是login如果用户授权过了，就不弹出授权页面。而auth每次都弹出授权页面，即使授权过了
```js
function login() {
        function success(result){
            console.log('login success',JSON.stringify(result));
        }
        function error(result){
            console.log('login error',JSON.stringify(result));
        }
        var platform  = 'QQ'//QQ/Sina/Wechat
        cordova.plugins.ShareSDKPlugin.login(success,error,platform );
}
```
|参数|说明|
|---|---|
|参数1|成功回调|
|参数2|失败回调|
|参数3|平台，不区分大小写qq/sina/wechat|

## 清除用户授权
```js
function logout() {
        var platform  = 'QQ'//QQ/Sina/Wechat
        cordova.plugins.ShareSDKPlugin.logout(platform );
}
```

# Tips
- `QQURLSCHEME`：QQ回调Scheme。例如:QQ41DF25B4,“QQ”+腾讯QQ互联应用appId转换成十六进制（不足8位前面补0），例如“`QQ05FC5B14`”

- `WBREDIRECTURL` 第三方应用授权回调页面。授权回调页对移动客户端应用来说对用户是不可见的，所以定义为何种形式都将不影响，但是没有定义将无法使用SDK认证登录。建议使用默认回调页https://api.weibo.com/oauth2/default.html （可以在新浪微博开放平台->我的应用->应用信息->高级应用->授权设置->应用回调页中找到）。

- [MOB 微信分享闪退 errCode -6](https://blog.csdn.net/feitian145623/article/details/51752093)
：：原因是微信开放平台的md5签名跟手机签名不一致了。用MD5签名生成器生成下替换下就OK啦

- 在没有签名的情况下，QQ平台可以分享。但是微博和微信平台会分享失败。
- Android中，如果有使用微信支付插件，会起冲突。需要在`manifest.xml` 注释掉相关 `Activity` 注册。


# 卸载
```
ionic cordova plugin rm cordova-plugin-sharesdk
```

# TODO
目前使用的一键分享，没有单个分享。待计划~




