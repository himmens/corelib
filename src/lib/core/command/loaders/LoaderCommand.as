package lib.core.command.loaders
{
import lib.core.AppErrorCodes;
import lib.core.command.Command;
import lib.core.util.log.Logger;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;


[Event (name="progress", type="flash.events.ProgressEvent")]

/**
 * Команда загрузчик - обертка любого загрузчика (с событиями complete, progress, ioError, securityError),
 * для интеграции загрузки скинов и изображений в общий потом команд.
 */
public class LoaderCommand extends Command
{
	public var errorReason:String = "";

	/**
	 * Для логирования, функционально не используется
	 * @return
	 *
	 */
	public function get url():String
	{
		return null;
	}

	protected var loaderDispatcher:EventDispatcher;

	/**
	 *
	 */
	public function LoaderCommand()
	{
	}

	override protected function execInternal ():void
	{
		//Logger.debug(this, "execInternal");
		handleLoaderDispatcher(loaderDispatcher);
	}

	protected function handleLoaderDispatcher(loaderDispatcher:EventDispatcher):void
	{
		this.loaderDispatcher = loaderDispatcher;
		if(loaderDispatcher)
		{
			loaderDispatcher.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
			loaderDispatcher.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
			loaderDispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError, false, 0, true);
			loaderDispatcher.addEventListener(ProgressEvent.PROGRESS, onProgress, false, 0, true);
		}
	}

	protected function onComplete(event:Event):void
	{
		notifyComplete();
	}

	protected function onProgress(event:ProgressEvent):void
	{
		//Logger.debug(this, "onProgress: " ,event.bytesLoaded/event.bytesTotal);
		dispatchEvent(event);
	}

	protected function onError(event:Event):void
	{
		_errorCode = AppErrorCodes.ASSETTS_LOAD_ERROR;
		errorReason = event.type;
		notifyComplete();
	}

	override protected function onTimeout(event:Event):void
	{
		errorReason = "timeout";
		super.onTimeout(event);
	}
	override protected function notifyComplete():void
	{
		if(_errorCode && !complete)
		{
			Logger.error(this, "loading error, url = ",url, ", code = ",_errorCode);
		}

		if(loaderDispatcher)
		{
			loaderDispatcher.removeEventListener(Event.COMPLETE, onComplete, false);
			loaderDispatcher.removeEventListener(IOErrorEvent.IO_ERROR, onError, false);
			loaderDispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError, false);
			loaderDispatcher.removeEventListener(ProgressEvent.PROGRESS, onProgress, false);
		}

		super.notifyComplete();
	}
}
}