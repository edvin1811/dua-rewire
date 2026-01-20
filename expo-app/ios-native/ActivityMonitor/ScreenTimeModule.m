#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(ScreenTimeModule, RCTEventEmitter)

// Authorization
RCT_EXTERN_METHOD(requestAuthorization:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(checkAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// App picker
RCT_EXTERN_METHOD(presentAppPicker)

// Focus sessions
RCT_EXTERN_METHOD(startFocusSession:(NSString *)name
                  durationMinutes:(int)durationMinutes
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(stopFocusSession:(NSString *)name)

RCT_EXTERN_METHOD(stopAllMonitoring)

// Usage data
RCT_EXTERN_METHOD(getUsageSummary:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
