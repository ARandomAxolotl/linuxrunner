#import <UIKit/UIKit.h>
#import "../TerminalViewController.h"

NS_ASSUME_NONNULL_BEGIN
void LRSetDatalessMaterialization(void);
@interface LRRuntimeBridge : NSObject
+ (UIViewController *)guiController;
+ (UIViewController *)desktopController;
+ (UIViewController * _Nullable)desktopControllerIfCreated;
+ (NSDictionary<NSString *, id> *)desktopSessionSummary;
+ (void)stopDesktopSession;
/// Requested graphics mode, the guest's GPU_ROUTING decision and per-process GPU statistics of the latest GUI session.
+ (NSDictionary<NSString *, id> *)graphicsSummary;
+ (UIViewController *)desktopControllerWithConfiguration:(NSDictionary *)configuration;
+ (UIViewController *)guiControllerWithConfiguration:(NSDictionary *)configuration;
+ (BOOL)autoStart;
+ (BOOL)canStartRuntime;
+ (int)startRuntime;
+ (BOOL)beginBoot;
+ (UIViewController *)diagnosticsController;
+ (NSDictionary<NSString *, NSString *> *)deviceDiagnostics;
+ (NSURL *)catalogURL;
+ (NSURL *)managedStorageURL;
+ (NSDictionary *)healthSummary;
+ (NSArray<NSDictionary *> *)diagnosticEntries;
+ (void)configureDiagnostics:(int)level process:(int)pid syscall:(int)number errorsOnly:(BOOL)errorsOnly;
+ (NSURL * _Nullable)exportFullDiagnosticBundle:(NSError **)error;
+ (NSString *)redactDiagnosticText:(NSString *)text application:(BOOL)application;
+ (NSArray<NSString *> *)rootNames;
+ (NSString *)activeRootName;
+ (NSString *)nextRootName;
+ (void)setNextRootName:(NSString *)name;
+ (NSURL *)rootURL:(NSString *)name;
+ (NSURL *)exchangeURL:(NSString *)name;
+ (BOOL)isRunning;
+ (NSString *)runtimeStatus;
+ (void)recordBoot:(NSString *)root error:(int)error;
+ (int)prepareExchange:(NSString *)root;
+ (BOOL)assembleDebianPackages:(NSArray<NSString *> *)packages toArchive:(NSURL *)archive progress:(void (^)(double))progress cancel:(BOOL (^)(void))cancel error:(NSError **)error;
+ (BOOL)importVerifiedEnvironment:(NSURL *)archive root:(NSString *)root sha256:(NSString *)sha256 progress:(void (^)(double, NSString *))progress cancel:(BOOL (^)(void))cancel error:(NSError **)error;
// Arch Linux ARM installer: repository database text (see lr_arch_read_database),
// assembly of authenticated packages, and import with explicit metadata.
+ (nullable NSString *)readArchDatabase:(NSURL *)database error:(NSError **)error;
+ (BOOL)assembleArchPackages:(NSArray<NSString *> *)packages localNames:(NSArray<NSString *> *)names localDescriptions:(NSArray<NSString *> *)descriptions toArchive:(NSURL *)archive progress:(void (^)(double))progress cancel:(BOOL (^)(void))cancel error:(NSError **)error;
+ (BOOL)importVerifiedEnvironment:(NSURL *)archive root:(NSString *)root sha256:(NSString *)sha256 metadata:(NSDictionary<NSString *, NSString *> *)metadata progress:(void (^)(double, NSString *))progress cancel:(BOOL (^)(void))cancel error:(NSError **)error;
+ (BOOL)activeEnvironmentIsArch;
+ (BOOL)activeEnvironmentIsDebian;
+ (NSDictionary *)probeJITPermissions;
+ (void)createEnvironment:(NSString *)root completion:(void (^)(NSError * _Nullable))completion;
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)discoverApplications;
+ (NSArray<NSDictionary *> *)discoverGraphicalApplications;
+ (NSURL * _Nullable)prepareApplicationSupport:(NSError **)error;
+ (void)resetGraphicalSessions;
+ (TerminalViewController *)terminalForCommand:(NSArray<NSString *> *)command directory:(NSString *)directory;
// Real guest account database and distro-managed password prompts. No passwords
// cross this bridge or enter native preferences/logs.
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)linuxAccounts;
// Create a desktop request through guest DAC and metadata, not host-only IO.
+ (BOOL)publishDesktopRequest:(NSString *)path user:(NSString *)user error:(NSError **)error;
+ (BOOL)writeDesktopRequest:(NSData *)data guestPath:(NSString *)path user:(NSString *)user error:(NSError **)error;
+ (NSString *)defaultLinuxUser;
// Shared iPhone folders (Files › document picker), bind-mounted at /mnt/<name>.
// Host files there without guest metadata belong to the default Linux user.
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)sharedFolders;
+ (BOOL)addSharedFolder:(NSURL *)url error:(NSError **)error;
+ (void)removeSharedFolder:(NSString *)name;
+ (void)applySharedFolderOwnership;
+ (void)checkSharedFolder:(NSString *)name completion:(void (^)(NSString *summary))completion;
+ (BOOL)setDefaultLinuxUser:(NSString *)name error:(NSError **)error;
+ (NSArray<NSString *> * _Nullable)defaultLinuxLoginCommand:(NSError **)error;
+ (TerminalViewController * _Nullable)createLinuxUser:(NSString *)name error:(NSError **)error;
+ (TerminalViewController * _Nullable)createLinuxUser:(NSString *)name administrator:(BOOL)administrator error:(NSError **)error;
+ (BOOL)canGrantAdministrator;
// Native account setup (no terminal): installs missing account tools/sudo,
// creates the user, sets the password from an app-side SHA-512 crypt hash and
// verifies it in /etc/shadow. Completion and progress run on the main thread.
+ (void)createLinuxUser:(NSString *)name password:(NSString *)password administrator:(BOOL)administrator
               progress:(void (^)(NSString *message))progress completion:(void (^)(NSError * _Nullable error))completion;
+ (BOOL)accountToolsPresent;
+ (void)setLinuxPassword:(NSString *)name password:(NSString *)password progress:(void (^)(NSString *message))progress completion:(void (^)(NSError * _Nullable error))completion;
+ (void)prepareDesktopProfile:(void (^)(NSString *stage))progress completion:(void (^)(NSError * _Nullable error))completion;
/// Experimental KDE Plasma (X11) from Debian's packages, on top of the regular desktop.
+ (void)installPlasma:(void (^)(NSString *stage))progress completion:(void (^)(NSError * _Nullable error))completion;
+ (BOOL)plasmaInstalled;
/// True while a support installation (account tools, desktop, KDE) runs; a
/// second one is refused until it finishes.
+ (BOOL)installationRunning;
// Keep Screen Awake During Operations (setting LinuxRunner.keepScreenAwake,
// default on): reasons are reference-counted; while any is active the idle
// timer is off. The only writer of UIApplication.idleTimerDisabled (the older
// "disable dimming" preference is honoured here too). Main thread or any queue.
+ (void)beginAwake:(NSString *)reason;
+ (void)endAwake:(NSString *)reason;
+ (void)refreshAwake;
+ (NSArray<NSString *> *)awakeReasons;
+ (TerminalViewController * _Nullable)changeLinuxPassword:(NSString *)name error:(NSError **)error;
+ (TerminalViewController * _Nullable)removeLinuxUserKeepingHome:(NSString *)name error:(NSError **)error;
+ (TerminalViewController * _Nullable)terminalForLinuxUser:(NSString *)name error:(NSError **)error;
// Open Desktop attempt timeline (one correlation id per request) and the
// exportable report: timeline, last successful / first failed stage, guest
// process and display state, viewer and renderer state. No secrets.
+ (NSString *)desktopTraceBegin:(NSString *)source;
+ (NSString *)desktopTraceAttempt;
+ (void)desktopTrace:(NSString *)stage result:(NSString *)result detail:(NSString * _Nullable)detail;
+ (NSArray<NSString *> *)desktopTraceRecords;
+ (NSString *)desktopTraceSavedText;
+ (void)exportDesktopReport:(void (^)(NSURL * _Nullable url))completion;
+ (NSDictionary *)inputDiagnostics;
+ (void)logCategory:(NSString *)category event:(NSString *)event;
+ (NSArray<NSString *> *)logLines;
+ (NSURL * _Nullable)exportLogs:(NSError **)error;
+ (BOOL)importFile:(NSURL *)source root:(NSString *)root error:(NSError **)error;
+ (NSURL * _Nullable)exportFile:(NSString *)leaf root:(NSString *)root error:(NSError **)error;
+ (void)deleteExport:(NSURL *)url;
@end

/// Posted on the main queue during a support installation. userInfo: title,
/// stage, detail (NSString), fraction (NSNumber 0…1, or -1 when not measurable),
/// elapsed (NSNumber seconds), phase ("running" | "succeeded" | "failed"),
/// error and log (NSString, failure only).
extern NSNotificationName const LRInstallProgressNotification;
NS_ASSUME_NONNULL_END
