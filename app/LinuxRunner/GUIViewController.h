#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface LRGUIViewController : UIViewController
- (instancetype)initDesktop;
- (NSDictionary *)desktopSessionSummary;
- (void)stopDesktopSession;
- (void)launchDesktopApplication:(NSDictionary *)configuration;
+ (NSURL * _Nullable)prepareSupport:(NSError **)error;
- (instancetype)initWithLaunchConfiguration:(NSDictionary *)configuration;
/// Graphics routing and per-process GPU statistics of the most recently started session.
+ (NSDictionary<NSString *, id> *)latestGraphicsSummary;
/// Compact Open Desktop diagnostic report (timeline, stages, guest/viewer/renderer state). No secrets.
+ (void)buildDesktopReport:(void (^)(NSString *text))completion;
/// Pointer sources seen (UIKit touches by type, hover, scroll, GCMouse), pointer mode and event-to-send latency.
+ (NSDictionary *)latestInputDiagnostics;
@end
/// Session graphics default (Settings): mesa, mesa-metal-resident, or mesa-metal-verify.
extern NSString *const LRGraphicsModeDefaultsKey;
NS_ASSUME_NONNULL_END
