//
//  NetworkConnection.h
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


#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "WebSocket.h"
#import "SBJson5.h"
#import "ServersDataSource.h"
#import "BuffersDataSource.h"
#import "ChannelsDataSource.h"
#import "UsersDataSource.h"
#import "EventsDataSource.h"
#import "NotificationsDataSource.h"
#import "AvatarsDataSource.h"
#import "CSURITemplate.h"

extern NSString *IRCCLOUD_HOST;
extern NSString *IRCCLOUD_PATH;

extern NSString *kIRCCloudConnectivityNotification;
extern NSString *kIRCCloudEventNotification;
extern NSString *kIRCCloudBacklogStartedNotification;
extern NSString *kIRCCloudBacklogFailedNotification;
extern NSString *kIRCCloudBacklogCompletedNotification;
extern NSString *kIRCCloudBacklogProgressNotification;

extern NSString *kIRCCloudEventKey;

typedef enum {
    kIRCEventUserInfo,
    kIRCEventMakeServer,
    kIRCEventMakeBuffer,
    kIRCEventDeleteBuffer,
    kIRCEventBufferMsg,
    kIRCEventHeartbeatEcho,
    kIRCEventChannelInit,
    kIRCEventChannelTopic,
    kIRCEventJoin,
    kIRCEventPart,
    kIRCEventNickChange,
    kIRCEventQuit,
    kIRCEventMemberUpdates,
    kIRCEventUserChannelMode,
    kIRCEventBufferArchived,
    kIRCEventBufferUnarchived,
    kIRCEventRenameConversation,
    kIRCEventStatusChanged,
    kIRCEventConnectionDeleted,
    kIRCEventAway,
    kIRCEventSelfBack,
    kIRCEventKick,
    kIRCEventChannelMode,
    kIRCEventChannelTimestamp,
    kIRCEventSelfDetails,
    kIRCEventUserMode,
    kIRCEventSetIgnores,
    kIRCEventBadChannelKey,
    kIRCEventOpenBuffer,
    kIRCEventBanList,
    kIRCEventWhoList,
    kIRCEventWhois,
    kIRCEventNamesList,
    kIRCEventLinkChannel,
    kIRCEventListResponseFetching,
    kIRCEventListResponse,
    kIRCEventListResponseTooManyChannels,
    kIRCEventConnectionLag,
    kIRCEventGlobalMsg,
    kIRCEventAcceptList,
    kIRCEventReorderConnections,
    kIRCEventChannelTopicIs,
    kIRCEventServerMap,
    kIRCEventSessionDeleted,
    kIRCEventQuietList,
    kIRCEventBanExceptionList,
    kIRCEventInviteList,
    kIRCEventWhoSpecialResponse,
    kIRCEventModulesList,
    kIRCEventChannelQuery,
    kIRCEventLinksResponse,
    kIRCEventWhoWas,
    kIRCEventTraceResponse,
    kIRCEventLogExportFinished,
    kIRCEventAvatarChange,
    kIRCEventChanFilterList,
    kIRCEventAuthFailure,
    kIRCEventTextList,
    kIRCEventAlert,
    kIRCEventMessageChanged,
    kIRCEventUserTyping,
    kIRCEventRefresh
} kIRCEvent;

typedef enum {
    kIRCCloudStateDisconnected,
    kIRCCloudStateConnecting,
    kIRCCloudStateConnected
} kIRCCloudState;

typedef enum {
    kIRCCloudUnreachable,
    kIRCCloudReachable,
    kIRCCloudUnknown
} kIRCCloudReachability;

typedef void (^IRCCloudAPIResultHandler)(IRCCloudJSONObject *result);

@interface NetworkConnection : NSObject<WebSocketDelegate> {
    WebSocket *_socket;
    SBJson5Parser *_parser;
    SBJson5Writer *_writer;
    ServersDataSource *_servers;
    BuffersDataSource *_buffers;
    ChannelsDataSource *_channels;
    UsersDataSource *_users;
    EventsDataSource *_events;
    NotificationsDataSource *_notifications;
    AvatarsDataSource *_avatars;
    NSMutableArray *_oobQueue;
    NSMutableDictionary *_awayOverride;
    NSTimer *_idleTimer;
    NSTimeInterval _idleInterval;
    int _totalBuffers;
    int _numBuffers;
    int _lastReqId;
    int _currentCount;
    int _totalCount;
    int _currentBid;
    int _failCount;
    NSTimeInterval _OOBStartTime;
    NSTimeInterval _longestEventTime;
    NSString *_longestEventType;
    BOOL _resuming;
    BOOL _notifier;
    NSTimeInterval _firstEID;
    NSString *_streamId;
    int _accrued;
    BOOL _ready;
    BOOL _mock;
    kIRCCloudState _state;
    NSDictionary *_userInfo;
    NSDictionary *_prefs;
    NSDictionary *_config;
    NSTimeInterval _clockOffset;
    NSTimeInterval _reconnectTimestamp;
    NSOperationQueue *_queue;
    SCNetworkReachabilityRef _reachability;
    BOOL _reachabilityValid;
    NSDictionary *_parserMap;
    NSString *_globalMsg;
    NSString *_session;
    int _keychainFailCount;
    NSTimeInterval _highestEID;
    NSMutableDictionary *_resultHandlers;
    NSMutableArray *_pendingEdits;
    id _httpMetric;
    NSURLSession *_urlSession;
    NSTimer *_serializeTimer;
}
@property (readonly) NSDictionary *parserMap;
@property (readonly) kIRCCloudState state;
@property NSDictionary *userInfo;
@property (readonly) NSTimeInterval clockOffset;
@property NSTimeInterval idleInterval;
@property NSTimeInterval reconnectTimestamp;
@property NSTimeInterval highestEID;
@property BOOL notifier, reachabilityValid, mock;
@property (readonly) kIRCCloudReachability reachable;
@property NSString *globalMsg;
@property int failCount;
@property NSString *session;
@property NSDictionary *config;
@property (readonly) BOOL ready;
@property (readonly) NSOperationQueue *queue;
@property CSURITemplate *fileURITemplate, *pasteURITemplate, *avatarURITemplate, *avatarRedirectURITemplate;
@property SCNetworkReachabilityRef reachability;
@property (readonly) NSURLSession *urlSession;


+(NetworkConnection*)sharedInstance;
+(void)sync;
+(void)sync:(NSURL *)file1 with:(NSURL *)file2;
+(BOOL)shouldReconnect;
-(BOOL)isWifi;
-(void)serialize;
-(NSDictionary *)prefs;
-(void)connect:(BOOL)notifier;
-(void)disconnect;
-(void)clearPrefs;
-(void)scheduleIdleTimer;
-(void)cancelIdleTimer;
-(void)cancelPendingBacklogRequests;
-(void)requestBacklogForBuffer:(int)bid server:(int)cid completion:(void (^)(BOOL))completionHandler;
-(void)requestBacklogForBuffer:(int)bid server:(int)cid beforeId:(NSTimeInterval)eid completion:(void (^)(BOOL))completionHandler;
-(id)fetchOOB:(NSString *)url;
-(void)logout;
-(void)fail;
-(void)requestArchives:(int)cid;
-(void)setLastSelectedBID:(int)bid;
-(void)parse:(NSDictionary *)object backlog:(BOOL)backlog;
-(void)sendFeedbackReport:(UIViewController *)delegate;
-(void)updateAPIHost:(NSString *)host;

//WebSocket
-(int)say:(NSString *)message to:(NSString *)to cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)reply:(NSString *)message to:(NSString *)to cid:(int)cid msgid:(NSString *)msgid handler:(IRCCloudAPIResultHandler)handler;
-(int)heartbeat:(int)selectedBuffer cid:(int)cid bid:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid handler:(IRCCloudAPIResultHandler)handler;
-(int)heartbeat:(int)selectedBuffer cids:(NSArray *)cids bids:(NSArray *)bids lastSeenEids:(NSArray *)lastSeenEids handler:(IRCCloudAPIResultHandler)handler;
-(int)join:(NSString *)channel key:(NSString *)key cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)part:(NSString *)channel msg:(NSString *)msg cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)kick:(NSString *)nick chan:(NSString *)chan msg:(NSString *)msg cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)mode:(NSString *)mode chan:(NSString *)chan cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)invite:(NSString *)nick chan:(NSString *)chan cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)archiveBuffer:(int)bid cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)unarchiveBuffer:(int)bid cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)deleteBuffer:(int)bid cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)deleteServer:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)addServer:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands channels:(NSString *)channels handler:(IRCCloudAPIResultHandler)handler;
-(int)editServer:(int)cid hostname:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands handler:(IRCCloudAPIResultHandler)handler;
-(int)ignore:(NSString *)mask cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)unignore:(NSString *)mask cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)setPrefs:(NSString *)prefs handler:(IRCCloudAPIResultHandler)handler;
-(int)setRealname:(NSString *)realname highlights:(NSString *)highlights autoaway:(BOOL)autoaway handler:(IRCCloudAPIResultHandler)handler;
-(int)ns_help_register:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)setNickservPass:(NSString *)nspass cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)whois:(NSString *)nick server:(NSString *)server cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)topic:(NSString *)topic chan:(NSString *)chan cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)back:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)disconnect:(int)cid msg:(NSString *)msg handler:(IRCCloudAPIResultHandler)handler;
-(int)reconnect:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(int)reorderConnections:(NSString *)cids handler:(IRCCloudAPIResultHandler)handler;
-(int)resendVerifyEmailWithHandler:(IRCCloudAPIResultHandler)handler;
-(int)changeEmail:(NSString *)email password:(NSString *)password handler:(IRCCloudAPIResultHandler)handler;
-(int)deleteFile:(NSString *)fileID handler:(IRCCloudAPIResultHandler)handler;
-(int)paste:(NSString *)name contents:(NSString *)contents extension:(NSString *)extension handler:(IRCCloudAPIResultHandler)handler;
-(int)deletePaste:(NSString *)pasteID handler:(IRCCloudAPIResultHandler)handler;
-(int)editPaste:(NSString *)pasteID name:(NSString *)name contents:(NSString *)contents extension:(NSString *)extension handler:(IRCCloudAPIResultHandler)handler;
-(int)changePassword:(NSString *)password newPassword:(NSString *)newPassword handler:(IRCCloudAPIResultHandler)handler;
-(int)deleteAccount:(NSString *)password handler:(IRCCloudAPIResultHandler)handler;
-(int)exportLog:(NSString *)timezone cid:(int)cid bid:(int)bid handler:(IRCCloudAPIResultHandler)handler;
-(int)renameChannel:(NSString *)name cid:(int)cid bid:(int)bid handler:(IRCCloudAPIResultHandler)handler;
-(int)renameConversation:(NSString *)name cid:(int)cid bid:(int)bid handler:(IRCCloudAPIResultHandler)handler;
-(int)setAvatar:(NSString *)avatarId orgId:(int)orgId handler:(IRCCloudAPIResultHandler)resultHandler;
-(int)setAvatar:(NSString *)avatarId cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler;
-(int)setNetworkName:(NSString *)name cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler;
-(int)deleteMessage:(NSString *)msgId cid:(int)cid to:(NSString *)to handler:(IRCCloudAPIResultHandler)handler;
-(int)editMessage:(NSString *)msgId cid:(int)cid to:(NSString *)to msg:(NSString *)msg handler:(IRCCloudAPIResultHandler)handler;
-(int)typing:(NSString *)value cid:(int)cid to:(NSString *)to handler:(IRCCloudAPIResultHandler)handler;
-(int)redact:(NSString *)msgId cid:(int)cid to:(NSString *)to reason:(NSString *)reason handler:(IRCCloudAPIResultHandler)handler;

//GET
-(void)requestConfigurationWithHandler:(IRCCloudAPIResultHandler)handler;
-(void)getFiles:(int)page handler:(IRCCloudAPIResultHandler)handler;
-(void)getPastebins:(int)page handler:(IRCCloudAPIResultHandler)handler;
-(void)propertiesForFile:(NSString *)fileID handler:(IRCCloudAPIResultHandler)handler;
-(void)getLogExportsWithHandler:(IRCCloudAPIResultHandler)handler;

//POST
-(void)requestAuthTokenWithHandler:(IRCCloudAPIResultHandler)handler;
-(void)login:(NSString *)email password:(NSString *)password token:(NSString *)token handler:(IRCCloudAPIResultHandler)handler;
-(void)login:(NSURL *)accessLink handler:(IRCCloudAPIResultHandler)handler;
-(void)signup:(NSString *)email password:(NSString *)password realname:(NSString *)realname token:(NSString *)token handler:(IRCCloudAPIResultHandler)handler;
-(void)POSTsay:(NSString *)message to:(NSString *)to cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
-(void)POSTreply:(NSString *)message to:(NSString *)to cid:(int)cid msgid:(NSString *)msgid handler:(IRCCloudAPIResultHandler)handler;
-(void)POSTheartbeat:(int)selectedBuffer cid:(int)cid bid:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid handler:(IRCCloudAPIResultHandler)handler;
-(void)POSTheartbeat:(int)selectedBuffer cids:(NSArray *)cids bids:(NSArray *)bids lastSeenEids:(NSArray *)lastSeenEids handler:(IRCCloudAPIResultHandler)handler;
-(void)registerAPNs:(NSData *)token fcm:(NSString *)fcm handler:(IRCCloudAPIResultHandler)handler;
-(void)unregisterAPNs:(NSData *)token fcm:(NSString *)fcm session:(NSString *)session handler:(IRCCloudAPIResultHandler)handler;
-(void)requestAccessLink:(NSString *)email token:(NSString *)token handler:(IRCCloudAPIResultHandler)handler;
-(void)requestPasswordReset:(NSString *)email token:(NSString *)token handler:(IRCCloudAPIResultHandler)handler;
-(void)finalizeUpload:(NSString *)uploadID filename:(NSString *)filename originalFilename:(NSString *)originalFilename avatar:(BOOL)avatar orgId:(int)orgId cid:(int)cid handler:(IRCCloudAPIResultHandler)handler;
@end
