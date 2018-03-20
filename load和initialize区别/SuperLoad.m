//
//  SuperLoad.m
//  load和initialize区别
//
//  Created by haogaoming on 2018/3/19.
//  Copyright © 2018年 郝高明. All rights reserved.
//

#import "SuperLoad.h"

@implementation SuperLoad

+(void)load {
    NSLog(@"我是 superLoad，我被触发了");
}

+(void)initialize {
    NSLog(@"我是 superInitialize，我被触发了");
}

@end

@implementation SuperLoad(Category)
+(void)load {
    NSLog(@"我是 Category，我被调用了");
}
/// 添加一个方法
-(void)addMethod {
    NSLog(@"我被添加到方法里边了");
}
@end
