#import "FluetoothPlugin.h"
#if __has_include(<fluetooth_plus/fluetooth_plus-Swift.h>)
#import <fluetooth_plus/fluetooth_plus-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fluetooth_plus-Swift.h"
#endif

@implementation FluetoothPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFluetoothPlugin registerWithRegistrar:registrar];
}
@end
