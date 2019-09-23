//
//  ObjCException.m
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 23.09.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ObjCException.h"

@implementation ObjCException

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
