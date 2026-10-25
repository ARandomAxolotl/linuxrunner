#import <Foundation/Foundation.h>
#import "RFBProtocol.h"
NS_ASSUME_NONNULL_BEGIN
// Private, authenticated loopback display only. Does not access guest memory.
@interface LRRFBClient : NSObject
@property (copy,nullable) void (^frameHandler)(NSData *bgra,uint16_t width,uint16_t height,uint64_t frameCount,uint64_t receivedBytes);
// Optional damage-aware delivery. Legacy probes/software clients remain valid.
@property (copy,nullable) void (^damageFrameHandler)(NSData *bgra,uint16_t width,uint16_t height,uint64_t frameCount,uint64_t receivedBytes,LRFrameDamage damage);
// Compact dirty pixels, rows tightly packed at damage.width*4 bytes.
@property (copy,nullable) void (^patchFrameHandler)(NSData *patch,uint16_t width,uint16_t height,uint64_t frameCount,uint64_t receivedBytes,LRFrameDamage damage);
@property (copy,nullable) void (^statusHandler)(NSString *status);
@property (copy,nullable) void (^inputTraceHandler)(NSString *event);
// Opt-in stage timing, called on decoder/input queues. No keysyms or pixels.
// decode_delivery_ms includes receiving the update body and callback delivery;
// input_queue_ms/write_ms stop at socket write, not guest response/display.
@property (copy,nullable) void (^transportMetricsHandler)(NSDictionary *event);
- (instancetype)initWithPort:(uint16_t)port password:(NSString *)password;
- (void)start;
- (void)stop;
- (void)key:(uint32_t)keysym down:(BOOL)down;
- (void)typeKeysyms:(const uint32_t *)symbols count:(size_t)count;
- (void)pointerX:(uint16_t)x y:(uint16_t)y buttons:(uint8_t)buttons;
@end
NS_ASSUME_NONNULL_END
