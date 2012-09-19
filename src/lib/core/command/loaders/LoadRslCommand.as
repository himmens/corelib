package lib.core.command.loaders
{
import flash.utils.ByteArray;

import lib.core.util.log.Logger;


/**
 * Команда загрузки скина.
 * Можно грузить скин напрямую через SkinsManager, можно использовать команду,
 * например для вставки в общую очередь команд.
 */
public class LoadRslCommand extends LoadSwfCommand
{
	/**
	 *
	 * @param source путь к swf со скинами или byteArray с swf файлом
	 *
	 */
	public function LoadRslCommand(source:Object)
	{
		super(source, true);
	}

	override protected function execInternal ():void
	{
		if(!(source is ByteArray))
			Logger.debug(this, "url = " + source );

		super.execInternal();
	}
}
}