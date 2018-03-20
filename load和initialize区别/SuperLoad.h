//
//  SuperLoad.h
//  load和initialize区别
//
//  Created by haogaoming on 2018/3/19.
//  Copyright © 2018年 郝高明. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SuperLoad : NSObject

@end

@interface SuperLoad (Category)

/// 添加一个方法
-(void)addMethod;

@end
