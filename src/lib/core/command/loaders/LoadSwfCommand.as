package lib.core.command.loaders
{
import flash.display.Loader;
import flash.system.Security;

import lib.core.util.log.Logger;
import lib.core.ui.skins.SkinsManager;


/**
 * Команда загрузки скина.
 * Можно грузить скин напрямую через SkinsManager, можно использовать команду,
 * например для вставки в общую очередь команд.
 */
public class LoadSwfCommand extends LoaderCommand
{
	protected var source:Object;
	protected var localDomain:Boolean;

	private var skinsManager:SkinsManager;

	private var _loader:Loader;
	public function get loader():Loader
	{
		return _loader;
	}

	override public function get url():String
	{
		return String(source);
	}

	/**
	 *
	 * @param source путь к swf со скинами или byteArray с swf файлом
	 *
	 */
	public function LoadSwfCommand(source:Object, localDomain:Boolean)
	{
		this.source = source;
		this.localDomain = localDomain;
	}

	override protected function execInternal ():void
	{
		skinsManager = SkinsManager.instance;

		if(skinsManager.isLibLoaded(source))
		{
			notifyComplete();
			return;
		}

		if(source is String)
		{
			Security.allowDomain(source);
//			Logger.debug(this, "load rsl lib = ", url);
		}

		_loader = skinsManager.loadSwf(source, localDomain);

		loaderDispatcher = _loader.contentLoaderInfo;

		super.execInternal();
	}
}
}