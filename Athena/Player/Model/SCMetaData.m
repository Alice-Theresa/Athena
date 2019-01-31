//
//  SCMetaData.m
//  Athena
//
//  Created by Theresa on 2019/01/31.
//  Copyright © 2019 Theresa. All rights reserved.
//

#import "SCMetaData.h"


@implementation SCMetaData

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary {
    return [[self alloc] initWithAVDictionary:avDictionary];
}

- (instancetype)initWithAVDictionary:(AVDictionary *)avDictionary {
    if (self = [super init]) {
        NSDictionary * dic = SGFFFoundationBrigeOfAVDictionary(avDictionary);
        
        self.metadata = dic;
        
        self.language = [dic objectForKey:@"language"];
        self.BPS = [[dic objectForKey:@"BPS"] longLongValue];
        self.duration = [dic objectForKey:@"DURATION"];
        self.number_of_bytes = [[dic objectForKey:@"NUMBER_OF_BYTES"] longLongValue];
        self.number_of_frames = [[dic objectForKey:@"NUMBER_OF_FRAMES"] longLongValue];
    }
    return self;
}

NSDictionary *SGFFFoundationBrigeOfAVDictionary(AVDictionary * avDictionary) {
    if (avDictionary == NULL) return nil;
    
    int count = av_dict_count(avDictionary);
    if (count <= 0) return nil;
    
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(avDictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        @autoreleasepool {
            NSString * key = [NSString stringWithUTF8String:entry->key];
            NSString * value = [NSString stringWithUTF8String:entry->value];
            [dictionary setObject:value forKey:key];
        }
    }
    
    return dictionary;
}

@end
