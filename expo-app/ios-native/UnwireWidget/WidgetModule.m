#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(WidgetModule, NSObject)

RCT_EXTERN_METHOD(updateWidgetData:(NSDictionary *)data)

RCT_EXTERN_METHOD(reloadAllTimelines)

RCT_EXTERN_METHOD(reloadTimeline:(NSString *)kind)

@end
