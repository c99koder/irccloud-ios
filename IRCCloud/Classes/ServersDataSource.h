//
//  ServersDataSource.h
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
#import "Ignore.h"

@interface Server : NSObject<NSSecureCoding> {
    int _cid;
    NSString *_name;
    NSString *_hostname;
    NSString *_ircserver;
    int _port;
    NSString *_nick;
    NSString *_from;
    NSString *_status;
    int _ssl;
    NSString *_realname;
    NSString *_server_pass;
    NSString *_server_realname;
    NSString *_nickserv_pass;
    NSString *_join_commands;
    NSDictionary *_fail_info;
    NSString *_away;
    NSString *_usermask;
    NSString *_mode;
    NSMutableDictionary *_isupport;
    NSArray *_ignores;
    NSString *_CHANTYPES;
    NSDictionary *_PREFIX;
    int _order;
    NSString *_MODE_OPER, *_MODE_OWNER, *_MODE_ADMIN, *_MODE_OP, *_MODE_HALFOP, *_MODE_VOICED;
    int _deferred_archives;
    Ignore *_ignore;
    int _orgId;
    NSString *_avatar;
    NSString *_avatarURL;
    int _avatars_supported;
    int _slack;
    NSArray *_caps;
    NSString *_account;
    NSMutableDictionary *_collapsed;
    BOOL _blocksEdits;
    BOOL _blocksReplies;
    BOOL _blocksReactions;
    BOOL _blocksDeletes;
    BOOL _blocksTyping;
}
@property (assign) int cid, port, ssl, order, deferred_archives, orgId, avatars_supported, slack;
@property (copy) NSString *name, *hostname, *nick, *status, *realname, *server_pass, *nickserv_pass, *join_commands, *away, *usermask, *mode, *CHANTYPES, *MODE_OPER, *MODE_OWNER, *MODE_ADMIN, *MODE_OP, *MODE_HALFOP, *MODE_VOICED, *server_realname, *ircserver, *avatar, *avatarURL, *from, *account;
@property (copy) NSDictionary *fail_info, *PREFIX;
@property (copy) NSDictionary *isupport;
@property (copy) NSArray *caps;
@property (strong) NSMutableDictionary *collapsed;
@property (readonly) Ignore *ignore;
@property (assign) BOOL blocksEdits, blocksReplies, blocksReactions, blocksDeletes, blocksTyping;
-(NSComparisonResult)compare:(Server *)aServer;
-(NSArray *)ignores;
-(void)setIgnores:(NSArray *)ignores;
-(BOOL)isSlack;
-(NSString *)slackBaseURL;
-(BOOL)clientTagDeny:(NSString *)tagName;
-(BOOL)hasMessageTags;
-(BOOL)hasLabels;
@end

@interface ServersDataSource : NSObject {
    NSMutableArray *_servers;
}
+(ServersDataSource *)sharedInstance;
-(void)serialize;
-(void)clear;
-(void)addServer:(Server *)server;
-(NSArray *)getServers;
-(Server *)getServer:(int)cid;
-(Server *)getServer:(NSString *)hostname port:(int)port;
-(Server *)getServer:(NSString *)hostname SSL:(BOOL)ssl;
-(void)removeServer:(int)cid;
-(void)removeAllDataForServer:(int)cid;
-(NSUInteger)count;
-(void)updateNick:(NSString *)nick server:(int)cid;
-(void)updateStatus:(NSString *)status failInfo:(NSDictionary *)failInfo server:(int)cid;
-(void)updateAway:(NSString *)away server:(int)cid;
-(void)updateUsermask:(NSString *)usermask server:(int)cid;
-(void)updateMode:(NSString *)mode server:(int)cid;
-(void)updateIsupport:(NSDictionary *)isupport server:(int)cid;
-(void)updateIgnores:(NSArray *)ignores server:(int)cid;
-(void)updateUserModes:(NSString *)modes server:(int)cid;
@end
