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

+ (bool)invokeMethod:(NSString *)name
            instance:(id)instance
                call:(FlutterMethodCall *)call
              result:(FlutterResult)result
             onCatch:(void (^)(id))onCatch {
    SEL selector = @selector(name);
    if ([instance respondsToSelector:selector]) {
        @try {
            [instance performSelector:selector withObject:call withObject:result];
        } @catch (id e) {
            onCatch(e);
            return true;
        }
        return true;
    } else {
        return false;
    }
}
@end