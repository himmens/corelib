package lib.core.command
{
import lib.core.AppErrorCodes;
import lib.core.util.log.Logger;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Timer;
import flash.utils.getQualifiedClassName;

/**
 * Простая реализация команды.
 */
[Event (name="complete", type="flash.events.Event")]
//[Event (name="error", type="flash.events.ErrorEvent")]
public class Command extends EventDispatcher
{
	/**
	 * Код ошибки
	 */
	protected var _errorCode:int = AppErrorCodes.NO_ERROR;
	public function get errorCode():int{return _errorCode}
	public function get success():Boolean{return errorCode == AppErrorCodes.NO_ERROR}
	
	/**
	 * Динамические данные ассоциированные с командой.
	 * Можно использовать для передачи информации в complete обработчик.
	 */
	public var data:Object;

	/**
	 * Кеш против удаления команд GC-ом на этапе выполнения
	 */
	private static var cache:Array = [];

	protected var _complete:Boolean;
	/**
	 * Выполнена ли команда.
	 */
	public function get complete ():Boolean{return _complete;}

	protected var _executing:Boolean;
	/**
	 * Работает ли команда
	 */
	public function get executing ():Boolean{return _executing;}


	/**
	 * макс. время выполнения команды (мсек)
	 */
	protected var _timeOut:uint = 0;
	public function get timeOut():uint
	{
		return _timeOut;
	}

	public function set timeOut(value:uint):void
	{
		_timeOut = value;
		if (timer)
			timer.delay = _timeOut;
	}

	private var timer:Timer = new Timer(timeOut, 1);

	public function Command()
	{
	}

	/**
	 * virtual
	 *
	 * Получаем доступ к нужному нам сервису и шлём реквест
	 */
	final public function execute ():void
	{
		//повторный вызов execute у работающйе или уже отработавшей команды игнорируется
		if(executing || complete)
			return;

		_executing = true;

		// кешируем команду
		if (cache.indexOf(this)==-1)
		{
			cache.push(this);
		}

//		try
//		{
			execInternal();
//		}catch(error:Error)
//		{
//			var event:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR);
//			event.text = error.message;
//			dispatchEvent(event);
//
//			Logger.error(this, error.getStackTrace());
//			//if(!event.isDefaultPrevented())
//			//	terminate();
//		}

		if (timeOut > 0)
		{
			startTimout();
		}
	}

	/**
	 * вынесено в отдельную функцию, чтобы была возможность переопределить время запуска таймера в случае
	 * кастомного порялке запуска команд, например если все команды определнного типа встраивают в очередь
	 * сами себя.
	 *
	 */
	protected function startTimout():void
	{
		timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimeout);
		timer.start();
	}

	/**
	 * Возможность остановить таймер.
	 */
	protected function stopTimout():void
	{
		timer.stop();
	}

	/**
	 * Возможность сбросить таймер.
	 */
	protected function resetTimout():void
	{
		timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimeout);
		timer.reset();
	}

	/**
	 * сбросить команду. После вызова этого метода возможен повторный запуск команды execute()
	 */
	internal function reset():void
	{
		resetTimout();
		_complete = false;
	}

	/**
	 * virtual
	 *
	 * Переопределяется в наследниках для выполнения команды
	 */
	protected function execInternal ():void
	{

	}

	/**
	 * для команд, которые не требуют вызова сервиса, дергаем метод вручную
	 */
	protected function notifyComplete ():void
	{
		_executing = false;

		if(!complete)
		{
			// убираем из кеша
			var index:int = cache.indexOf(this);
			if (index > -1)
			{
				cache.splice(index, 1);
			}

			if (timer.running)
				resetTimout();

			_complete = true;
			// шлём событие окончания выполнения команды
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}

	/**
	 * Обрываем выполнение команды
	 */
	public function terminate ():void
	{
		notifyComplete();
	}

	protected function onTimeout(event:Event):void
	{
		if(!complete) {
			Logger.debug(this, "Execution time has expired");
			_errorCode = AppErrorCodes.TIMEOUT_EXPIRED;
			terminate();
		}
	}

	override public function toString ():String
	{
		var name:String = getQualifiedClassName(this);
		return name.split("::")[1]+"::";
	}
}
}