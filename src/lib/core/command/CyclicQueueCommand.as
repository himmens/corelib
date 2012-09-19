package lib.core.command
{
import flash.events.Event;

import lib.core.command.Command;
import lib.core.command.QueueCommand;

/**
* Зацикленная очередь команд (бесконечная команда)
*/
public class CyclicQueueCommand extends QueueCommand
{
	private var index:int = -1;

	public function CyclicQueueCommand (commands:Array)
	{
		super(commands);
	}

	override protected function run ():void
	{
		if (!_runningCommand && queue.length > 0)
		{
			index++;
			if (index >= queue.length)
				index = 0;
			var c:Command = Command(queue[index]);
			_runningCommand = c;
			c.addEventListener(Event.COMPLETE, onCommandComplete, false,0,true);
			c.reset();
			c.execute();
		}
	}
}
}