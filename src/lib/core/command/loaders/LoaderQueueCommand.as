package lib.core.command.loaders
{
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.TimerEvent;
import flash.utils.Dictionary;
import flash.utils.Timer;

import lib.core.command.Command;
import lib.core.command.QueueCommand;

[Event (name="progress", type="flash.events.ProgressEvent")]
[Event (name="complete", type="flash.events.Event")]

/**
* 	Менеджер
 * 		-организует последовательную очередь загруки (элементы очереди LoaderCommand-ы должны кидать события progress и complete (или ioError, securityError)),
 * 		-кидает общее событие progress и complete для всей очереди.
*/
public class LoaderQueueCommand extends QueueCommand
{
	/**
	 * как часто тикает файковый таймер
	 */
	public var fakeTime:int = 400;
	public var fakeStepDefault:Number = .01;

	/**
	 * Можно указать начальный прогресс, тогда команда пропорционально уменьший свой общий прогресс
	 * например если указать initialProgress = 0.1, команда начнет кидать прогресс с 0.1 до 1, "сжав" свой общий прогресс до 0.9
	 *
	 */
	public var initialProgress:Number = 0;

	protected var progressScale:Number = 1;

	protected var _map:Dictionary = new Dictionary(true);

	//доля текущего загрузчика
	protected var _runningPercent:Number = 0;
	//прогресс текущего загрузчика
	protected var _runningProgress:Number = 0;
	//текущий файковый шаг
	protected var _runningFakeStep:Number = .01;

	//Текущий прогресс загрузки, от 0 до 1
	protected var _totalProgress:Number = 0;

	protected var _fakeTimer:Timer;

	public function LoaderQueueCommand(...commands)
	{
		dispatchProgress = false;

		super(commands);
	}

	/*
	 *
	 public API
	 */

	/**
	 * Текущий прогресс загрузки, от 0 до 1, округленный до 0.00001
	 * @return
	 *
	 */
	public function get progress():Number
	{
		return Math.ceil(10000 * (_totalProgress + _runningProgress))/10000;
	}

	/**
	 * Добавить загрузчик в очередь
	 * @param command - загрузчик с событиями progress, complete (вместо complete так же обрабатывается ioError, securityError)
	 * @param percents часть от общей длины (единица), сколько должен грузится данный загрузчик, например .2
	 * 					-1 означает, что % будут посчитанны автоматически послсе вызова execute
	 * @param fake поставить флаг, если loader не кидает событие progress, тогда будет отображаться фейковый прогресс для данного загрузчика по таймеру
	 * @param fake_step на сколько тикать фейковому прелоадеру на каждое событие таймера @see fakeTime
	 *
	 */
	public function addLoader(command:Command, percents:Number = -1, fake:Boolean = false, fake_step:Number = 0):void
	{
		if(!_map[command])
		{
			super.add(command);
			_map[command] = {percents:percents, fake:fake, fake_step:fake_step || fakeStepDefault};

			//run();
		}
	}

	override protected function execInternal():void
	{
		_totalProgress = initialProgress;
		checkPercents();
		notifyProgress();

		super.execInternal();
	}

	protected function notifyProgress():void
	{
		//файковые данные, чтобы был верный прогресс
		var fakeTotal:int = 10000;
		var fakeLoaded:int = progress*fakeTotal;
		dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, fakeLoaded, fakeTotal));
	}

	/**
	 * Проверяем, что все команды имею свой ненулевой %, если % не стоит равномерно разбиваем по всем командам незанятые %
	 *
	 */
	protected function checkPercents():void
	{
		var total:Number = _totalProgress;
		var marked:Array = [];
		var obj:Object;
		var cmd:Command;

		for each(cmd in queue)
		{
			obj = _map[cmd] || {percents:-1};
			_map[cmd] = obj;

			if(obj.percents == -1)
				marked[marked.length] = obj;
			else
				total+=Number(obj.percents);
		}

		//незантый % распределяем равномерно по каждому загручику
		var free:Number = 1 - total;
		if(marked.length > 0)
		{
			var percent:Number = free/marked.length;
			for each(obj in marked)
				obj.percents = percent;
		}
	}
	/*
	 *
	 protected methods
	 */

	override protected function run():void
	{
		if(complete)
			return;

		if (!runningCommand && queue.length > 0)
		{
			_runningCommand = queue.shift() ;
			var data:Object = _map[runningCommand];
			_runningPercent = data.percents;

			//команда уже загрузилась, выполняем следующую
			if(runningCommand.complete)
			{
				removeCompletedLoader(runningCommand);
				run();
			}else
			{
				runningCommand.addEventListener(Event.COMPLETE, onCommandComplete, false, 0, true);

				if(data.fake)
				{
					_runningFakeStep = data.fake_step;
					if(!_fakeTimer)
					{
						_fakeTimer = new Timer(fakeTime);
						_fakeTimer.addEventListener(TimerEvent.TIMER, onFakeTimer);
					}
					_fakeTimer.start();
				}else
				{
					runningCommand.addEventListener(ProgressEvent.PROGRESS, onLoaderProgress, false, 0, true);
				}

				runningCommand.execute();
			}
		}
		else
		{
			if(progress >= 1 || queue.length == 0)
				notifyComplete();
		}
	}

	protected function removeCompletedLoader(loader:Command):void
	{
		if(loader)
		{
			_totalProgress += _runningPercent;

			delete _map[loader];

			loader.removeEventListener(Event.COMPLETE, onCommandComplete);
			loader.removeEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
		}
	}

	/*
	 *
		Handlers
	 */
	protected function onFakeTimer(event:Event):void
	{
		if(_runningProgress < _runningPercent)
		{
			_runningProgress += _runningFakeStep;
			notifyProgress();
		}else
		{
			_fakeTimer.stop();
		}
	}

	protected function onLoaderProgress(event:ProgressEvent):void
	{
		//иногда при кривых заголовках event.bytesTotal равен нулю, чотбы прогресс не уходил в бесконечность ограничиваемего единицей
		var progress:Number = Math.min(event.bytesLoaded/event.bytesTotal, 1);
		_runningProgress = _runningPercent*progress;
		notifyProgress();
	}

//	protected function onLoaderError(event:ErrorEvent):void
//	{
//		removeLoader(event.target as EventDispatcher);
//		run();
//	}

	override protected function onCommandComplete(event:Event):void
	{
		if(_fakeTimer)
			_fakeTimer.stop();

		var loader:Command = event.target as Command;
		removeCompletedLoader(loader);
		_runningProgress = 0;
		notifyProgress();
		

		super.onCommandComplete(event);
	}

}
}