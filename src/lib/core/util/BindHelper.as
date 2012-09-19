package lib.core.util
{
import flash.events.Event;
import flash.events.EventDispatcher;

import mx.binding.utils.BindingUtils;
import mx.binding.utils.ChangeWatcher;

/**
 * Утилитный класс, для удобного биндинга с возможность unbind
 * Функционал:
 * 	1. предоставляет методы биндинга с автоматическим складированием вотчеров в коллекцию.
 * 	2. вызывает методы биндинга при добавлени/удалении со stage - (displayProxy || callbackProxy).bindProperties
 *
 * @author fsb
 *
 */
public class BindHelper
{
	/**
	 * массив ChangeWatcher
	 */
	protected var _watchers:Array = [];

	protected var displayProxy:EventDispatcher;
	protected var callbackProxy:Object;

	/**
	 * 
	 * @param displayProxy диспатчер событий добавления/удаления из Displaylist для автоматического bind/unbind
	 * @param callbackProxy объект. у которого будет автоматически дергаться метод bindProperties при добавлени на stage
	 * 
	 */
	public function BindHelper(displayProxy:EventDispatcher = null, callbackProxy:Object = null)
	{
		this.displayProxy = displayProxy;
		this.callbackProxy = callbackProxy || displayProxy;
		init();
	}

	protected function init():void
	{
		if(displayProxy)
		{
			displayProxy.addEventListener(Event.ADDED_TO_STAGE, onStage, false, 0, true);
			displayProxy.addEventListener(Event.REMOVED_FROM_STAGE, onStage, false, 0, true);
		}
	}

	private function onStage(event:Event):void
	{
		if(event.type == Event.ADDED_TO_STAGE)
		{
			//у флеша есть бага. когда событие onAdded кидаетяс два раза подряд, поэтому всегда перед вызовом bind делаем unbind, чотбы гарантировать
			//биндинг с чистого листа
			unbindProperties();

			bindProperties();
		}
		else
		{
			unbindProperties();
		}
	}

	public function clearProxy():void
	{
		displayProxy.removeEventListener(Event.ADDED_TO_STAGE, onStage, false);
		displayProxy.removeEventListener(Event.REMOVED_FROM_STAGE, onStage, false);
	}

	/**
	 * Обертка на стандартный BindingUtils.bindProperty
	 * @param site
	 * @param prop
	 * @param host
	 * @param chain
	 *
	 */
	public function bindProperty(site:Object, prop:String, host:Object, chain:Object):ChangeWatcher
	{
		var watcher:ChangeWatcher = BindingUtils.bindProperty(site, prop, host, chain);
		_watchers[_watchers.length] = watcher

		return watcher;
	}

	/**
	 * Обертка на стандартный BindingUtils.bindSetter
	 * @param setter
	 * @param host
	 * @param chain
	 *
	 */
	public function bindSetter(setter:Function, host:Object, chain:Object):ChangeWatcher
	{
		var watcher:ChangeWatcher = BindingUtils.bindSetter(setter, host, chain);
		_watchers[_watchers.length] = watcher

		return watcher;
	}

	/**
	 *
	 *
	 */
	public function unbindProperties():void
	{
		for each(var watcher:ChangeWatcher in _watchers)
		{
			watcher.unwatch();
		}
		_watchers = [];
	}

	/**
	 * Переопределяется в наследниках дял связывания с датой
	 *
	 */
	public function bindProperties():void
	{
		if(callbackProxy && ("bindProperties" in callbackProxy))
			callbackProxy["bindProperties"]();
	}

}
}