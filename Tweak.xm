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
    NSArray *wallpapers = [self respondsToSelector:@selector(wallpapers)] ? [self wallpapers] : nil;
    return wallpapers ? wallpapers.count : %orig;
}

%end
