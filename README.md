# Unity Everyplay Save to Local
**UPDATE:** With the release of *2200-1600*, Everyplay now officially supports getting the path of the recorded video, which renders this plugin obsolete. See [Everyplay.GetFilepath()](https://github.com/Everyplay/everyplay-unity-sdk/blob/master/USAGE.md) for more info.

This is a little plugin to help you save your **Everyplay** recordings to your mobile device, instead of having to upload them to Everyplay servers. It it tested with **Everyplay Release 2160-1580** on both Android and iOS. Please note that **FaceCam** features are not supported and these additional media (microphone input and/or camera feed) will simply be ignored.

Everyplay internally saves its last session to a temporary folder in **mp4** format. However, for some reason, the video is rendered upside down on iOS devices when *OpenGLES* Graphics API is used instead of *Metal*. This script takes that fact into consideration and flips the video in such a case. So, the saved video should always be correctly oriented.

All you have to do is to import **EveryplayLocalSave.unitypackage** to your project and you are good to go!

## How To
As video flipping operation on iOS can take some time for long videos, there are two different functions to save your videos: one asynchronous and one synchronous.

- `EveryplayLocalSave.SaveTo( string path )`: synchronously saves the video to **path**. Returns **true** if the video is saved successfully, **false** otherwise. One thing to note here is that the path is *string.Format*'ed to avoid overwriting an existing video file, if desired. Just put a **{0}** in your path and it will be replaced with a unique number, starting from 1. For example, if your path ends with "*my video {0}.mp4*", the videos will be saved as "*my video 1.mp4*", "*my video 2.mp4*" and so on. If you don't provide a *{0}* in your path and a file happens to exist at that path, it will be overwritten.

- `EveryplayLocalSave.SaveToAsync( string path )`: asynchronously saves the video to **path**. Returns an **IEnumerator** object that you can **yield** in coroutines (see example code below).

The plugin may alter your **path** string if it contains a *{0}* or if a filename is not provided in the path. Therefore, use **EveryplayLocalSave.SavedPath** to access the saved file's path correctly. If it is *null*, either the video was not saved correctly or it is still being saved (async call). Note that you can not issue more than one save commands at a time; therefore, it is recommended to check the value of **EveryplayLocalSave.IsBusy** before attempting to save the video to disk.

**NOTE:** in order to ensure that you save the most recent Everyplay recording to your local storage, call these functions after **Everyplay.RecordingStopped** event is triggered.

## Example Code
The following code snippet saves an Everyplay session to *Application.persistentDataPath\saved video {0}.mp4* as soon as the recording has finished. 

```csharp
void Start()
{
	Everyplay.RecordingStopped += OnRecordingStopped;
}

void OnDestroy()
{
	Everyplay.RecordingStopped -= OnRecordingStopped;
}

private void OnRecordingStopped()
{
	// synchronous
	//if( EveryplayLocalSave.SaveTo( Path.Combine( Application.persistentDataPath, "saved video {0}.mp4" ) ) )
	//	Debug.Log( "Video saved to " + EveryplayLocalSave.SavedPath );

	// async
	StartCoroutine( EveryplayLocalSaveAsync() );
}

private IEnumerator EveryplayLocalSaveAsync()
{
	// Only async on iOS, results immediately on Android
	yield return EveryplayLocalSave.SaveToAsync( Path.Combine( Application.persistentDataPath, "saved video {0}.mp4" ) );

	if( EveryplayLocalSave.SavedPath != null )
		Debug.Log( "Video saved to " + EveryplayLocalSave.SavedPath );
	else
		Debug.LogWarning( "Could not save the video; check logs!" );
}
```
