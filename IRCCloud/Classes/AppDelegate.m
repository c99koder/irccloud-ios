//
//  AppDelegate.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <SafariServices/SafariServices.h>
#import <AdSupport/AdSupport.h>
#import <Intents/Intents.h>
#import "AppDelegate.h"
#import "NetworkConnection.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "config.h"
#import "URLHandler.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "AvatarsDataSource.h"
#import "ImageCache.h"
#import "LogExportsTableViewController.h"
#import "ImageViewController.h"
#import "SettingsViewController.h"
#import "ColorFormatter.h"
#import "EventsDataSource.h"
#import "AvatarsDataSource.h"
#if DEBUG
#import "FLEXManager.h"
#endif
@import Firebase;

extern NSURL *__logfile;

#ifdef DEBUG
@implementation NSURLRequest(CertificateHack)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}
@end
#endif

//From: http://stackoverflow.com/a/19313559
@interface NavBarHax : UINavigationBar

@property (nonatomic, assign) BOOL changingUserInteraction;
@property (nonatomic, assign) BOOL userInteractionChangedBySystem;

@end

@implementation NavBarHax

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.userInteractionChangedBySystem && self.userInteractionEnabled == NO) {
        return [super hitTest:point withEvent:event];
    }
    
    if ([self pointInside:point withEvent:event]) {
        self.changingUserInteraction = YES;
        self.userInteractionEnabled = YES;
        self.changingUserInteraction = NO;
    } else {
        self.changingUserInteraction = YES;
        self.userInteractionEnabled = NO;
        self.changingUserInteraction = NO;
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    if (!self.changingUserInteraction) {
        self.userInteractionChangedBySystem = YES;
    } else {
        self.userInteractionChangedBySystem = NO;
    }
    
    [super setUserInteractionEnabled:userInteractionEnabled];
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef ENTERPRISE
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    if(sharedcontainer) {
        __logfile = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"log.txt"];
        [[NSFileManager defaultManager] removeItemAtURL:__logfile error:nil];
    }
#ifdef CRASHLYTICS_TOKEN
    if([FIROptions defaultOptions]) {
        [FIRApp configure];
#if !TARGET_OS_MACCATALYST
        [FIRAnalytics setUserID:nil];
#endif
    }
#endif
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    UNTextInputNotificationAction *replyAction = [UNTextInputNotificationAction actionWithIdentifier:@"reply" title:@"Reply" options:UNNotificationActionOptionAuthenticationRequired textInputButtonTitle:@"Send" textInputPlaceholder:@""];
    
    UNNotificationAction *joinAction = [UNNotificationAction actionWithIdentifier:@"join" title:@"Join" options:UNNotificationActionOptionForeground];
    UNNotificationAction *acceptAction = [UNNotificationAction actionWithIdentifier:@"accept" title:@"Accept" options:UNNotificationActionOptionNone];
    UNNotificationAction *retryAction = [UNNotificationAction actionWithIdentifier:@"retry" title:@"Retry" options:UNNotificationActionOptionNone];
    //UNNotificationAction *readAction = [UNNotificationAction actionWithIdentifier:@"read" title:@"Mark As Read" options:UNNotificationActionOptionNone];

    if (@available(iOS 12, *)) {
        [center setNotificationCategories:[NSSet setWithObjects:
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_msg" actions:@[replyAction/*,readAction*/] intentIdentifiers:@[INSendMessageIntentIdentifier] hiddenPreviewsBodyPlaceholder:@"New message" categorySummaryFormat:@"%u more messages" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_me_msg" actions:@[replyAction/*,readAction*/] intentIdentifiers:@[INSendMessageIntentIdentifier] hiddenPreviewsBodyPlaceholder:@"New message" categorySummaryFormat:@"%u more messages" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"channel_invite" actions:@[joinAction] intentIdentifiers:@[] hiddenPreviewsBodyPlaceholder:@"Channel invite" categorySummaryFormat:@"%u more channel invites" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"callerid" actions:@[acceptAction] intentIdentifiers:@[] hiddenPreviewsBodyPlaceholder:@"Caller ID" categorySummaryFormat:@"%u more notifications" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"retry" actions:@[retryAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           nil]];
    } else if (@available(iOS 11, *)) {
        [center setNotificationCategories:[NSSet setWithObjects:
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_msg" actions:@[replyAction/*,readAction*/] intentIdentifiers:@[INSendMessageIntentIdentifier] hiddenPreviewsBodyPlaceholder:@"New message" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_me_msg" actions:@[replyAction/*,readAction*/] intentIdentifiers:@[INSendMessageIntentIdentifier] hiddenPreviewsBodyPlaceholder:@"New message" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"channel_invite" actions:@[joinAction] intentIdentifiers:@[] hiddenPreviewsBodyPlaceholder:@"Channel invite" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"callerid" actions:@[acceptAction] intentIdentifiers:@[] hiddenPreviewsBodyPlaceholder:@"Caller ID" options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"retry" actions:@[retryAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           nil]];
    } else {
        [center setNotificationCategories:[NSSet setWithObjects:
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_msg" actions:@[replyAction/*,readAction*/] intentIdentifiers:@[INSendMessageIntentIdentifier] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_me_msg" actions:@[replyAction/*,readAction*/] intentIdentifiers:@[INSendMessageIntentIdentifier] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"channel_invite" actions:@[joinAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"callerid" actions:@[acceptAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"retry" actions:@[retryAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           nil]];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSURL *caches = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSFileManager defaultManager] removeItemAtURL:caches error:nil];
    
    sharedcontainer = [sharedcontainer URLByAppendingPathComponent:@"attachments/"];
    [[NSFileManager defaultManager] removeItemAtURL:sharedcontainer error:nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":IRCCLOUD_HOST, @"saveToCameraRoll":@(YES), @"photoSize":@(1024), @"notificationSound":@(YES), @"tabletMode":@(YES), @"imageService":@"IRCCloud", @"uploadsAvailable":@(NO), @"browser":[SFSafariViewController class]?@"IRCCloud":@"Safari", @"warnBeforeLaunchingBrowser":@(NO), @"imageViewer":@(YES), @"videoViewer":@(YES), @"inlineWifiOnly":@(NO), @"iCloudLogs":@(NO), @"clearFormattingAfterSending":@(YES)}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"fontSize":@([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 0.8)}];

    if (@available(iOS 13, *)) {
        if([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark)
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"theme":@"automatic"}];
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"path"]) {
        IRCCLOUD_HOST = [[NSUserDefaults standardUserDefaults] objectForKey:@"host"];
        IRCCLOUD_PATH = [[NSUserDefaults standardUserDefaults] objectForKey:@"path"];
    } else if([NetworkConnection sharedInstance].session.length) {
        CLS_LOG(@"Session cookie found without websocket path");
        [NetworkConnection sharedInstance].session = nil;
    }

    if([[NSUserDefaults standardUserDefaults] objectForKey:@"useChrome"]) {
        CLS_LOG(@"Migrating browser setting");
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"])
            [[NSUserDefaults standardUserDefaults] setObject:@"Chrome" forKey:@"browser"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"useChrome"];
    }
    
    self->_conn = [NetworkConnection sharedInstance];
#ifdef DEBUG
    if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        
        IRCCLOUD_HOST = @"MOCK.HOST";
        IRCCLOUD_PATH = @"/";
        [NetworkConnection sharedInstance].mock = YES;
        if([[NSProcessInfo processInfo].arguments containsObject:@"-mono"])
            [NetworkConnection sharedInstance].userInfo = @{@"last_selected_bid":@(5), @"prefs":@"{\"font\":\"mono\"}"};
        else
            [NetworkConnection sharedInstance].userInfo = @{@"last_selected_bid":@(5)};
        
        [[ServersDataSource sharedInstance] clear];
        [[BuffersDataSource sharedInstance] clear];
        [[ChannelsDataSource sharedInstance] clear];
        [[UsersDataSource sharedInstance] clear];
        [[EventsDataSource sharedInstance] clear];

        [[NetworkConnection sharedInstance] fetchOOB:@"https://irccloud.com/test/bufferview.json"];
    }
#endif
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [ColorFormatter loadFonts];
    [UIColor setTheme];
    [self.mainViewController applyTheme];
    [[EventsDataSource sharedInstance] reformat];
    
    if(IRCCLOUD_HOST.length < 1)
    [NetworkConnection sharedInstance].session = nil;
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    [d setObject:IRCCLOUD_HOST forKey:@"host"];
    [d setObject:IRCCLOUD_PATH forKey:@"path"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] forKey:@"photoSize"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] forKey:@"cacheVersion"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"uploadsAvailable"] forKey:@"uploadsAvailable"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] forKey:@"imageService"];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_access_token"])
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_access_token"] forKey:@"imgur_access_token"];
    else
        [d removeObjectForKey:@"imgur_access_token"];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_refresh_token"])
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_refresh_token"] forKey:@"imgur_refresh_token"];
    else
        [d removeObjectForKey:@"imgur_refresh_token"];
    [d synchronize];
    
    self.splashViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SplashViewController"];
    self.splashViewController.view.accessibilityIgnoresInvertColors = YES;
    self.window.rootViewController = self.splashViewController;
    self.loginSplashViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginSplashViewController"];
    //if(@available(iOS 11, *))
    //    self.loginSplashViewController.view.accessibilityIgnoresInvertColors = YES;
    self.mainViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"MainViewController"];
    self.slideViewController = [[ECSlidingViewController alloc] init];
    self.slideViewController.view.backgroundColor = [UIColor blackColor];
    self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
    [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
    self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    self.slideViewController.view.accessibilityIgnoresInvertColors = YES;
    if(launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        self.mainViewController.bidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:1] intValue];
        self.mainViewController.eidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:2] doubleValue];
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *session = [NetworkConnection sharedInstance].session;
        if(session != nil && [session length] > 0 && IRCCLOUD_HOST.length > 0) {
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
            self.window.rootViewController = self.slideViewController;
        } else {
            self.window.rootViewController = self.loginSplashViewController;
        }
        
#ifdef DEBUG
        if(![[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
#endif
            [self.window addSubview:self.splashViewController.view];
            
            if([NetworkConnection sharedInstance].session.length) {
                [self.splashViewController animate:nil];
            } else {
                self.loginSplashViewController.logo.hidden = YES;
                [self.splashViewController animate:self.loginSplashViewController.logo];
            }
            
            [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
                self.splashViewController.view.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL finished) {
                self.loginSplashViewController.logo.hidden = NO;
                [self.splashViewController.view removeFromSuperview];
            }];
#ifdef DEBUG
        }
#endif
    }];
    
    [[ImageCache sharedInstance] performSelectorInBackground:@selector(prune) withObject:nil];
    
#if TARGET_IPHONE_SIMULATOR
#ifdef FLEX
    [FLEXManager sharedManager].simulatorShortcutsEnabled = YES;
#endif
#endif
    return YES;
}

-(BOOL)continueActivity:(NSUserActivity *)userActivity {
    CLS_LOG(@"Continuing activity type: %@", userActivity.activityType);
#if !TARGET_OS_MACCATALYST
    if([FIROptions defaultOptions])
        [FIRAnalytics handleUserActivity:userActivity];
#endif
#ifdef ENTERPRISE
    if([userActivity.activityType isEqualToString:@"com.irccloud.enterprise.buffer"])
#else
    if([userActivity.activityType isEqualToString:@"com.irccloud.buffer"])
#endif
    {
        if([userActivity.userInfo objectForKey:@"bid"]) {
            self.mainViewController.bidToOpen = [[userActivity.userInfo objectForKey:@"bid"] intValue];
            self.mainViewController.eidToOpen = 0;
            self.mainViewController.incomingDraft = [userActivity.userInfo objectForKey:@"draft"];
            CLS_LOG(@"Opening BID from handoff: %i", self.mainViewController.bidToOpen);
            [self.mainViewController bufferSelected:[[userActivity.userInfo objectForKey:@"bid"] intValue]];
            [self showMainView:YES];
            return YES;
        }
    } else if([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        [self launchURL:userActivity.webpageURL];
    }
    
    return NO;
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    return [self continueActivity:userActivity];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
#if !TARGET_OS_MACCATALYST
    if([FIROptions defaultOptions])
        [FIRAnalytics handleOpenURL:url];
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if([url.scheme hasPrefix:@"irccloud"]) {
        if([url.host isEqualToString:@"chat"] && [url.path isEqualToString:@"/access-link"]) {
            [[NetworkConnection sharedInstance] logout];
            self.loginSplashViewController.accessLink = url;
            self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
            self.loginSplashViewController.view.alpha = 1;
            if(self.window.rootViewController == self.loginSplashViewController)
                [self.loginSplashViewController viewWillAppear:YES];
            else
                self.window.rootViewController = self.loginSplashViewController;
        } else {
            return NO;
        }
    } else {
        [self launchURL:url];
    }
    return YES;
}

- (void)launchURL:(NSURL *)url {
    if (!_urlHandler) {
        self->_urlHandler = [[URLHandler alloc] init];
#ifdef ENTERPRISE
        self->_urlHandler.appCallbackURL = [NSURL URLWithString:@"irccloud-enterprise://"];
#else
        self->_urlHandler.appCallbackURL = [NSURL URLWithString:@"irccloud://"];
#endif
        
    }
    [self->_urlHandler launchURL:url];
}

-(void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    NSData *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"];
    
    [[FIRMessaging messaging] tokenWithCompletion:^(NSString *token, NSError *error) {
        if (error != nil) {
            CLS_LOG(@"Error fetching FIRMessaging token: %@", error);
        } else {
            //CLS_LOG(@"FCM Token: %@", result.token);
            if(oldToken && ![devToken isEqualToData:oldToken]) {
              CLS_LOG(@"Unregistering old APNs token");
                [self->_conn unregisterAPNs:oldToken fcm:token session:self->_conn.session handler:^(IRCCloudJSONObject *result) {
                  CLS_LOG(@"Unregistration result: %@", result);
              }];
            }
            [[NSUserDefaults standardUserDefaults] setObject:devToken forKey:@"APNs"];
            [self->_conn registerAPNs:devToken fcm:token handler:^(IRCCloudJSONObject *result) {
              CLS_LOG(@"Registration result: %@", result);
            }];
        }
    }];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    CLS_LOG(@"Error in APNs registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    if([userInfo objectForKey:@"d"]) {
        int cid = [[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue];
        int bid = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        NSTimeInterval eid = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        
        if(application.applicationState == UIApplicationStateBackground && (!_conn || (self->_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting))) {
            [[NotificationsDataSource sharedInstance] notify:nil category:nil cid:cid bid:bid eid:eid];
        }
        
        if(self->_movedToBackground && application.applicationState == UIApplicationStateInactive) {
            self.mainViewController.bidToOpen = bid;
            self.mainViewController.eidToOpen = eid;
            CLS_LOG(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
            [UIColor setTheme];
            [self.mainViewController applyTheme];
            [self.mainViewController bufferSelected:bid];
            [self showMainView:YES];
        } else if(application.applicationState == UIApplicationStateBackground && (!_conn || (self->_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting))) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CLS_LOG(@"Preloading backlog for bid%i from notification", bid);
                [[NetworkConnection sharedInstance] requestBacklogForBuffer:bid server:cid completion:^(BOOL success) {
                    [self.mainViewController refresh];
                    [[NotificationsDataSource sharedInstance] updateBadgeCount];
                    if(success) {
                        CLS_LOG(@"Backlog download completed for bid%i", bid);
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[NetworkConnection sharedInstance] serialize];
                            handler(UIBackgroundFetchResultNewData);
                        });
                    } else {
                        CLS_LOG(@"Backlog download failed for bid%i", bid);
                        handler(UIBackgroundFetchResultFailed);
                    }
                }];
            });
        } else {
            handler(UIBackgroundFetchResultNoData);
        }
    } else if ([userInfo objectForKey:@"hb"] && application.applicationState == UIApplicationStateBackground) {
        //CLS_LOG(@"APNS Heartbeat: %@", userInfo);
        for(NSString *key in [userInfo objectForKey:@"hb"]) {
            NSDictionary *bids = [[userInfo objectForKey:@"hb"] objectForKey:key];
            for(NSString *bid in bids.allKeys) {
                NSTimeInterval eid = [[bids objectForKey:bid] doubleValue];
                //CLS_LOG(@"Setting bid %i last_seen_eid to %f", bid.intValue, eid);
                [[BuffersDataSource sharedInstance] updateLastSeenEID:eid buffer:bid.intValue];
                [[NotificationsDataSource sharedInstance] removeNotificationsForBID:bid.intValue olderThan:eid];
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NetworkConnection sharedInstance] serialize];
            handler(UIBackgroundFetchResultNoData);
        });
    } else {
        handler(UIBackgroundFetchResultNoData);
    }
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if([notification.request.content.userInfo objectForKey:@"d"]) {
        int bid = [[[notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        NSTimeInterval eid = [[[notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
        if(self->_mainViewController.buffer.bid != bid && eid > b.last_seen_eid) {
            completionHandler(UNNotificationPresentationOptionAlert + UNNotificationPresentationOptionSound);
            return;
        }
    } else if([notification.request.content.userInfo objectForKey:@"view_logs"]) {
        if([UIApplication sharedApplication].applicationState == UIApplicationStateActive && [self->_mainViewController.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)_mainViewController.presentedViewController).topViewController isKindOfClass:[LogExportsTableViewController class]])
            completionHandler(UNNotificationPresentationOptionNone);
        else
            completionHandler(UNNotificationPresentationOptionAlert + UNNotificationPresentationOptionSound);
    }
    completionHandler(UNNotificationPresentationOptionNone);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [UIColor setTheme];
    [self.mainViewController applyTheme];
    if([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
        [self handleAction:response.actionIdentifier userInfo:response.notification.request.content.userInfo response:((UNTextInputNotificationResponse *)response).userText completionHandler:completionHandler];
    } else if([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
        if([response.notification.request.content.userInfo objectForKey:@"view_logs"]) {
            LogExportsTableViewController *lvc = [[LogExportsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            lvc.buffer = self->_mainViewController.buffer;
            lvc.server = [[ServersDataSource sharedInstance] getServer:self->_mainViewController.buffer.cid];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:lvc];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self showMainView:YES];
            [self->_mainViewController presentViewController:nc animated:YES completion:nil];
        } else {
            if([response.notification.request.content.userInfo objectForKey:@"d"]) {
                self.mainViewController.bidToOpen = [[[response.notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
                self.mainViewController.eidToOpen = [[[response.notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
                CLS_LOG(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
                [UIColor setTheme];
                [self.mainViewController applyTheme];
                [self.mainViewController bufferSelected:[[[response.notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
                [self showMainView:YES];
            }
        }
        completionHandler();
    } else {
        [self handleAction:response.actionIdentifier userInfo:response.notification.request.content.userInfo response:nil completionHandler:completionHandler];
    }
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIColor setTheme];
        [self.mainViewController applyTheme];
        [self showMainView:NO];
        SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        svc.scrollToNotifications = YES;
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self.mainViewController presentViewController:nc animated:NO completion:nil];
    }];
}

-(void)handleAction:(NSString *)identifier userInfo:(NSDictionary *)userInfo response:(NSString *)response completionHandler:(void (^)())completionHandler {
    IRCCloudAPIResultHandler handler = ^(IRCCloudJSONObject *result) {
        if([[result objectForKey:@"success"] intValue] == 1) {
            if([identifier isEqualToString:@"reply"]) {
                AudioServicesPlaySystemSound(1001);
            } else if([identifier isEqualToString:@"read"]) {
                Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
                if(b && b.last_seen_eid < [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue])
                    b.last_seen_eid = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
                [[NotificationsDataSource sharedInstance] removeNotificationsForBID:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue] olderThan:[[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue]];
                [[NotificationsDataSource sharedInstance] updateBadgeCount];
            } else if([identifier isEqualToString:@"join"]) {
                Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1] server:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
                if(b) {
                    [self.mainViewController bufferSelected:b.bid];
                } else {
                    self.mainViewController.cidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue];
                    self.mainViewController.bufferToOpen = [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1];
                }
                [self showMainView:YES];
            }
        } else {
            CLS_LOG(@"Failed: %@ %@", identifier, result);
            NSString *alertBody = @"";
            if([identifier isEqualToString:@"reply"]) {
                Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0] server:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
                if(b)
                    b.draft = response;
                alertBody = [NSString stringWithFormat:@"Failed to send message to %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0]];
            } else if([identifier isEqualToString:@"join"]) {
                alertBody = [NSString stringWithFormat:@"Failed to join %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1]];
            } else if([identifier isEqualToString:@"accept"]) {
                alertBody = [NSString stringWithFormat:@"Failed to add %@ to accept list", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0]];
            }
            NSDictionary *ui;
            if(response)
                ui = @{@"identifier":identifier, @"userInfo":userInfo, @"responseInfo":@{UIUserNotificationActionResponseTypedTextKey:response}, @"d":[userInfo objectForKey:@"d"]};
            else
                ui = @{@"identifier":identifier, @"userInfo":userInfo, @"d":[userInfo objectForKey:@"d"]};
            [[NotificationsDataSource sharedInstance] alert:alertBody title:nil category:@"retry" userInfo:ui];
        }
        
        completionHandler();
    };
    
    if([identifier isEqualToString:@"reply"]) {
        [[NetworkConnection sharedInstance] POSTsay:response
                                                 to:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-key"] hasSuffix:@"CH"]?2:0]
                                                cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]
                                            handler:handler];
    } else if([identifier isEqualToString:@"join"]) {
        [[NetworkConnection sharedInstance] POSTsay:[NSString stringWithFormat:@"/join %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1]]
                                                 to:@""
                                                cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]
                                            handler:handler];
    } else if([identifier isEqualToString:@"accept"]) {
        [[NetworkConnection sharedInstance] POSTsay:[NSString stringWithFormat:@"/accept %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0]]
                                                 to:@""
                                                cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]
                                            handler:handler];
    } else if([identifier isEqualToString:@"read"]) {
        [[NetworkConnection sharedInstance] POSTheartbeat:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue] cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue] bid:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue] lastSeenEid:[[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue] handler:handler];
    }
}

-(void)showLoginView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
        self.loginSplashViewController.view.alpha = 1;
        self.window.rootViewController = self.loginSplashViewController;
#ifndef ENTERPRISE
        [self.loginSplashViewController loginHintPressed:nil];
#endif
    }];
}

-(void)showMainView {
    [self showMainView:YES];
}

-(void)showMainView:(BOOL)animated {
    if([NetworkConnection sharedInstance].session.length) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIColor setTheme];
        [self.mainViewController applyTheme];
        if(animated) {
            if([NetworkConnection sharedInstance].state != kIRCCloudStateConnected)
                [[NetworkConnection sharedInstance] connect:NO];

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [UIApplication sharedApplication].statusBarHidden = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
                self.slideViewController.view.alpha = 1;
                if(self.window.rootViewController != self.slideViewController) {
                    if([self.window.rootViewController isKindOfClass:ImageViewController.class])
                        self.mainViewController.ignoreVisibilityChanges = YES;
                    BOOL fromLoginView = (self.window.rootViewController == self.loginSplashViewController);
                    UIView *v = self.window.rootViewController.view;
                    self.window.rootViewController = self.slideViewController;
                    [self.window insertSubview:v aboveSubview:self.window.rootViewController.view];
                    self.mainViewController.ignoreVisibilityChanges = NO;
                    if(fromLoginView)
                        [self.loginSplashViewController hideLoginView];
                    [UIView animateWithDuration:0.5f animations:^{
                        v.alpha = 0;
                    } completion:^(BOOL finished){
                        [v removeFromSuperview];
                        self.window.backgroundColor = [UIColor textareaBackgroundColor];
                    }];
                }
            }];
        } else if(self.window.rootViewController != self.slideViewController) {
            if([self.window.rootViewController isKindOfClass:ImageViewController.class])
                self.mainViewController.ignoreVisibilityChanges = YES;
            [UIApplication sharedApplication].statusBarHidden = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
            self.slideViewController.view.alpha = 1;
            [self.window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            self.window.rootViewController = self.slideViewController;
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
            self.mainViewController.ignoreVisibilityChanges = NO;
        }
        }];
        if(self.slideViewController.presentedViewController)
            [self.slideViewController dismissViewControllerAnimated:animated completion:nil];
    }
}

-(void)showConnectionView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped]];
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CLS_LOG(@"App entering background");
#ifndef DEBUG
#ifdef ENTERPRISE
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    if(sharedcontainer) {
        NSURL *logfile = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"log.txt"];
        
        NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:(-60*60*24)];
        NSDate *modificationDate = nil;
        [logfile getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];

        if([yesterday compare:modificationDate] == NSOrderedDescending) {
            [[NSFileManager defaultManager] removeItemAtURL:logfile error:nil];
        }
    }
#endif
    self->_conn = [NetworkConnection sharedInstance];
    self->_movedToBackground = YES;
    self->_conn.failCount = 0;
    self->_conn.reconnectTimestamp = 0;
    [self->_conn cancelIdleTimer];
    if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
        [evc.topViewController viewWillDisappear:NO];
    } else {
        [self.window.rootViewController viewWillDisappear:NO];
    }
    
    __block UIBackgroundTaskIdentifier background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        if(background_task == self->_background_task) {
            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                CLS_LOG(@"Background task expired, disconnecting websocket");
                [self->_conn performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
                [self->_conn serialize];
                [NetworkConnection sync];
            }
            self->_background_task = UIBackgroundTaskInvalid;
        }
    }];
    self->_background_task = background_task;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
            if(!b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
        }
        [self->_conn serialize];
        [NSThread sleepForTimeInterval:[UIApplication sharedApplication].backgroundTimeRemaining - 5];
        if(background_task == self->_background_task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_background_task = UIBackgroundTaskInvalid;
                if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                    CLS_LOG(@"Background task timed out, disconnecting websocket");
                    [[NetworkConnection sharedInstance] disconnect];
                    [[NetworkConnection sharedInstance] serialize];
                    [NetworkConnection sync];
                }
                [application endBackgroundTask: background_task];
            });
        }
    });
    if(self.window.rootViewController != self->_slideViewController && [ServersDataSource sharedInstance].count) {
        [self showMainView:NO];
        self.window.backgroundColor = [UIColor blackColor];
    }
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
    [[ImageCache sharedInstance] clearFailedURLs];
    [[ImageCache sharedInstance] performSelectorInBackground:@selector(prune) withObject:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self->_conn = [NetworkConnection sharedInstance];
    CLS_LOG(@"App became active, state: %i notifier: %i movedToBackground: %i reconnectTimestamp: %f", _conn.state, _conn.notifier, _movedToBackground, _conn.reconnectTimestamp);
    
    if(self->_backlogCompletedObserver) {
        CLS_LOG(@"Backlog completed observer was registered, removing");
        [[NSNotificationCenter defaultCenter] removeObserver:self->_backlogCompletedObserver];
        self->_backlogCompletedObserver = nil;
    }
    if(self->_backlogFailedObserver) {
        CLS_LOG(@"Backlog failed observer was registered, removing");
        [[NSNotificationCenter defaultCenter] removeObserver:self->_backlogFailedObserver];
        self->_backlogFailedObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self->_conn.reconnectTimestamp == 0)
        self->_conn.reconnectTimestamp = -1;
    self->_conn.failCount = 0;
    self->_conn.reachabilityValid = NO;
    if(self->_conn.session.length && self->_conn.state != kIRCCloudStateConnected && self->_conn.state != kIRCCloudStateConnecting) {
        CLS_LOG(@"Attempting to reconnect on app resume");
        [self->_conn connect:NO];
    } else if(self->_conn.notifier) {
        CLS_LOG(@"Clearing notifier flag");
        self->_conn.notifier = NO;
    } else {
        CLS_LOG(@"Not attempting to reconnect, session length: %i state: %i", self->_conn.session.length, self->_conn.state);
    }
    
    if(self->_movedToBackground) {
        self->_movedToBackground = NO;
        if([ColorFormatter shouldClearFontCache]) {
            [ColorFormatter clearFontCache];
            [[EventsDataSource sharedInstance] clearFormattingCache];
            [[AvatarsDataSource sharedInstance] clear];
            [ColorFormatter loadFonts];
        }
        self->_conn.reconnectTimestamp = -1;
        if(_conn.state == kIRCCloudStateConnected)
            [self->_conn scheduleIdleTimer];
        if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
            ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
            [evc.topViewController viewWillAppear:NO];
        } else {
            [self.window.rootViewController viewWillAppear:NO];
        }
        if(self->_background_task != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:self->_background_task];
            self->_background_task = UIBackgroundTaskInvalid;
        }
    }
    
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    CLS_LOG(@"Application terminating, disconnecting websocket");
    [self->_conn disconnect];
    [self->_conn serialize];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    NSURLSessionConfiguration *config;
    config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
#ifdef ENTERPRISE
    config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
    config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
    config.HTTPCookieStorage = nil;
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    config.discretionary = NO;
    if([identifier hasPrefix:@"com.irccloud.logs."]) {
        LogExportsTableViewController *lvc;
        
        if([self->_mainViewController.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)_mainViewController.presentedViewController).topViewController isKindOfClass:[LogExportsTableViewController class]])
            lvc = (LogExportsTableViewController *)(((UINavigationController *)_mainViewController.presentedViewController).topViewController);
        else
            lvc = [[LogExportsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        
        lvc.completionHandler = completionHandler;
        [[NSURLSession sessionWithConfiguration:config delegate:lvc delegateQueue:[NSOperationQueue mainQueue]] finishTasksAndInvalidate];
    } else if([identifier hasPrefix:@"com.irccloud.share."]) {
        [[NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]] finishTasksAndInvalidate];
        imageUploadCompletionHandler = completionHandler;
    } else {
        CLS_LOG(@"Unrecognized background task: %@", identifier);
#if !TARGET_OS_MACCATALYST
        if([FIROptions defaultOptions])
            [FIRAnalytics handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
#endif
        completionHandler();
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    self->_conn = [NetworkConnection sharedInstance];
    NSData *response = [NSData dataWithContentsOfURL:location];
    if(session.configuration.identifier) {
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
        NSDictionary *dict = [uploadtasks objectForKey:session.configuration.identifier];
        [uploadtasks removeObjectForKey:session.configuration.identifier];
        [d setObject:uploadtasks forKey:@"uploadtasks"];
        [d synchronize];
        
        NSDictionary *r = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:nil];
        if(!r) {
            CLS_LOG(@"Invalid JSON response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        } else if([[r objectForKey:@"success"] intValue] == 1) {
            if([[dict objectForKey:@"service"] isEqualToString:@"irccloud"]) {
                CLS_LOG(@"Finalizing IRCCloud upload");
                [[NetworkConnection sharedInstance] finalizeUpload:[r objectForKey:@"id"] filename:[dict objectForKey:@"filename"] originalFilename:[dict objectForKey:@"original_filename"] avatar:[[dict objectForKey:@"avatar"] boolValue] orgId:[[dict objectForKey:@"orgId"] intValue] cid:[[dict objectForKey:@"cid"] intValue] handler:^(IRCCloudJSONObject *o) {
                    if([[o objectForKey:@"success"] intValue] == 1) {
                        CLS_LOG(@"IRCCloud upload successful");
                        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                        if(b) {
                            NSString *msg = [dict objectForKey:@"msg"];
                            NSString *msgid = [dict objectForKey:@"msgid"];
                            if(msg.length)
                                msg = [msg stringByAppendingString:@" "];
                            else
                                msg = @"";
                            msg = [msg stringByAppendingFormat:@"%@", [[o objectForKey:@"file"] objectForKey:@"url"]];
                            
                            IRCCloudAPIResultHandler handler = ^(IRCCloudJSONObject *result) {
                                [self.mainViewController fileUploadDidFinish];
                                AudioServicesPlaySystemSound(1001);
                                if(self->imageUploadCompletionHandler)
                                    self->imageUploadCompletionHandler();
                            };
                            
                            if(msgid.length > 0)
                                [[NetworkConnection sharedInstance] POSTreply:msg to:b.name cid:b.cid msgid:msgid handler:handler];
                            else
                                [[NetworkConnection sharedInstance] POSTsay:msg to:b.name cid:b.cid handler:handler];
                        }
                    } else {
                        CLS_LOG(@"IRCCloud upload failed");
                        [self.mainViewController fileUploadDidFail:[o objectForKey:@"message"]];
                        [[NSNotificationCenter defaultCenter] removeObserver:self->_IRCEventObserver];
                        NSString *alertBody;
                        if([[o objectForKey:@"message"] isEqualToString:@"upload_limit_reached"]) {
                            alertBody = @"Sorry, you can’t upload more than 100 MB of files.  Delete some uploads and try again.";
                        } else if([[o objectForKey:@"message"] isEqualToString:@"upload_already_exists"]) {
                            alertBody = @"You’ve already uploaded this file";
                        } else if([[o objectForKey:@"message"] isEqualToString:@"banned_content"]) {
                            alertBody = @"Banned content";
                        } else {
                            alertBody = @"Failed to upload file. Please try again shortly.";
                        }
                        [[NotificationsDataSource sharedInstance] alert:alertBody title:nil category:nil userInfo:nil];
                        if(self->imageUploadCompletionHandler)
                            self->imageUploadCompletionHandler();
                    }
                }];
            } else if([[dict objectForKey:@"service"] isEqualToString:@"imgur"]) {
                NSString *link = [[[r objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                
                if([dict objectForKey:@"msg"]) {
                    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                    [[NetworkConnection sharedInstance] POSTsay:[NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"msg"],link] to:b.name cid:b.cid handler:^(IRCCloudJSONObject *result) {
                        AudioServicesPlaySystemSound(1001);
                        if(self->imageUploadCompletionHandler)
                            self->imageUploadCompletionHandler();
                    }];
                } else {
                    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                        if(b) {
                            if(b.draft.length)
                                b.draft = [b.draft stringByAppendingFormat:@" %@",link];
                            else
                                b.draft = link;
                        }
                        [[NotificationsDataSource sharedInstance] alert:@"Your image has been uploaded and is ready to send" title:nil category:nil userInfo:@{@"d":@[@(b.cid), @(b.bid), @(-1)]}];
                    }
                    if(self->imageUploadCompletionHandler)
                        self->imageUploadCompletionHandler();
                }
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        CLS_LOG(@"Download error: %@", error);
        [[NotificationsDataSource sharedInstance] alert:@"Unable to share image. Please try again shortly." title:nil category:nil userInfo:nil];
    }
    [session finishTasksAndInvalidate];
}

-(void)addScene:(id)scene {
    if(!_activeScenes)
        _activeScenes = [[NSMutableSet alloc] init];
    
    [_activeScenes addObject:scene];
    
    if(_activeScenes.count == 1)
        [self applicationDidBecomeActive:[UIApplication sharedApplication]];
    
    [self setActiveScene:[scene window]];
    
    CLS_LOG(@"Active scene count: %i", _activeScenes.count);
}

-(void)removeScene:(id)scene {
    [_activeScenes removeObject:scene];

    if(_activeScenes.count == 0)
        [self applicationDidEnterBackground:[UIApplication sharedApplication]];

    CLS_LOG(@"Active scene count: %i", _activeScenes.count);
}

-(void)setActiveScene:(UIWindow *)window {
    if (@available(iOS 13.0, *)) {
        for(SceneDelegate *d in _activeScenes) {
            if(d.window == window) {
                self.window = d.window;
                self.splashViewController = d.splashViewController;
                self.loginSplashViewController = d.loginSplashViewController;
                self.mainViewController = d.mainViewController;
                self.slideViewController = d.slideViewController;
                break;
            }
        }
    }
}

-(UIScene *)sceneForWindow:(UIWindow *)window API_AVAILABLE(ios(13.0)){
    for(SceneDelegate *d in _activeScenes) {
        if(d.window == window) {
            return d.scene;
        }
    }
    return nil;
}

-(void)closeWindow:(UIWindow *)window {
    if (@available(iOS 13.0, *)) {
        for(UISceneSession *session in [UIApplication sharedApplication].openSessions) {
            if([session.scene.delegate isKindOfClass:SceneDelegate.class] && ((SceneDelegate *)session.scene.delegate).window == window) {
                [UIApplication.sharedApplication requestSceneSessionDestruction:session options:nil errorHandler:nil];
                break;
            }
        }
    }
}
@end

@implementation SceneDelegate
-(void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    _appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.scene = scene;

    for(NSUserActivity *a in connectionOptions.userActivities) {
        if([a.activityType isEqualToString:@"com.IRCCloud.settings"]) {
            SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            self.window.rootViewController = nc;
            ((UIWindowScene *)scene).sizeRestrictions.maximumSize = ((UIWindowScene *)scene).sizeRestrictions.minimumSize;
            return;
        }
    }
    
    self.splashViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SplashViewController"];
    self.splashViewController.view.accessibilityIgnoresInvertColors = YES;
    self.window.rootViewController = self.splashViewController;
    self.loginSplashViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginSplashViewController"];
    //if(@available(iOS 11, *))
    //    self.loginSplashViewController.view.accessibilityIgnoresInvertColors = YES;
    self.mainViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"MainViewController"];
    self.slideViewController = [[ECSlidingViewController alloc] init];
    self.slideViewController.view.backgroundColor = [UIColor blackColor];
    self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
    [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
    self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    self.slideViewController.view.accessibilityIgnoresInvertColors = YES;
}

-(void)sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [_appDelegate removeScene:self];
}

-(void)sceneDidBecomeActive:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [_appDelegate addScene:self];
}

-(void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
    [_appDelegate setActiveScene:self.window];
    for(UIOpenURLContext *c in URLContexts) {
        [_appDelegate application:[UIApplication sharedApplication] handleOpenURL:c.URL options:nil];
    }
}

-(void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity API_AVAILABLE(ios(13.0)) {
    [_appDelegate setActiveScene:self.window];
    [_appDelegate continueActivity:userActivity];
}

-(void)sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;

    if(self.window.rootViewController == self.splashViewController) {
        NSString *session = [NetworkConnection sharedInstance].session;
        if(session != nil && [session length] > 0 && IRCCLOUD_HOST.length > 0) {
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
            self.window.rootViewController = self.slideViewController;
            self.window.overrideUserInterfaceStyle = self.mainViewController.view.overrideUserInterfaceStyle;
        } else {
            self.window.rootViewController = self.loginSplashViewController;
        }
        
#ifdef DEBUG
        if(![[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
#endif
            [self.window addSubview:self.splashViewController.view];
            
            if([NetworkConnection sharedInstance].session.length) {
                [self.splashViewController animate:nil];
            } else {
                self.loginSplashViewController.logo.hidden = YES;
                [self.splashViewController animate:self.loginSplashViewController.logo];
            }
            
            [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
                self.splashViewController.view.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL finished) {
                self.loginSplashViewController.logo.hidden = NO;
                [self.splashViewController.view removeFromSuperview];
            }];
#ifdef DEBUG
        }
#endif
    }
}
@end
