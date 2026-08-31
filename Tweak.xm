#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%hook PBRPosterGalleryCollection

- (NSArray *)descriptors {
    return %orig;
}

- (NSArray *)items {
    return %orig;
}

%end

%hook WKWallpaperCollection

- (NSUInteger)numberOfItems {
    id selfObj = (id)self;
    SEL wallpapersSelector = NSSelectorFromString(@"wallpapers");
    
    if ([selfObj respondsToSelector:wallpapersSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSArray *wallpapers = [selfObj performSelector:wallpapersSelector];
#pragma clang diagnostic pop
        if (wallpapers && [wallpapers isKindOfClass:[NSArray class]]) {
            return wallpapers.count;
        }
    }
    return %orig;
}

%end
