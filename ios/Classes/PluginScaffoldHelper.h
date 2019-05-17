//
// Created by Dev Aggarwal on 2019-05-17.
//

#import <Foundation/Foundation.h>

@class FlutterMethodCall;


@interface PluginScaffoldHelper : NSObject
+ (void)tryCatch:(void (^)(void))fn
         onCatch:(void (^)(id))onCatch
          onElse:(void (^)(void))onElse;

+ (bool)invokeMethod:(NSString *)name
            instance:(id)instance
                call:(FlutterMethodCall *)call
              result:(FlutterResult)result
             onCatch:(void (^)(id))onCatch;
@end
