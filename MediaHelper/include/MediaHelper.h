#import <Foundation/Foundation.h>

/// Get now playing info as JSON string
NSString* _Nullable MediaHelperGetNowPlaying(void);

/// Send a media command (0=play, 1=pause, 2=togglePlayPause, 4=next, 5=previous)
void MediaHelperSendCommand(int command);
