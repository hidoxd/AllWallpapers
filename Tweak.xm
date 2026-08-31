#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 1. Хук секций галереи PosterBoard (iOS 17 / 18)
%hook PBFPosterGallerySection

- (NSInteger)maximumNumberOfItems {
    NSLog(@"[AllWallpapers] PBFPosterGallerySection maximumNumberOfItems -> override 999");
    return 999;
}

- (NSInteger)maxNumberOfItems {
    NSLog(@"[AllWallpapers] PBFPosterGallerySection maxNumberOfItems -> override 999");
    return 999;
}

- (NSArray *)items {
    NSArray *orig = %orig;
    NSLog(@"[AllWallpapers] PBFPosterGallerySection items count: %lu", (unsigned long)orig.count);
    return orig;
}

- (NSArray *)descriptors {
    NSArray *orig = %orig;
    NSLog(@"[AllWallpapers] PBFPosterGallerySection descriptors count: %lu", (unsigned long)orig.count);
    return orig;
}

%end

// 2. Хук поставщика данных галереи
%hook PBFPosterGalleryDataProvider

- (NSArray *)sections {
    NSArray *sections = %orig;
    NSLog(@"[AllWallpapers] PBFPosterGalleryDataProvider fetched sections: %lu", (unsigned long)sections.count);
    return sections;
}

%end

// 3. Старый интерфейсный хук для совместимости
%hook PBRPosterGalleryCollection

- (NSInteger)maximumNumberOfItems {
    NSLog(@"[AllWallpapers] PBRPosterGalleryCollection maximumNumberOfItems -> override 999");
    return 999;
}

- (NSInteger)maxNumberOfItems {
    NSLog(@"[AllWallpapers] PBRPosterGalleryCollection maxNumberOfItems -> override 999");
    return 999;
}

%end
