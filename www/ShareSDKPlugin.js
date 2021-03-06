var exec = require('cordova/exec');
var pluginName = "ShareSDKPlugin";
var ShareSDKPlugin = {
};


ShareSDKPlugin.logout = function (successCallback, errorCallback, params) {
    exec(successCallback, errorCallback, pluginName, "logout", [params]);
};
//一键分享
ShareSDKPlugin.share = function (successCallback,errorCallback,params) {
    var result = undefined;
    if(Array.isArray(params)){
        result = params;
    }else{
        result = [params]
    }
    exec(successCallback, errorCallback, pluginName, "share", result);
};
//获取用户信息
ShareSDKPlugin.login = function (successCallback, errorCallback, params) {
    exec(successCallback, errorCallback, pluginName, "login", [params]);
};
//用户授权
ShareSDKPlugin.auth = function (successCallback, errorCallback, params) {
    exec(successCallback, errorCallback, pluginName, "auth", [params]);
};
module.exports = ShareSDKPlugin;