//
//  SubLoad.m
//  load和initialize区别
//
//  Created by haogaoming on 2018/3/19.
//  Copyright © 2018年 郝高明. All rights reserved.
//

#import "SubLoad.h"

@implementation SubLoad

+(void)load {
    NSLog(@"我是 SubLoad，我被触发了");
}

+(void)initialize {
    NSLog(@"我是 SubInitialize，我被触发了");
}

@end

