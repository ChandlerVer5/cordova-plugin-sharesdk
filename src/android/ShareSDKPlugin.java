package com.wjipet.sharesdk;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.device.Device;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;

import cn.sharesdk.framework.Platform;
import cn.sharesdk.framework.PlatformActionListener;
import cn.sharesdk.framework.PlatformDb;
import cn.sharesdk.framework.ShareSDK;
import cn.sharesdk.onekeyshare.OnekeyShare;
import cn.sharesdk.sina.weibo.SinaWeibo;
import cn.sharesdk.tencent.qq.QQ;
import cn.sharesdk.wechat.friends.Wechat;

import com.mob.MobSDK;
import com.mob.tools.utils.Hashon;
import com.mob.tools.utils.UIHandler;

public class ShareSDKPlugin extends CordovaPlugin {

  private Activity activity;
  
      /**参考sharesdk中ios枚举型:SSDKResponseState*/
    private static final int RESPONSE_STATE_BEGIN = 0;
    private static final int RESPONSE_STATE_SUCCESS = 1;
    private static final int RESPONSE_STATE_FAIL = 2;
    private static final int RESPONSE_STATE_CANCEL = 3;
    

  public ShareSDKPlugin() {
  }
  
  @Override
  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    this.activity = cordova.getActivity();

      try{
        ApplicationInfo appInfo = this.activity.getPackageManager().getApplicationInfo(this.activity.getPackageName(), PackageManager.GET_META_DATA);
        String appKey = appInfo.metaData.getString("Mob-AppKey");
        String appSecret = appInfo.metaData.getString("Mob-AppSecret");
        //调用initSDK初始化
        MobSDK.init(this.activity, appKey, appSecret);

      } catch (PackageManager.NameNotFoundException e) {
        e.printStackTrace();
      }
  }
  
 @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    if ("share".equals(action)) {
      showShare(args.optString(0, ""), args.optString(1, ""), args.optString(2, ""), args.optString(3, ""), callbackContext);
    } else if ("login".equals(action)) {
      login(args.optString(0, ""), callbackContext);
    } else if ("auth".equals(action)) {
      auth(args.optString(0, ""), callbackContext);
    } else if ("logout".equals(action)) {
      removeAuth(args.optString(0, ""));
    } else {
      return false;
    }
    return true;
  }


  private void showShare(String title, String content, String image, String url, final CallbackContext callbackContext) {
    OnekeyShare oks = new OnekeyShare();
    //关闭sso授权
    oks.disableSSOWhenAuthorize();
    // title标题，印象笔记、邮箱、信息、微信、人人网、QQ和QQ空间使用
    oks.setTitle(title);
    // titleUrl是标题的网络链接，仅在Linked-in,QQ和QQ空间使用
    oks.setTitleUrl(url);
    // site是分享此内容的网站名称，仅在QQ空间使用
    oks.setSite(title);
    // siteUrl是分享此内容的网站地址，仅在QQ空间使用
    oks.setSiteUrl(url);
    // text是分享文本，所有平台都需要这个字段
    oks.setText(content);
    //分享网络图片，新浪微博分享网络图片需要通过审核后申请高级写入接口，否则请注释掉测试新浪微博
    oks.setImageUrl(image);
    // imagePath是图片的本地路径，Linked-In以外的平台都支持此参数
    //oks.setImagePath("/sdcard/test.jpg");//确保SDcard下面存在此张图片
    // url仅在微信（包括好友和朋友圈）中使用
    oks.setUrl(url);
    // comment是我对这条分享的评论，仅在人人网和QQ空间使用
    oks.setComment(content);
    oks.setCallback(new PlatformActionListener() {
        @Override
        public void onComplete(Platform platform, int i, HashMap<String, Object> hashMap) {
            if(callbackContext!=null)
                callbackContext.success();
        }
        @Override
        public void onError(Platform platform, int i, Throwable throwable) {
            if(callbackContext!=null) {
                JSONObject jsonObject = new JSONObject();
                try {
                    jsonObject.putOpt("state", RESPONSE_STATE_FAIL);
                    jsonObject.putOpt("error", throwable.toString());
                } catch (JSONException e) {
                    e.printStackTrace();
                }finally {
                    callbackContext.error(jsonObject);
                }
            }
        }
        @Override
        public void onCancel(Platform platform, int i) {
            if(callbackContext!=null) {
                JSONObject jsonObject = new JSONObject();
                try {
                    jsonObject.putOpt("state", RESPONSE_STATE_CANCEL);
                } catch (JSONException e) {
                    e.printStackTrace();
                }finally {
                    callbackContext.error(jsonObject);
                }
            }
        }});

    // 启动分享GUI
    oks.show(this.activity);
  }


  private void auth(String platformName, final CallbackContext callbackContext) {
    String name = platformName.toLowerCase();
    if (name.equals("qq")) {
      name = QQ.NAME;
    } else if (name.equals("sina")) {
      name = SinaWeibo.NAME;
    } else if (name.equals("wechat")) {
      name = Wechat.NAME;
    }
    Platform platform = ShareSDK.getPlatform(name);
//回调信息，可以在这里获取基本的授权返回的信息，但是注意如果做提示和UI操作要传到主线程handler里去执行
    platform.setPlatformActionListener(new PlatformActionListener() {

      @Override
      public void onError(Platform arg0, int arg1, Throwable arg2) {
        JSONObject r = new JSONObject();
        try {
          r.put("platform", arg0);
          r.put("code", arg1);
          r.put("error", arg2);
        } catch (JSONException e) {
          e.printStackTrace();
        }
        callbackContext.error(r);
      }

      @Override
      public void onComplete(Platform platform, int action, HashMap<String, Object> res) {

        if (action == Platform.ACTION_AUTHORIZING) {
          PlatformDb platDB = platform.getDb();//获取数平台数据DB
          //通过DB获取各种数据
          try {
            JSONObject r = new JSONObject();
            r.put("token", platDB.getToken());
            r.put("icon", platDB.getUserIcon());
            r.put("id", platDB.getUserId());
            r.put("name", platDB.getUserName());
            r.put("user_gender", platDB.getUserGender());
            r.put("export-data",platform.getDb().exportData());
            callbackContext.success(r);
            return;
          } catch (JSONException e) {
            e.printStackTrace();
          }
        }
        callbackContext.error("failed");
      }

      @Override
      public void onCancel(Platform arg0, int arg1) {
        callbackContext.error("cancel");
      }
    });
//authorize与showUser单独调用一个即可
    platform.authorize();//单独授权,OnComplete返回的hashmap是空的
//    platform.showUser(null);//授权并获取用户信息
  }

  private void login(String platformName, final CallbackContext callbackContext) {
    String name = platformName.toLowerCase();
    if (name.equals("qq")) {
      name = QQ.NAME;
    } else if (name.equals("sina")) {
      name = SinaWeibo.NAME;
    } else if (name.equals("wechat")) {
      name = Wechat.NAME;
    }
    Platform platform = ShareSDK.getPlatform(name);
//回调信息，可以在这里获取基本的授权返回的信息，但是注意如果做提示和UI操作要传到主线程handler里去执行
    platform.setPlatformActionListener(new PlatformActionListener() {

      @Override
      public void onError(Platform arg0, int arg1, Throwable arg2) {
        JSONObject r = new JSONObject();
        try {
          r.put("platform", arg0);
          r.put("code", arg1);
          r.put("error", arg2);
        } catch (JSONException e) {
          e.printStackTrace();
        }
        callbackContext.error(r);
      }

      @Override
      public void onComplete(Platform platform, int action, HashMap<String, Object> res) {
        if (action == Platform.ACTION_USER_INFOR) {
          PlatformDb platDB = platform.getDb();//获取数平台数据DB
          //通过DB获取各种数据
          try {
            JSONObject r = new JSONObject();
            r.put("token", platDB.getToken());
            r.put("icon", platDB.getUserIcon());
            r.put("id", platDB.getUserId());
            r.put("name", platDB.getUserName());
            r.put("user_gender", platDB.getUserGender());
            r.put("export-data",platform.getDb().exportData());
            callbackContext.success(r);
            return;
          } catch (JSONException e) {
            e.printStackTrace();
          }
        }
        callbackContext.error("failed");
      }

      @Override
      public void onCancel(Platform arg0, int arg1) {
        callbackContext.error("cancel");
      }
    });
//authorize与showUser单独调用一个即可
    //platform.authorize();//单独授权,OnComplete返回的hashmap是空的
    platform.showUser(null);//授权并获取用户信息
  }

  private void removeAuth(String platformName) {
    String name = platformName.toLowerCase();
    if (name.equals("qq")) {
      name = QQ.NAME;
    } else if (name.equals("sina")) {
      name = SinaWeibo.NAME;
    } else if (name.equals("wechat")) {
      name = Wechat.NAME;
    }
    Platform platform = ShareSDK.getPlatform(name);
//移除授权
    platform.removeAccount(true);
  }

  

}


