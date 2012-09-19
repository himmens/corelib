package lib.core.command
{
import flash.events.Event;
	
/**
 * Команда для параллельного выполнения группы команд, которая ждет завершения хотя бы одной в группе
 */
public class SingleBoxCommand extends BoxCommand
{
	public function SingleBoxCommand(commands:Array)
	{
		super(commands);
	}
	
	override protected function onComplete (e:Event):void
	{
		//Дожидаемся ответа хотя бы одной команды, остальные завершаем
		for each (var c:Command in queue)
		{
			c.removeEventListener(Event.COMPLETE, onComplete);
			if (!c.complete)
				c.terminate();
		}
		notifyComplete();
	}
	
	override public function terminate ():void
	{
		for each (var c:Command in queue)
		{
			c.removeEventListener(Event.COMPLETE, onComplete);
			c.terminate();
		}
		super.terminate();
	}
}
}