//
// Created by Dev Aggarwal on 2019-05-17.
//

#import <Flutter/Flutter.h>
#import <PluginScaffoldHelper.h>

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
@end
