//
//  ChannelInfoViewController.h
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


#import <UIKit/UIKit.h>
#import "ChannelsDataSource.h"
#import "LinkTextView.h"
#import "IRCColorPickerView.h"

@interface ChannelInfoViewController : UITableViewController<UITextViewDelegate,LinkTextViewDelegate,NSTextStorageDelegate,IRCColorPickerViewDelegate> {
    Channel *_channel;
    long _topiclen;
    UITextView *_topicEdit;
    NSAttributedString *_topic;
    LinkTextView *_topicLabel;
    LinkTextView *_url;
    NSMutableArray *_modeHints;
    NSString *_topicSetBy;
    BOOL _topicChanged;
    int offset;
    IRCColorPickerView *_colorPickerView;
    NSDictionary *_currentMessageAttributes;
}
-(id)initWithChannel:(Channel *)channel;
@end
