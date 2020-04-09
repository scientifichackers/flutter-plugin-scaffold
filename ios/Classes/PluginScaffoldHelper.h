//
// Created by Dev Aggarwal on 2019-05-17.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>


@interface PluginScaffoldHelper : NSObject
+ (void)tryCatch:(void (^)(void))fn
         onCatch:(void (^)(id))onCatch
          onElse:(void (^)(void))onElse;
@end
