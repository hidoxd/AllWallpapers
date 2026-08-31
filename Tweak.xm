#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Функция записи логов прямо в файл на устройстве
static void appendLog(NSString *msg) {
    NSString *path = @"/var/mobile/allwallpapers.log";
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], msg];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (handle) {
        [handle seekToEndOfFile];
        [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [handle closeFile];
    } else {
        [line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

%hook PBFPosterGallerySection

- (NSInteger)maximumNumberOfItems {
    appendLog(@"PBFPosterGallerySection maximumNumberOfItems -> override 999");
    return 999;
}

- (NSInteger)maxNumberOfItems {
    appendLog(@"PBFPosterGallerySection maxNumberOfItems -> override 999");
    return 999;
}

- (NSArray *)items {
    NSArray *orig = %orig;
    appendLog([NSString stringWithFormat:@"PBFPosterGallerySection items count: %lu", (unsigned long)orig.count]);
    return orig;
}

- (NSArray *)descriptors {
    NSArray *orig = %orig;
    appendLog([NSString stringWithFormat:@"PBFPosterGallerySection descriptors count: %lu", (unsigned long)orig.count]);
    return orig;
}

%end

%hook PBFPosterGalleryDataProvider

- (NSArray *)sections {
    NSArray *sections = %orig;
    appendLog([NSString stringWithFormat:@"PBFPosterGalleryDataProvider fetched sections: %lu", (unsigned long)sections.count]);
    return sections;
}

%end

%hook PBRPosterGalleryCollection

- (NSInteger)maximumNumberOfItems {
    appendLog(@"PBRPosterGalleryCollection maximumNumberOfItems -> override 999");
    return 999;
}

- (NSInteger)maxNumberOfItems {
    appendLog(@"PBRPosterGalleryCollection maxNumberOfItems -> override 999");
    return 999;
}

%end
