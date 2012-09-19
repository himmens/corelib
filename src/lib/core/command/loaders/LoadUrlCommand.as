package lib.core.command.loaders
{
import lib.core.util.log.Logger;

import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;


/**
 * Команда загрузки любого url (обертка для URLLoader).
 *
 */
public class LoadUrlCommand extends LoaderCommand
{
	protected var _url:Object;
	protected var format:String;

	protected var _loader:URLLoader;

	protected var _urlData:Object;
	public function get urlData():Object
	{
		return _urlData;
	};
	override public function get url():String
	{
		return String(_url);
	}

	/**
	 *
	 * @param url url для загруки данных
	 *
	 */
	public function LoadUrlCommand(source:Object, format:String = "text")
	{
		this._url = source;
		this.format = format;
	}

	override protected function execInternal ():void
	{
		var bytes:ByteArray = _url as ByteArray;
		Logger.debug(this, "load url: ", bytes ? "<ByteArray>" :_url, ", format = ", format);

		if(bytes)
		{
			bytes.position = 0;
			_urlData = bytes.readUTFBytes(bytes.bytesAvailable);
			processData(_urlData);
			super.onComplete(null);
		}
		else if(url)
		{
			_loader = new URLLoader();
			_loader.dataFormat = format;
			_loader.load(new URLRequest(url));

			handleLoaderDispatcher(_loader);
		}else
		{
			Logger.warning(this, "url isn't defined: url = ", url);
			notifyComplete();
		}
	}

	override protected function onComplete(event:Event):void
	{
		_urlData = URLLoader(event.target).data;
		processData(_urlData);

		Logger.debug(this, "url ", _url, " loaded");
		super.onComplete(event);
	}
	
	protected function processData(data:Object):void
	{
		
	}

}
}