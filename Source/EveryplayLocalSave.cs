using System.Collections;
using System.IO;
using UnityEngine;

public static class EveryplayLocalSave
{
#if !UNITY_EDITOR && UNITY_IOS
    [System.Runtime.InteropServices.DllImport( "__Internal" )]
    private static extern void _FlipVideoSynchronous( string path, string outputPath );

	[System.Runtime.InteropServices.DllImport( "__Internal" )]
    private static extern void _FlipVideoAsynchronous( string path, string outputPath );

	private static EveryplayLocalSaveHelper asyncHelper = null;
#endif
	
	private static string m_savePath = null;

	public static bool IsBusy { get; private set; }
	public static string SavedPath { get; private set; }

	public static bool SaveTo( string path )
	{
		if( SaveToInternal( path, false ) )
		{
			Debug.Log( "Video saved: " + SavedPath );
			return true;
		}

		return false;
	}

	public static IEnumerator SaveToAsync( string path )
	{
		if( SaveToInternal( path, true ) )
		{
			while( IsBusy )
				yield return null;

			if( SavedPath != null )
				Debug.Log( "Video saved: " + SavedPath );
		}
		else
		{
			IsBusy = false;
		}
		
		yield break;
	}

	private static bool SaveToInternal( string path, bool async )
	{
		if( IsBusy )
		{
			Debug.LogError( "Another save operation is in progress" );
			return false;
		}

		SavedPath = null;

		if( path == null || path.Length == 0 )
			throw new System.ArgumentException( "Parameter 'path' is null or empty!" );

		if( !path.EndsWith( ".mp4" ) )
			path = Path.Combine( path, "session {0}.mp4" );

		// Credit: http://answers.unity3d.com/questions/1224739/everyplay-video-local-file.html
		string recordedVideoDir = null;
#if UNITY_ANDROID
		recordedVideoDir = Path.Combine( new DirectoryInfo( Application.temporaryCachePath ).FullName, "sessions" );
#elif UNITY_IOS
        recordedVideoDir = new DirectoryInfo( Application.persistentDataPath ).Parent.FullName + "/tmp/Everyplay/session";
#endif

		FileInfo[] files = new DirectoryInfo( recordedVideoDir ).GetFiles( "*.mp4", SearchOption.AllDirectories );
		if( files.Length > 0 )
			recordedVideoDir = files[0].FullName;
		else
		{
			Debug.LogError( "Couldn't find a recorded Everyplay session!" );
			return false;
		}

		if( path.Contains( "{0}" ) )
		{
			int fileIndex = 0;
			string newPath;
			do
			{
				newPath = string.Format( path, ++fileIndex );
			} while( File.Exists( newPath ) );

			path = newPath;
		}

		if( !File.Exists( path ) )
		{ 
			string directory = Path.GetDirectoryName( path );
			if( directory != null && directory.Length > 0 )
				Directory.CreateDirectory( directory );
		}

#if UNITY_EDITOR || UNITY_ANDROID
		File.Copy( recordedVideoDir, path, true );
		SavedPath = path;
#elif UNITY_IOS
		if( SystemInfo.graphicsDeviceType == UnityEngine.Rendering.GraphicsDeviceType.Metal )
		{
			File.Copy( recordedVideoDir, path, true );
			SavedPath = path;
		}
		else
		{
			if( !async )
			{
				_FlipVideoSynchronous( recordedVideoDir, path );

				if( !File.Exists( path ) )
					return false;

				SavedPath = path;
			}
			else
			{
				IsBusy = true;
				m_savePath = path;

				if( asyncHelper == null )
				{
					asyncHelper = new GameObject( "EveryplayLocalSaveHelper" ).AddComponent<EveryplayLocalSaveHelper>();
					asyncHelper.VideoProcessed = OnVideoProcessed;
					Object.DontDestroyOnLoad( asyncHelper.gameObject );
				}

				_FlipVideoAsynchronous( recordedVideoDir, path );
			}
		}
#endif

		return true;
	}

	private static void OnVideoProcessed( bool success )
	{
		IsBusy = false;
		
		if( success && File.Exists( m_savePath ) )
			SavedPath = m_savePath;

		m_savePath = null;
    }
}