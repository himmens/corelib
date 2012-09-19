package lib.core.command.loaders
{
import flash.display.Loader;
import flash.system.Security;
import flash.utils.ByteArray;
import lib.core.ui.skins.SkinsManager;
	
	
/**
 * Команда загрузки скина.
 * Можно грузить скин напрямую через SkinsManager, можно использовать команду,
 * например для вставки в общую очередь команд.
 */	
public class LoadSkinCommand extends LoaderCommand
{
	protected var source:Object;
	
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
	public function LoadSkinCommand(source:Object)
	{
		this.source = source;
	}
	
	override protected function execInternal ():void
	{
		skinsManager = SkinsManager.instance;

		if(skinsManager.isLibLoaded(source))
		{
			notifyComplete();
			return;
		}
			
		_loader = skinsManager.loadSkin(source);
		
		loaderDispatcher = _loader.contentLoaderInfo;
		
		super.execInternal();
	}
}
}