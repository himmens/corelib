package lib.core.command.loaders
{
import flash.display.LoaderInfo;
import flash.display.Shape;
import flash.events.Event;
import flash.events.ProgressEvent;
	
	
/**
 * Команда загрузки любого loaderInfo, например загрузка главного swf - root.loaderInfo
 * 	
 */	
public class LoaderInfoLoaderCommand extends LoaderCommand
{
	
	private static var shape:Shape = new Shape();
	
	private var _loaderInfo:LoaderInfo;
	/**
	 * 
	 * @param url url для загруки данных
	 * 
	 */
	public function LoaderInfoLoaderCommand(loaderInfo:LoaderInfo)
	{
		_loaderInfo = loaderInfo;
	}
	
	override protected function execInternal ():void
	{
		shape.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	public function onEnterFrame(event:Event):void
	{
		var bytesLoaded:int = _loaderInfo.bytesLoaded;
		var bytesTotal:int = _loaderInfo.bytesTotal;
		
		if(bytesLoaded == bytesTotal)
		{
			notifyComplete();
		}
		else
		{
			event = new ProgressEvent(ProgressEvent.PROGRESS, false, false, bytesLoaded, bytesTotal);
			dispatchEvent(event);
		}
	}

	override protected function notifyComplete():void
	{
		shape.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
		super.notifyComplete();
	}
	
}
}