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
    if ([selfObj respondsToSelector:@selector(wallpapers)]) {
        NSArray *wallpapers = [selfObj wallpapers];
        if (wallpapers) {
            return wallpapers.count;
        }
    }
    return %orig;
}

%end
