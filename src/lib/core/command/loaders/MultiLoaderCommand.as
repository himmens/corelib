package lib.core.command.loaders
{
import lib.core.command.BoxCommand;
import lib.core.command.Command;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.utils.Dictionary;

[Event (name="progress", type="flash.events.ProgressEvent")]

/**
 * Команда - очередь LoaderCommand с общим progress событием, с суммарным числом байт.
 *
 * Для корректного подсчета общего числа байт очередь команд нельзя пополнять после вызова execute()
 */
public class MultiLoaderCommand extends BoxCommand
{
	protected var bytesLoaded:int;
	protected var bytesTotal:int;

	private var totalLdrs:int;
	private var pending:Dictionary = new Dictionary(true);
	/**
	 *
	 */
	public function MultiLoaderCommand(...commands)
	{
		super(commands);
	}

	override protected function execInternal ():void
	{
		if(queue.length == 0)
		{
			notifyComplete();
			return;
		}

		pending = new Dictionary(true);
		var ldrCmd:LoaderCommand;
		for each(var cmd:Command in queue)
		{
			ldrCmd = cmd as LoaderCommand;
			if(ldrCmd)
			{
				ldrCmd.addEventListener(ProgressEvent.PROGRESS, onProgress);
				ldrCmd.addEventListener(Event.COMPLETE, onCommandComplete);
			}
		}
		totalLdrs = queue.length;

		super.execInternal();
	}

	private function onCommandComplete (event:Event):void
	{
		var cmd:LoaderCommand = LoaderCommand(event.target);

		if(!pending[cmd])
		{
			pending[cmd] = {};
		}

		notifyProgress();
	}

	private function onProgress(event:ProgressEvent):void
	{
		var cmd:LoaderCommand = LoaderCommand(event.target);
		//если еще не посчитали в суммарное количество - считаем
		if(!pending[cmd])
		{
			bytesTotal+=event.bytesTotal;
		}

		pending[cmd] = event.bytesLoaded || {};

		notifyProgress();
	}

	protected function notifyProgress():void
	{
		bytesLoaded = 0;

		var cnt:int = 0;
		for each(var value:String in pending)
		{
			bytesLoaded+=int(value);
			cnt++;
		}

		if(cnt == totalLdrs)
		{
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, bytesLoaded, bytesTotal));
		}
	}
}
}