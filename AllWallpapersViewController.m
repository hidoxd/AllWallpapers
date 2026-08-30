#import "AllWallpapersViewController.h"
#import "MCMBridge.h"

static NSString *const AWProvider = @"com.apple.WallpaperKit.CollectionsPoster";

@interface AWItem : NSObject
@property(nonatomic, copy) NSString *uuid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) UIImage *thumbnail;
@end

@implementation AWItem
@end

@implementation AllWallpapersViewController {
    NSArray<AWItem *> *_items;
    AWMCMLease *_lease;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"All Wallpapers";

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(aw_close)];

    self.tableView.rowHeight = 74.0;
    self.tableView.tableFooterView = [UIView new];

    [self aw_load];
}

- (void)aw_close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PosterBoard access

- (NSString *)aw_findStoreRoot:(NSError **)outError {
    NSString *errorString = nil;

    AWMCMLease *lease =
        [AWMCMLease leaseForClass:2
                       identifier:@"com.apple.PosterBoard"
                            error:&errorString];

    if (!lease || ![lease activate:&errorString]) {
        if (outError) {
            *outError =
                [NSError errorWithDomain:@"AllWallpapers"
                                    code:1
                                userInfo:@{
                                    NSLocalizedDescriptionKey :
                                        errorString ?: @"Could not access PosterBoard"
                                }];
        }
        return nil;
    }

    NSString *base = lease.rootPath;
    if (base.length == 0) {
        if (outError) {
            *outError =
                [NSError errorWithDomain:@"AllWallpapers"
                                    code:2
                                userInfo:@{
                                    NSLocalizedDescriptionKey :
                                        @"PosterBoard container returned an empty path"
                                }];
        }
        return nil;
    }

    /*
     * Keep the lease alive for the lifetime of the view controller.
     * Releasing it immediately after obtaining rootPath can invalidate
     * the sandbox extension needed to read the descriptor store.
     */
    self->_lease = lease;

    NSFileManager *fm = [NSFileManager defaultManager];

    /*
     * iOS 18.x can use different internal store revisions.
     * Check the known revisions from newest to oldest.
     */
    NSArray<NSString *> *versions = @[
        @"61",
        @"60",
        @"62",
        @"59"
    ];

    for (NSString *version in versions) {
        NSString *path =
            [base stringByAppendingPathComponent:@"Library"];

        path =
            [path stringByAppendingPathComponent:@"Application Support"];

        path =
            [path stringByAppendingPathComponent:@"PRBPosterExtensionDataStore"];

        path =
            [path stringByAppendingPathComponent:version];

        path =
            [path stringByAppendingPathComponent:@"Extensions"];

        path =
            [path stringByAppendingPathComponent:AWProvider];

        path =
            [path stringByAppendingPathComponent:@"descriptors"];

        BOOL isDirectory = NO;

        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] &&
            isDirectory) {
            return path;
        }
    }

    if (outError) {
        *outError =
            [NSError errorWithDomain:@"AllWallpapers"
                                code:3
                            userInfo:@{
                                NSLocalizedDescriptionKey :
                                    @"CollectionsPoster descriptors folder not found"
                            }];
    }

    return nil;
}

#pragma mark - Descriptor metadata

- (NSString *)aw_nameFromDescriptor:(NSString *)descriptor {
    NSArray<NSString *> *candidateFiles = @[
        @"providerInfo.plist",
        @"com.apple.posterkit.provider.contents.userInfo"
    ];

    for (NSString *fileName in candidateFiles) {
        NSString *path =
            [descriptor stringByAppendingPathComponent:fileName];

        NSDictionary *dict =
            [NSDictionary dictionaryWithContentsOfFile:path];

        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        NSArray<NSString *> *candidateKeys = @[
            @"displayName",
            @"localizedName",
            @"name",
            @"title"
        ];

        for (NSString *key in candidateKeys) {
            id value = dict[key];

            if ([value isKindOfClass:[NSString class]] &&
                [(NSString *)value length] > 0) {
                return value;
            }
        }
    }

    NSString *uuid = descriptor.lastPathComponent;

    if (uuid.length > 0) {
        return uuid;
    }

    return @"Wallpaper";
}

#pragma mark - Thumbnail search

- (NSString *)aw_findImage:(NSString *)root {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSArray<NSString *> *names =
        [fm contentsOfDirectoryAtPath:root error:nil];

    if (names.count == 0) {
        return nil;
    }

    /*
     * Prefer common wallpaper image formats.
     */
    NSArray<NSString *> *preferredExtensions = @[
        @"jpg",
        @"jpeg",
        @"png",
        @"heic",
        @"webp"
    ];

    /*
     * First inspect the current directory.
     */
    for (NSString *name in names) {
        NSString *extension = name.pathExtension.lowercaseString;

        if ([preferredExtensions containsObject:extension]) {
            NSString *path =
                [root stringByAppendingPathComponent:name];

            BOOL directory = NO;

            if ([fm fileExistsAtPath:path isDirectory:&directory] &&
                !directory) {
                return path;
            }
        }
    }

    /*
     * Then recurse into child directories.
     */
    for (NSString *name in names) {
        NSString *path =
            [root stringByAppendingPathComponent:name];

        BOOL directory = NO;

        if (![fm fileExistsAtPath:path isDirectory:&directory] ||
            !directory) {
            continue;
        }

        NSString *found = [self aw_findImage:path];

        if (found.length > 0) {
            return found;
        }
    }

    return nil;
}

#pragma mark - Loading

- (void)aw_load {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            NSError *error = nil;

            NSString *root =
                [self aw_findStoreRoot:&error];

            if (root.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert =
                        [UIAlertController
                            alertControllerWithTitle:@"AllWallpapers"
                                              message:error.localizedDescription
                                       preferredStyle:UIAlertControllerStyleAlert];

                    [alert addAction:
                        [UIAlertAction
                            actionWithTitle:@"OK"
                                      style:UIAlertActionStyleDefault
                                    handler:nil]];

                    [self presentViewController:alert
                                       animated:YES
                                     completion:nil];
                });

                return;
            }

            NSFileManager *fm = [NSFileManager defaultManager];

            NSArray<NSString *> *names =
                [fm contentsOfDirectoryAtPath:root error:nil];

            NSMutableArray<AWItem *> *items =
                [NSMutableArray array];

            for (NSString *name in names) {
                @autoreleasepool {
                    if (name.length == 0 ||
                        [name hasPrefix:@"."]) {
                        continue;
                    }

                    NSString *path =
                        [root stringByAppendingPathComponent:name];

                    BOOL isDirectory = NO;

                    if (![fm fileExistsAtPath:path
                                   isDirectory:&isDirectory] ||
                        !isDirectory) {
                        continue;
                    }

                    AWItem *item = [AWItem new];

                    item.uuid = name;
                    item.path = path;
                    item.name =
                        [self aw_nameFromDescriptor:path];

                    NSString *imagePath =
                        [self aw_findImage:path];

                    if (imagePath.length > 0) {
                        item.thumbnail =
                            [UIImage imageWithContentsOfFile:imagePath];
                    }

                    [items addObject:item];
                }
            }

            [items sortUsingComparator:^NSComparisonResult(
                AWItem *a,
                AWItem *b
            ) {
                return [a.name
                    localizedCaseInsensitiveCompare:b.name];
            }];

            dispatch_async(dispatch_get_main_queue(), ^{
                self->_items = [items copy];

                [self.tableView reloadData];

                self.navigationItem.prompt =
                    [NSString stringWithFormat:@"%lu descriptors",
                        (unsigned long)self->_items.count];
            });
        }
    });
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)_items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *const CellIdentifier = @"AWCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:CellIdentifier];
    }

    AWItem *item = _items[indexPath.row];

    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.uuid;
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (item.thumbnail) {
        cell.imageView.image =
            [self aw_scaled:item.thumbnail
                       size:CGSizeMake(58.0, 58.0)];
    } else {
        cell.imageView.image = nil;
    }

    return cell;
}

#pragma mark - Image scaling

- (UIImage *)aw_scaled:(UIImage *)image
                  size:(CGSize)size {

    if (!image) {
        return nil;
    }

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:size];

    return [renderer imageWithActions:
        ^(UIGraphicsImageRendererContext *context) {
            [image drawInRect:CGRectMake(0.0,
                                         0.0,
                                         size.width,
                                         size.height)];
        }];
}

#pragma mark - Selection

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    AWItem *item = _items[indexPath.row];

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:item.name
                             message:
                                 @"Read-only build. This descriptor was found in the PosterBoard store."
                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"OK"
                      style:UIAlertActionStyleDefault
                    handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

@end
