#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 1. Снимаем лимит количества элементов в секциях PosterBoard (iOS 16/17/18)
%hook PBFPosterGalleryCollection

- (NSInteger)maximumNumberOfItems {
    return 999;
}

- (NSInteger)maxNumberOfItems {
    return 999;
}

%end

// 2. Резервный хук для PBR-классов коллекции
%hook PBRPosterGalleryCollection

- (NSInteger)maximumNumberOfItems {
    return 999;
}

- (NSInteger)maxNumberOfItems {
    return 999;
}

%end
