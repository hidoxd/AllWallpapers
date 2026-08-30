#import "MCMBridge.h"
#import <dlfcn.h>
#import <xpc/xpc.h>

#define LOADSYM(h, n, t) ((t)dlsym((h), (n)))

typedef void *(*QCreate)(void);
typedef void (*QSetU64)(void *, uint64_t);
typedef void (*QSetXPC)(void *, xpc_object_t);
typedef void *(*QGet)(void *);
typedef void (*QFree)(void *);
typedef const char *(*OGetPath)(void *);
typedef void *(*OCopy)(void *);
typedef char *(*OCopyToken)(void *);
typedef bool (*OActivate)(void *, bool);
typedef void (*OFree)(void *);

typedef struct {
    void *h;
    QCreate queryCreate;
    QSetU64 querySetClass;
    QSetXPC querySetIdentifiers;
    QSetU64 querySetFlags;
    QGet queryGetSingle;
    QFree queryFree;
    OGetPath objectGetPath;
    OCopy objectCopy;
    OCopyToken objectCopyToken;
    OActivate objectActivate;
    OFree objectFree;
} API;

static API *sharedAPI(void) {
    static API api;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        api.h = dlopen("/usr/lib/system/libsystem_containermanager.dylib", RTLD_NOW | RTLD_LOCAL);
        void *h = api.h ?: RTLD_DEFAULT;
        api.queryCreate = LOADSYM(h, "container_query_create", QCreate);
        api.querySetClass = LOADSYM(h, "container_query_set_class", QSetU64);
        api.querySetIdentifiers = LOADSYM(h, "container_query_set_identifiers", QSetXPC);
        api.querySetFlags = LOADSYM(h, "container_query_operation_set_flags", QSetU64);
        api.queryGetSingle = LOADSYM(h, "container_query_get_single_result", QGet);
        api.queryFree = LOADSYM(h, "container_query_free", QFree);
        api.objectGetPath = LOADSYM(h, "container_object_get_path", OGetPath);
        api.objectCopy = LOADSYM(h, "container_object_copy", OCopy);
        api.objectCopyToken = LOADSYM(h, "container_copy_sandbox_token", OCopyToken);
        api.objectActivate = LOADSYM(h, "container_object_sandbox_extension_activate", OActivate);
        api.objectFree = LOADSYM(h, "container_object_free", OFree);
    });
    return &api;
}

@interface AWMCMLease () {
    void *_query;
    void *_activation;
    NSString *_rootPath;
}
@property(nonatomic, copy, readwrite) NSString *rootPath;
@end

@implementation AWMCMLease

+ (instancetype)leaseForClass:(uint64_t)containerClass identifier:(NSString *)identifier error:(NSString **)error {
    API *a = sharedAPI();
    if (!a->queryCreate || !a->querySetClass || !a->querySetIdentifiers || !a->querySetFlags ||
        !a->queryGetSingle || !a->queryFree || !a->objectGetPath || !a->objectCopy ||
        !a->objectCopyToken || !a->objectActivate || !a->objectFree) {
        if (error) *error = @"ContainerManager API unavailable";
        return nil;
    }
    void *q = a->queryCreate();
    if (!q) { if (error) *error = @"container_query_create failed"; return nil; }
    a->querySetClass(q, containerClass);
    xpc_object_t id = xpc_string_create(identifier.UTF8String);
    a->querySetIdentifiers(q, id);
#if !OS_OBJECT_USE_OBJC
    xpc_release(id);
#endif
    a->querySetFlags(q, 0x900000000ULL);
    void *obj = a->queryGetSingle(q);
    if (!obj) {
        a->queryFree(q);
        if (error) *error = @"PosterBoard container lookup failed";
        return nil;
    }
    const char *raw = a->objectGetPath(obj);
    NSString *path = raw ? [NSString stringWithUTF8String:raw] : nil;
    if (!path.length) {
        a->queryFree(q);
        if (error) *error = @"PosterBoard path unavailable";
        return nil;
    }
    if ([path isEqualToString:@"/var"] || [path hasPrefix:@"/var/"]) {
        path = [@"/private" stringByAppendingString:path];
    }
    AWMCMLease *lease = [AWMCMLease new];
    lease->_query = q;
    lease->_rootPath = [path copy];
    return lease;
}

- (BOOL)activate:(NSString **)error {
    if (_activation) return YES;
    API *a = sharedAPI();
    void *obj = a->queryGetSingle(_query);
    _activation = obj ? a->objectCopy(obj) : NULL;
    char *token = _activation ? a->objectCopyToken(_activation) : NULL;
    BOOL ok = token && token[0] && a->objectActivate(_activation, false);
    if (token) free(token);
    if (!ok && error) *error = @"PosterBoard sandbox extension activation failed";
    return ok;
}

- (void)dealloc {
    API *a = sharedAPI();
    if (_activation) { a->objectFree(_activation); _activation = NULL; }
    if (_query) { a->queryFree(_query); _query = NULL; }
}
@end
