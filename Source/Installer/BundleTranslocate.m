#import "BundleTranslocate.h"
#import <sys/mount.h>

BOOL appBundleTranslocatedToARandomizedPath(NSString *bundle)
{
    const char *bundleAbsPath = [[bundle stringByExpandingTildeInPath] UTF8String];
    int entryCount = getfsstat(NULL, 0, 0);
    int entrySize = sizeof(struct statfs);
    struct statfs *bufs = (struct statfs *)calloc(entryCount, entrySize);
    entryCount = getfsstat(bufs, entryCount * entrySize, MNT_NOWAIT);
    for (int i = 0; i < entryCount; i++) {
        if (!strcmp(bundleAbsPath, bufs[i].f_mntfromname)) {
            free(bufs);

            // getfsstat() may return us a cached result, and so we need to get the stat of the mounted fs.
            // If statfs() returns an error, the mounted fs is already gone.
            struct statfs stat;
            int checkResult = statfs(bundleAbsPath, &stat);
            if (checkResult != 0) {
                // Meaning the app's bundle is not mounted, that is it's not translocated.
                // It also means that the app is not loaded.
                return NO;
            }

            return YES;
        }
    }
    free(bufs);
    return NO;
}
