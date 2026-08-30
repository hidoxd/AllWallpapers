#import <Foundation/Foundation.h>

@interface AWMCMLease : NSObject
@property(nonatomic, copy, readonly) NSString *rootPath;
+ (instancetype)leaseForClass:(uint64_t)containerClass identifier:(NSString *)identifier error:(NSString **)error;
- (BOOL)activate:(NSString **)error;
@end
