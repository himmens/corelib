package lib.core.command
{

import flash.events.Event;
import flash.events.ProgressEvent;

/**
* выполнена одна из команд в очереди,
 * общее число команд лежит в ProgressEvent.bytesTotal
 * выполненное число команд лежит в ProgressEvent.bytesLoaded
 * последняя выполненная команда доступна по ссылке QueueCommand.completedCommand
*/
[Event (name="progress", type="flash.events.ProgressEvent")]
/**
 * выполнена одна из команд в очереди,
 * последняя выполненная команда доступна по ссылке QueueCommand.completedCommand
*/
[Event (name="commandComplete", type="flash.events.Event")]
/**
 * команда для последовательного выполнения группы команд
 */
public class QueueCommand extends Command
{
	public static const COMMAND_COMPLETE:String = "commandComplete";

	public var queue:Array = [];

	private var _completedCommand:Command;
	public function get completedCommand():Command{return _completedCommand;}

	protected var _runningCommand:Command = null;
	public function get runningCommand():Command{return _runningCommand;}

	protected var total:int;
	protected var dispatchProgress:Boolean = true;

	/**
	 * @param commands одна или несколько команд-параметров
	 */
	public function QueueCommand (...commands)
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
					queue[queue.length] = c;
				}
			}
		}
	}

	/**
	 * Добавляем командув очередь выполнения.
	 * Выполнится автоматически по достижению очереди.
	 * @param c
	 */
	public function add (c:Command):Command
	{
		queue[queue.length] = c;
		_complete = false;
		return c;
	}
	/**
 	 * Добавляем команды очередь выполнения.
	 * Выполняются автоматически последовательно по достижению очереди.
	 * @param arr
	 */
	public function addList (arr:Array):void
	{
		queue = queue.concat(arr);
		_complete = false;
	}

	override protected function execInternal ():void
	{
		total = queue.length;

		run();
	}

	protected function run ():void
	{
		if(complete)
			return;

		if (queue.length > 0)
		{
			if(!_runningCommand)
			{
				var c:Command = Command (queue.shift());
				_runningCommand = c;
				c.addEventListener(Event.COMPLETE, onCommandComplete, false,0,true);
				c.execute();
			}
		}
		else
		{
			if(!_runningCommand)
				notifyComplete();
		}
	}

	protected function onCommandComplete (e:Event):void
	{
		_completedCommand = _runningCommand;
		_runningCommand.removeEventListener(Event.COMPLETE, onCommandComplete);
		_runningCommand = null;

		dispatchEvent(new Event(COMMAND_COMPLETE));
		if(dispatchProgress)
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, total-queue.length, total));

		run();
	}

	/**
	 * доделываем текущую команду и прекращаем
	 */
	override internal function reset ():void
	{
		queue = [];
		super.reset();
	}

	override public function terminate ():void
	{
		reset();
		if (runningCommand)
		{
			runningCommand.removeEventListener(Event.COMPLETE, onCommandComplete);
			runningCommand.terminate();
		}
		super.terminate();
	}
	
	/**
	 * Удаляет комманду из очереди
	 * @param cmd
	 * 
	 */	
	public function removeCommand(cmd:Command):void
	{
		queue.splice(queue.indexOf(cmd), 1);
		total--;
//		if (cmd.executing)
			cmd.terminate();
	}

}
}