#import "ShareSDKPlugin.h"
#import <Cordova/CDVPlugin.h>


#import <MOBFoundation/MOBFoundation.h>

#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <ShareSDKExtension/SSEThirdPartyLoginHelper.h>

//腾讯开放平台（对应QQ和QQ空间）SDK头文件
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>

//微信SDK头文件
#import "WXApi.h"

//新浪微博SDK头文件
#import "WeiboSDK.h"
//新浪微博SDK需要在项目Build Settings中的Other Linker Flags添加"-ObjC"


@implementation ShareSDKPlugin
#pragma mark "API"
- (void)pluginInitialize {

/**初始化ShareSDK应用

@param activePlatforms

使用的分享平台集合

 @param importHandler (onImport)

导入回调处理，当某个平台的功能需要依赖原平台提供的SDK支持时，需要在此方法中对原平台SDK进行导入操作

 @param configurationHandler (onConfiguration)

配置回调处理，在此方法中根据设置的platformType来填充应用配置信息

 */

    NSString* sharesdkAppKey = [[self.commandDelegate settings] objectForKey:@"sharesdkappkey"];
    NSString* wechatAppId = [[self.commandDelegate settings] objectForKey:@"wechatappid"];
    NSString* wechatAppSecret = [[self.commandDelegate settings] objectForKey:@"wechatappsecret"];
    NSString* qqAppId = [[self.commandDelegate settings] objectForKey:@"qqappid"];
    NSString* qqAppKey = [[self.commandDelegate settings] objectForKey:@"qqappkey"];
    NSString* wbAppKey = [[self.commandDelegate settings] objectForKey:@"wbappkey"];
    NSString* wbAppSecret = [[self.commandDelegate settings] objectForKey:@"wbappsecret"];
    NSString* wbRedirectUrl = [[self.commandDelegate settings] objectForKey:@"wbredirecturl"];

    if(wechatAppId && wechatAppSecret && qqAppId && qqAppKey && wbAppKey && wbAppSecret && wbRedirectUrl && sharesdkAppKey){

        [ShareSDK registerActivePlatforms:@[
                            @(SSDKPlatformTypeSinaWeibo),
                            @(SSDKPlatformTypeMail),
                            @(SSDKPlatformTypeSMS),
                            @(SSDKPlatformTypeCopy),
                            @(SSDKPlatformTypeWechat),
                            @(SSDKPlatformTypeQQ)
            ]
           onImport:^(SSDKPlatformType platformType)
           {
               switch (platformType)
               {
                  case SSDKPlatformTypeWechat:
                  //初始化的import参数注意要链接原生微信SDK。
                       [ShareSDKConnector connectWeChat:[WXApi class]];
                    break;
                  case SSDKPlatformTypeQQ:
                        [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                    break;
                  case SSDKPlatformTypeSinaWeibo:
                          [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                    break;
                  default:
                    break;
                }
          }
              onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {

                  switch (platformType)
                  {
                      case SSDKPlatformTypeSinaWeibo:
                          //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                          [appInfo SSDKSetupSinaWeiboByAppKey:wbAppKey
                                                    appSecret:wbAppSecret
                                                  redirectUri:wbRedirectUrl
                                                     authType:SSDKAuthTypeBoth];
                          break;
                      case SSDKPlatformTypeWechat:
                          [appInfo SSDKSetupWeChatByAppId:wechatAppId
                                                appSecret:wechatAppSecret];
                          break;
                      case SSDKPlatformTypeQQ:
                          [appInfo SSDKSetupQQByAppId:qqAppId
                                               appKey:qqAppKey
                                             authType:SSDKAuthTypeBoth];
                          break;
                      default:
                          break;
                  }
              }];
    }

}

- (void)share:(CDVInvokedUrlCommand*)command {
    //在这里拿到参数，
    [self showShareActionSheet:self.viewController.view
                       command:command];

}

- (void)auth:(CDVInvokedUrlCommand*)command {
    //在这里拿到参数，
    NSString *platformString = [command.arguments[0] lowercaseString];
    SSDKPlatformType platform;
    if ([platformString  isEqual: @"sina"])
    {
        platform = SSDKPlatformTypeSinaWeibo;
    }
    else if([platformString  isEqual: @"qq"])
    {
        platform = SSDKPlatformTypeQQ;
    }
    else {
        platform = SSDKPlatformTypeWechat;
    }


    [ShareSDK authorize:platform
               settings:@{SSDKAuthSettingKeyScopes : @[@"follow_app_official_microblog"]}
         onStateChanged:^(SSDKResponseState state, SSDKUser *user, NSError *error)
     {
         if (state == SSDKResponseStateSuccess)
         {
             NSLog(@"***************************************************");
             NSLog(@"%@", user.uid);
             NSLog(@"%@", user.nickname);
             NSLog(@"%@", user.icon);
             NSLog(@"%lu", (unsigned long)user.gender);
             NSLog(@"%@", user.birthday);
             NSLog(@"%@", user.url);
             NSLog(@"***************************************************");
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                               messageAsString:[NSString stringWithFormat:@"success"]];
             [self.commandDelegate sendPluginResult:pluginResult
                                         callbackId:command.callbackId];


         }else if(state == SSDKResponseStateFail)
         {
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                               messageAsString:[NSString stringWithFormat:@"error"]
                                              ];

             [self.commandDelegate sendPluginResult:pluginResult
                                         callbackId:command.callbackId];
         }else if(state == SSDKResponseStateCancel)
         {
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                               messageAsString:[NSString stringWithFormat:@"cancel"]
                                              ];

             [self.commandDelegate sendPluginResult:pluginResult
                                         callbackId:command.callbackId];

         }

     }];



}

- (void)login:(CDVInvokedUrlCommand*)command {
    NSString *platformString = [command.arguments[0] lowercaseString];
    SSDKPlatformType platform;
    if ([platformString  isEqual: @"sina"])
    {
        platform = SSDKPlatformTypeSinaWeibo;
    }
    else if([platformString  isEqual: @"qq"])
    {
        platform = SSDKPlatformTypeQQ;
    }
    else {
        platform = SSDKPlatformTypeWechat;
    }


    [ShareSDK getUserInfo:platform
           onStateChanged:^(SSDKResponseState state, SSDKUser *user, NSError *error)
     {
         if (state == SSDKResponseStateSuccess)
         {
             NSLog(@"***************************************************");
             NSLog(@"%@", user.uid);
             NSLog(@"%@", user.nickname);
             NSLog(@"%@", user.icon);
             NSLog(@"%lu", (unsigned long)user.gender);
             NSLog(@"%@", user.birthday);
             NSLog(@"%@", user.url);
             NSLog(@"***************************************************");

             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                      messageAsDictionary:user.rawData];

             [self.commandDelegate sendPluginResult:pluginResult
                                         callbackId:command.callbackId];


         }else if(state == SSDKResponseStateFail)
         {
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                               messageAsString:[NSString stringWithFormat:@"error"]
                                              ];

             [self.commandDelegate sendPluginResult:pluginResult
                                         callbackId:command.callbackId];
         }else if(state == SSDKResponseStateCancel)
         {
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                               messageAsString:[NSString stringWithFormat:@"cancel"]
                                              ];

             [self.commandDelegate sendPluginResult:pluginResult
                                         callbackId:command.callbackId];

         }

     }];


}
- (void)logout:(CDVInvokedUrlCommand*)command {
    NSString *platformString = [command.arguments[0] lowercaseString];
    SSDKPlatformType platform;
    if ([platformString  isEqual: @"sina"])
    {
        platform = SSDKPlatformTypeWechat;
    }
    else if([platformString  isEqual: @"qq"])
    {
        platform = SSDKPlatformTypeQQ;
    }
    else {
        platform = SSDKPlatformTypeSinaWeibo;
    }

    [ShareSDK cancelAuthorize:platform];

}





#pragma mark 显示分享菜单

/**
 *  显示分享菜单
 *
 *  @param view 容器视图
 */
- (void)showShareActionSheet:(UIView *)view
                    command :(CDVInvokedUrlCommand*)command{
    /**
     * 在简单分享中，只要设置共有分享参数即可分享到任意的社交平台
     **/
    __weak UIViewController *theController = self.viewController;

    //1、创建分享参数（必要）

    NSString* title = [command.arguments objectAtIndex:0];
    NSString* text = [command.arguments objectAtIndex:1];
    NSString* imageUrl = [command.arguments objectAtIndex:2];
    NSString* url = [command.arguments objectAtIndex:3];

    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    NSArray* imageArray = imageUrl;// 在这里把参数替换掉。
    [shareParams SSDKSetupShareParamsByText:text
                                     images:imageArray
                                        url:[NSURL URLWithString:url]
                                      title:title
                                       type:SSDKContentTypeAuto];
    [shareParams SSDKEnableUseClientShare];

    //2、分享（可以弹出我们的分享菜单和编辑界面）
    //大家请注意：4.1.2版本开始因为UI重构了下，所以这个弹出分享菜单的接口有点改变，如果集成的是4.1.2以及以后版本，如下调用：
 [ShareSDK showShareActionSheet:nil customItems:nil shareParams:shareParams sheetConfiguration:nil onStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                   switch (state) {
                        /**
                        *  开始
                        */
                       case SSDKResponseStateBegin:
                       {
                           break;
                       }
                        //视频文件开始上传
                       case SSDKResponseStateBeginUPLoad:
                       {
                           break;
                       }
                       case SSDKResponseStateSuccess:
                       {
                           //Facebook Messenger、WhatsApp等平台捕获不到分享成功或失败的状态，最合适的方式就是对这些平台区别对待
                           if (platformType == SSDKPlatformTypeFacebookMessenger)
                           {
                               break;
                           }
                           CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                             messageAsString:[NSString stringWithFormat:@"success"]];
                           [self.commandDelegate sendPluginResult:pluginResult
                                                       callbackId:command.callbackId];


                           break;
                       }
                       case SSDKResponseStateFail:
                       {


                           CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                             messageAsString:[NSString stringWithFormat:[error.userInfo valueForKey:@"error_message"]]
                                                            ];
                           [self.commandDelegate sendPluginResult:pluginResult
                                                       callbackId:command.callbackId];
                           break;
                       }
                       case SSDKResponseStateCancel:
                       {

                           CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                             messageAsString:[NSString stringWithFormat:@"cancel"]
                                                            ];

                           [self.commandDelegate sendPluginResult:pluginResult
                                                       callbackId:command.callbackId];

                           break;
                       }
                       default:
                           break;
                   }

               }];
    
}



@end

