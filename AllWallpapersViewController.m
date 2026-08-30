#import "AllWallpapersViewController.h"
#import "MCMBridge.h"

static NSString *const AWProvider = @"com.apple.WallpaperKit.CollectionsPoster";

@interface AWItem : NSObject
@property(nonatomic, copy) NSString *uuid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) UIImage *thumbnail;
@end
@implementation AWItem @end

@implementation AllWallpapersViewController {
    NSArray<AWItem *> *_items;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"All Wallpapers";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(aw_close)];
    self.tableView.rowHeight = 74.0;
    self.tableView.tableFooterView = [UIView new];
    [self aw_load];
}

- (void)aw_close { [self dismissViewControllerAnimated:YES completion:nil]; }

- (NSString *)aw_findStoreRoot:(NSError **)outError {
    NSString *err = nil;
    AWMCMLease *lease = [AWMCMLease leaseForClass:2 identifier:@"com.apple.PosterBoard" error:&err];
    if (!lease || ![lease activate:&err]) {
        if (outError) *outError = [NSError errorWithDomain:@"AllWallpapers" code:1 userInfo:@{NSLocalizedDescriptionKey: err ?: @"Could not access PosterBoard"}];
        return nil;
    }
    NSString *base = lease.rootPath;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *versions = @[@"61", @"60", @"62", @"59"];
    for (NSString *v in versions) {
        NSString *p = [[[[base stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"]
                         stringByAppendingPathComponent:@"PRBPosterExtensionDataStore"] stringByAppendingPathComponent:v];
        NSString *d = [[p stringByAppendingPathComponent:@"Extensions"] stringByAppendingPathComponent:AWProvider];
        d = [d stringByAppendingPathComponent:@"descriptors"];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:d isDirectory:&isDir] && isDir) return d;
    }
    if (outError) *outError = [NSError errorWithDomain:@"AllWallpapers" code:2 userInfo:@{NSLocalizedDescriptionKey:@"CollectionsPoster descriptors folder not found"}];
    return nil;
}

- (NSString *)aw_nameFromDescriptor:(NSString *)descriptor {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *file in @[@"providerInfo.plist", @"com.apple.posterkit.provider.contents.userInfo"]) {
        NSString *p = [descriptor stringByAppendingPathComponent:file];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:p];
        if (![dict isKindOfClass:NSDictionary.class]) continue;
        for (NSString *key in @[@"displayName", @"localizedName", @"name", @"title"]) {
            id v = dict[key];
            if ([v isKindOfClass:NSString.class] && [v length]) return v;
        }
    }
    NSString *uuid = descriptor.lastPathComponent;
    return uuid ?: @"Wallpaper";
}

- (NSString *)aw_findImage:(NSString *)root {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray *names = [fm contentsOfDirectoryAtPath:root error:nil] ?: @[];
    for (NSString *n in names) {
        NSString *p = [root stringByAppendingPathComponent:n];
        BOOL dir = NO;
        if (![fm fileExistsAtPath:p isDirectory:&dir]) continue;
        if (dir) {
            NSString *found = [self aw_findImage:p];
            if (found) return found;
        } else {
            NSString *ext = n.pathExtension.lowercaseString;
            if ([(@[@"png", @"jpg", @"jpeg", @"heic", @"webp"]) containsObject:ext]) return p;
        }
    }
    return nil;
}

- (void)aw_load {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSString *root = [self aw_findStoreRoot:&error];
        if (!root) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *a = [UIAlertController alertControllerWithTitle:@"AllWallpapers"
                                                                              message:error.localizedDescription
                                                                       preferredStyle:UIAlertControllerStyleAlert];
                [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:a animated:YES completion:nil];
            });
            return;
        }
        NSFileManager *fm = NSFileManager.defaultManager;
        NSArray *names = [fm contentsOfDirectoryAtPath:root error:nil] ?: @[];
        NSMutableArray *items = [NSMutableArray array];
        for (NSString *name in names) {
            if ([name hasPrefix:@"."]) continue;
            NSString *p = [root stringByAppendingPathComponent:name];
            BOOL dir = NO;
            if (![fm fileExistsAtPath:p isDirectory:&dir] || !dir) continue;
            AWItem *item = [AWItem new];
            item.uuid = name;
            item.path = p;
            item.name = [self aw_nameFromDescriptor:p];
            NSString *img = [self aw_findImage:p];
            if (img) item.thumbnail = [UIImage imageWithContentsOfFile:img];
            [items addObject:item];
        }
        [items sortUsingComparator:^NSComparisonResult(AWItem *a, AWItem *b) {
            return [a.name localizedCaseInsensitiveCompare:b.name];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_items = [items copy];
            [self.tableView reloadData];
            self.navigationItem.prompt = [NSString stringWithFormat:@"%lu descriptors", (unsigned long)self->_items.count];
        });
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return _items.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"AWCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    AWItem *item = _items[indexPath.row];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.uuid;
    cell.imageView.image = item.thumbnail ? [self aw_scaled:item.thumbnail size:CGSizeMake(58,58)] : nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (UIImage *)aw_scaled:(UIImage *)image size:(CGSize)size {
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [image drawInRect:CGRectMake(0,0,size.width,size.height)];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AWItem *item = _items[indexPath.row];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:item.name
                                                                  message:@"Read-only build: this entry is an existing PosterBoard descriptor. Applying wallpapers is deliberately not implemented in v0.1."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
