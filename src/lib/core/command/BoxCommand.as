package lib.core.command
{

import flash.events.Event;

/**
 * выполнена одна из команд в очереди,
 * последняя выполненная команда доступна по ссылке QueueCommand.completedCommand
 */
[Event (name="commandComplete", type="flash.events.Event")]
/**
 * команда для параллельного выполнения группы команд
 */
public class BoxCommand extends Command
{
	public static const COMMAND_COMPLETE:String = "commandComplete";

	private var _completedCommand:Command;
	public function get completedCommand():Command{return _completedCommand;}

	public var queue:Array = [];

	/**
	 * счетчик выполненных команд
	 */
	private var counter:int;

	public function BoxCommand(...commands)
	{
		if (commands.length > 0)
		{
			if (commands[0] is Array)
			{
				this.queue = commands[0] as Array;
			}
			else
			{
				for each (var c:Command in commands)
				{
					queue.push(c);
				}
			}
		}
	}

	override protected function execInternal ():void
	{
		counter = 0;

		if(queue.length > 0)
		{
			for each (var c:Command in queue)
			{
				c.addEventListener(Event.COMPLETE, onComplete, false,0,true);
				c.execute();
			}
		}else
		{
			notifyComplete();
		}
	}

	/**
	 * Добавляем команду. Команда должна быть добавлена перед вызовом execute()
	 * @param c
	 * @return
	 *
	 */
	public function add (c:Command):Command
	{
		queue.push(c);
		return c;
	}

	/**
	 * Добавляем массив команд. Команды должны быть добавлены перед вызовом execute()
	 * @param arr
	 *
	 */
	public function addList (arr:Array):void
	{
		queue = queue.concat(arr);
	}

	protected function onComplete (e:Event):void
	{
		counter++;

		Command (e.target).removeEventListener(Event.COMPLETE, onComplete);

		_completedCommand = Command (e.target);
		dispatchEvent(new Event(COMMAND_COMPLETE));

		if (counter == queue.length)
		{
			notifyComplete();
		}
	}

}

}