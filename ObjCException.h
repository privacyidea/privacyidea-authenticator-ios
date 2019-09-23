//
//  CatchException.h
//  privacyIDEA Authenticator
//
//  Created by Nils Behlen on 23.09.19.
//  Copyright © 2019 Nils Behlen. All rights reserved.
//

#ifndef CatchException_h
#define CatchException_h

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>

@interface ObjCException : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end


#endif /* CatchException_h */
