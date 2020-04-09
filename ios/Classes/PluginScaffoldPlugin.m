#import "PluginScaffoldPlugin.h"
#if __has_include(<plugin_scaffold/plugin_scaffold-Swift.h>)
#import <plugin_scaffold/plugin_scaffold-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "plugin_scaffold-Swift.h"
#endif

@implementation PluginScaffoldPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPluginScaffoldPlugin registerWithRegistrar:registrar];
}
@end
