package lib.core.command.loaders
{
import flash.display.Loader;
import flash.events.Event;

import lib.core.media.SoundManager;
import lib.core.ui.skins.SkinsManager;
	
	
/**
 * Команда загрузки скина.
 * Можно грузить скин напрямую через SkinsManager, можно использовать команду,
 * например для вставки в общую очередь команд.
 */	
public class LoadSoundCommand extends LoaderCommand
{
	private var source:Object;
	private var names:Array;
	
	private var skinsManager:SkinsManager;
	
	private var _loader:Loader;
	//public function get loader():Loader
	//{
	//	return _loader;
	//}
	/**
	 * 
	 * @param source путь к swf или byteArray с swf файлом со звуками
	 * @param names список имен звуков в файле
	 * 
	 */
	public function LoadSoundCommand(source:Object, names:Array)
	{
		this.source = source;
		this.names = names;
	}
	
	override protected function execInternal ():void
	{
		skinsManager = SkinsManager.instance;

		if(skinsManager.isLibLoaded(source))
		{
			for each(var name:String in names)
			{
				handleSound(name, skinsManager.getSkinDefinition(name));
			}
			
			notifyComplete();
			return;
		}
			
		_loader = skinsManager.loadSkin(source);
		
		loaderDispatcher = _loader.contentLoaderInfo;
		
		super.execInternal();
	}
	
	override protected function onComplete(event:Event):void
	{
		for each(var name:String in names)
		{
			handleSound(name, skinsManager.getSkinDefinition(name));
		}
		
		super.onComplete(event);
	}
	
	protected function handleSound(name:String, sndClass:Class):void
	{
		var manager:SoundManager = SoundManager.instance;
		if(sndClass && manager)
		{
			manager.addLibrarySound(name, new sndClass());
		}
	}
}
}