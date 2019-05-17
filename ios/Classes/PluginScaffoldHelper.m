//
// Created by Dev Aggarwal on 2019-05-17.
//

#import <Flutter/Flutter.h>
#import "PluginScaffoldHelper.h"

@implementation PluginScaffoldHelper
+ (void)tryCatch:(void (^)(void))fn
         onCatch:(void (^)(id))onCatch
          onElse:(void (^)(void))onElse {
    @try {
        fn();
    } @catch (id e) {
        onCatch(e);
        return;
    }
    onElse();
}

+ (bool)invokeMethod:(id)instance
                call:(FlutterMethodCall *)call
                 res:(FlutterResult)res
             onCatch:(void (^)(id))onCatch {
    for (NSString *suffix in @[@"WithCall:result:", @"WithCall:error:result:"]) {
        NSString *name = [call.method stringByAppendingString:suffix];
        SEL selector = NSSelectorFromString(name);
        if ([instance respondsToSelector:selector]) {
            NSLog(@">>>> %@", name);
            @try {
                [instance performSelector:selector withObject:call withObject:res];
            } @catch (id e) {
                onCatch(e);
            }
            return true;
        }
    }

    return false;
}
@end
