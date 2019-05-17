#import "PluginScaffoldPlugin.h"
#import <plugin_scaffold/plugin_scaffold-Swift.h>

@implementation PluginScaffoldPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPluginScaffoldPlugin registerWithRegistrar:registrar];
}
@end
