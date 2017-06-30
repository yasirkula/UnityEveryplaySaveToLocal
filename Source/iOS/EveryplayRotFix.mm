#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "UnityAppController.h"

@interface UMediaManager:NSObject
+ (void)flipVideoSynchronous:(NSURL *)videoURL andOutputPath:(NSString *)exportPath;
+ (void)flipVideoAsynchronous:(NSURL *)videoURL andOutputPath:(NSString *)exportPath;
@end

@implementation UMediaManager

// Source: https://stackoverflow.com/questions/18872024/video-recorded-from-eaglview-is-flipped-when-uploaded-to-youtube
+ (void)flipVideoSynchronous:(NSURL *)videoURL andOutputPath:(NSString *)exportPath {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey:@YES }];

    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;

    CGAffineTransform transform;

	AVAssetTrack *assetVideoTrack = nil;
	AVAssetTrack *assetAudioTrack = nil;
	
	// Check if the asset contains video and audio tracks
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
	}
	if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
		assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
	}

	CMTime insertionPoint = kCMTimeZero;
	NSError *error = nil;

	// Step 1
	// Create a composition with the given asset and insert audio and video tracks into it from the asset
	AVMutableComposition *mutableComposition = [AVMutableComposition composition];

	// Insert the video and audio tracks from AVAsset
	if (assetVideoTrack != nil) {
		AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
		[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
	}
	if (assetAudioTrack != nil) {
		AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
		[compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
	}

	// Step 2
	// Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
	// Rotate transformation
	transform = CGAffineTransformMake(1, 0, 0, -1, 0, assetVideoTrack.naturalSize.height);

	// Step 3
	// Set the appropriate render sizes and rotational transforms
	// Create a new video composition
	AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
	mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
	mutableVideoComposition.frameDuration = CMTimeMake(1, 30);

	// The rotate transform is set on a layer instruction
	instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
	layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(mutableComposition.tracks)[0]];
	[layerInstruction setTransform:transform atTime:kCMTimeZero];

	// Step 4
	// Add the transform instructions to the video composition
	instruction.layerInstructions = @[layerInstruction];
	mutableVideoComposition.instructions = @[instruction];

	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:[mutableComposition copy] presetName:AVAssetExportPresetHighestQuality];

	exportSession.videoComposition = mutableVideoComposition;
	exportSession.outputURL = [NSURL fileURLWithPath:exportPath];
	exportSession.outputFileType=AVFileTypeQuickTimeMovie;
	exportSession.shouldOptimizeForNetworkUse = YES;

	dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){

        dispatch_semaphore_signal(sema);
        
        dispatch_async(dispatch_get_main_queue(), ^{
				switch (exportSession.status) {
					case AVAssetExportSessionStatusCompleted:
						NSLog(@"Video processing complete");
						break;
					case AVAssetExportSessionStatusFailed:
						NSLog(@"Failed processing video:%@",exportSession.error);
						break;
					case AVAssetExportSessionStatusCancelled:
						NSLog(@"Canceled processing video:%@",exportSession.error);
						break;
					default:
						break;
				}
			});
	}];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

// Source: https://stackoverflow.com/questions/18872024/video-recorded-from-eaglview-is-flipped-when-uploaded-to-youtube
+ (void)flipVideoAsynchronous:(NSURL *)videoURL andOutputPath:(NSString *)exportPath {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey:@YES }];

    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;

    CGAffineTransform transform;

	AVAssetTrack *assetVideoTrack = nil;
	AVAssetTrack *assetAudioTrack = nil;
	
	// Check if the asset contains video and audio tracks
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
	}
	if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
		assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
	}

	CMTime insertionPoint = kCMTimeZero;
	NSError *error = nil;

	// Step 1
	// Create a composition with the given asset and insert audio and video tracks into it from the asset
	AVMutableComposition *mutableComposition = [AVMutableComposition composition];

	// Insert the video and audio tracks from AVAsset
	if (assetVideoTrack != nil) {
		AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
		[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
	}
	if (assetAudioTrack != nil) {
		AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
		[compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
	}

	// Step 2
	// Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
	// Rotate transformation
	transform = CGAffineTransformMake(1, 0, 0, -1, 0, assetVideoTrack.naturalSize.height);

	// Step 3
	// Set the appropriate render sizes and rotational transforms
	// Create a new video composition
	AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
	mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
	mutableVideoComposition.frameDuration = CMTimeMake(1, 30);

	// The rotate transform is set on a layer instruction
	instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
	layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(mutableComposition.tracks)[0]];
	[layerInstruction setTransform:transform atTime:kCMTimeZero];

	// Step 4
	// Add the transform instructions to the video composition
	instruction.layerInstructions = @[layerInstruction];
	mutableVideoComposition.instructions = @[instruction];

	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:[mutableComposition copy] presetName:AVAssetExportPresetHighestQuality];

	exportSession.videoComposition = mutableVideoComposition;
	exportSession.outputURL = [NSURL fileURLWithPath:exportPath];
	exportSession.outputFileType=AVFileTypeQuickTimeMovie;
	exportSession.shouldOptimizeForNetworkUse = YES;

    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        if( exportSession.status == AVAssetExportSessionStatusCompleted )
			UnitySendMessage("EveryplayLocalSaveHelper", "OnVideoProcessed", "1");
		else
			UnitySendMessage("EveryplayLocalSaveHelper", "OnVideoProcessed", "0");
        
        dispatch_async(dispatch_get_main_queue(), ^{
				switch (exportSession.status) {
					case AVAssetExportSessionStatusCompleted:
						NSLog(@"Video processing complete");
						break;
					case AVAssetExportSessionStatusFailed:
						NSLog(@"Failed processing video:%@",exportSession.error);
						break;
					case AVAssetExportSessionStatusCancelled:
						NSLog(@"Canceled processing video:%@",exportSession.error);
						break;
					default:
						break;
				}
			});
	}];
}

@end

extern "C" void _FlipVideoSynchronous(const char* path, const char* outputPath) {
	NSString *videoPath = [NSString stringWithUTF8String:path];
	NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
	
	NSString *videoOutputPath = [NSString stringWithUTF8String:outputPath];
	
	[UMediaManager flipVideoSynchronous:videoURL andOutputPath:videoOutputPath];
}

extern "C" void _FlipVideoAsynchronous(const char* path, const char* outputPath) {
	NSString *videoPath = [NSString stringWithUTF8String:path];
	NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
	
	NSString *videoOutputPath = [NSString stringWithUTF8String:outputPath];
	
	[UMediaManager flipVideoAsynchronous:videoURL andOutputPath:videoOutputPath];
}