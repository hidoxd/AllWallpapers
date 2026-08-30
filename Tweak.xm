#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <Preferences/PSListController.h>
#import "AllWallpapersViewController.h"

static BOOL AWLooksLikeWallpaperController(id self) {
    if (![self isKindOfClass:UIViewController.class]) return NO;
    NSString *title = nil;
    if ([self respondsToSelector:@selector(title)]) {
        title = ((id (*)(id, SEL))objc_msgSend)(self, @selector(title));
    }
    if (!title.length) return NO;
    NSString *s = title.lowercaseString;
    return [s containsString:@"wallpaper"] || [s containsString:@"обо"];
}

%hook PSListController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!AWLooksLikeWallpaperController(self)) return;

    UINavigationItem *item = self.navigationItem;
    if (!item) return;
    if (item.rightBarButtonItem) {
        if ([item.rightBarButtonItem.title isEqualToString:@"All"]) return;
    }

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"All"
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(aw_openAllWallpapers)];
    item.rightBarButtonItem = button;
}

%new
- (void)aw_openAllWallpapers {
    AllWallpapersViewController *vc = [AllWallpapersViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    if (self.navigationController) {
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    } else {
        [self presentViewController:nav animated:YES completion:nil];
    }
}

%end

%ctor {
    NSLog(@"[AllWallpapers] loaded");
}
