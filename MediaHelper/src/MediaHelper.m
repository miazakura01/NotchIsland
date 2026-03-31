#import <Foundation/Foundation.h>
#import <dlfcn.h>

// MediaRemote function types
typedef void (*MRMediaRemoteRegisterFunc)(dispatch_queue_t queue);
typedef void (*MRMediaRemoteGetInfoFunc)(dispatch_queue_t queue, void (^callback)(CFDictionaryRef info));
typedef Boolean (*MRMediaRemoteSendCmdFunc)(uint32_t command, void *options);

static MRMediaRemoteGetInfoFunc getInfoFunc = NULL;
static MRMediaRemoteSendCmdFunc sendCmdFunc = NULL;

__attribute__((constructor))
static void initialize(void) {
    void *handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    if (!handle) return;

    MRMediaRemoteRegisterFunc registerFunc = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications");
    getInfoFunc = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo");
    sendCmdFunc = dlsym(handle, "MRMediaRemoteSendCommand");

    if (registerFunc) {
        registerFunc(dispatch_get_main_queue());
    }
}

// Exported function: prints now playing JSON to stdout
__attribute__((visibility("default")))
void MediaHelperPrintNowPlaying(void) {
    if (!getInfoFunc) {
        printf("null\n");
        fflush(stdout);
        return;
    }

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block NSString *jsonStr = nil;

    getInfoFunc(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(CFDictionaryRef info) {
        if (!info) {
            dispatch_semaphore_signal(sem);
            return;
        }

        NSDictionary *dict = (__bridge NSDictionary *)info;

        NSString *title = dict[@"kMRMediaRemoteNowPlayingInfoTitle"] ?: @"";
        NSString *artist = dict[@"kMRMediaRemoteNowPlayingInfoArtist"] ?: @"";
        NSString *album = dict[@"kMRMediaRemoteNowPlayingInfoAlbum"] ?: @"";
        NSNumber *duration = dict[@"kMRMediaRemoteNowPlayingInfoDuration"] ?: @0;
        NSNumber *elapsed = dict[@"kMRMediaRemoteNowPlayingInfoElapsedTime"] ?: @0;
        NSNumber *playbackRate = dict[@"kMRMediaRemoteNowPlayingInfoPlaybackRate"] ?: @0;

        NSData *artworkData = dict[@"kMRMediaRemoteNowPlayingInfoArtworkData"];
        NSString *artworkB64 = artworkData ? [artworkData base64EncodedStringWithOptions:0] : @"";

        NSMutableDictionary *output = [NSMutableDictionary dictionary];
        output[@"title"] = title;
        output[@"artist"] = artist;
        output[@"album"] = album;
        output[@"duration"] = duration;
        output[@"elapsedTime"] = elapsed;
        output[@"playing"] = @([playbackRate doubleValue] > 0);
        if (artworkB64.length > 0) {
            output[@"artworkData"] = artworkB64;
        }

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:output options:0 error:nil];
        if (jsonData) {
            jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }

        dispatch_semaphore_signal(sem);
    });

    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));

    if (jsonStr) {
        printf("%s\n", [jsonStr UTF8String]);
    } else {
        printf("null\n");
    }
    fflush(stdout);
}

// Exported function: send media command
__attribute__((visibility("default")))
void MediaHelperSendCommand(int command) {
    if (sendCmdFunc) {
        sendCmdFunc((uint32_t)command, NULL);
    }
}
