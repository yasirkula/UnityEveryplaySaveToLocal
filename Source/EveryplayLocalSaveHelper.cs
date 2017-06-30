using UnityEngine;

public class EveryplayLocalSaveHelper : MonoBehaviour 
{
#if !UNITY_EDITOR && UNITY_IOS
	public System.Action<bool> VideoProcessed = null;
	
    public void OnVideoProcessed( string message )
    {
		if( VideoProcessed == null )
			return;

		if( message == null || message != "1" )
			VideoProcessed( false );
		else
			VideoProcessed( true );
    }
#endif
}