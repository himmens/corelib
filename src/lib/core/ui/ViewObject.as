package lib.core.ui
{
import lib.core.util.BindHelper;
import lib.core.util.FunctionUtil;

import flash.display.Sprite;
import flash.events.Event;

/**
 * Базовый визуальный объект.
 * Функционал:
 * 	1. автоматически вызывает методы onShow и onHide при добавлении и удаления со stage
 * 	2. автоматически вызывает методы bindProperties и unbindProperties при добавлении и удаления со stage
 * 	3. предоставляет методы биндинга с автоматическим складированием ватчеров в коллекцию.
 * 		Анбиндинг происходит автоматически при удалении со stage
 */
public class ViewObject extends Sprite
{
	protected var inited:Boolean = false;
	
	protected var _bindHelper:BindHelper;

	/**
	 * Флаг - находится на stage
	 * у флеша есть бага. когда событие onAdded кидаетяс два раза подряд, чтобы вызывать onShow и bindProperties один раз при добавлении
	 */ 
	private var withinStage:Boolean;
	
	public function ViewObject()
	{
		super();

		preInit();
	}

	private function preInit():void
	{
		if(!inited)
		{
			_bindHelper = new BindHelper();
			
			init();
			inited = true;

			onInited();

			if(stage) 
			{
				withinStage = true;
				onShow();
				bindProperties();
			}

			addEventListener(Event.ADDED_TO_STAGE, onStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onStage);
		}
	}

	private function onInitAdded(event:Event):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onInitAdded);

		preInit();
	}

	/**
	 * virtual (Переопределяется в наследниках)
	 *
	 * Инициализация объекта - создание детей, скинов, слушателей.
	 * Биндинг данных вызывать в методе bindProperties
	 *
	 */
	protected function init():void
	{
	}

	protected function onInited():void
	{
	}

	private function onStage(event:Event):void
	{
		if(event.type == Event.ADDED_TO_STAGE)
		{
			if (!withinStage) 
			{
				withinStage = true;
				unbindProperties();
				onShow();
				bindProperties();
			}
		}
		else
		{
			if (withinStage)
			{
				withinStage = false;
				onHide();
				unbindProperties();
			}
		}
	}
	/**
	 * virtual (Переопредляется в наследниках)
	 *
	 * Все биндинги прописывать в этом методе в наследниках, при этом
	 * все ChangeWatcher склдывать в массив _watchers, чтобы сработал автоматический
	 * unwatch при удалеении со сцены.
	 */
	protected function onShow():void
	{

	}

	protected function onHide():void
	{

	}

	/**
	 * Биндиться через эти методы
	 * @param site
	 * @param prop
	 * @param host
	 * @param chain
	 *
	 */
	protected function bindProperty(site:Object, prop:String, host:Object, chain:Object):void
	{
		_bindHelper.bindProperty(site, prop, host, chain);
	}

	/**
	 * Биндиться через эти методы
	 * @param setter
	 * @param host
	 * @param chain
	 *
	 */
	protected function bindSetter(setter:Function, host:Object, chain:Object):void
	{
		_bindHelper.bindSetter(setter, host, chain);
	}

	/**
	 *
	 *
	 */
	protected function unbindProperties():void
	{
		_bindHelper.unbindProperties();
	}

	/**
	 * Переопределяется в наследниках дял связывания с датой
	 *
	 */
	protected function bindProperties():void
	{
	}

	protected var _width:Number;
	override public function set width(value:Number):void{if(width != value){_width = value; arrange()}}
	override public function get width():Number{return _width ? _width : super.width;}
	
	protected var _height:Number;
	override public function set height(value:Number):void{if(height != value){_height = value; arrange()}}
	override public function get height():Number{return _height ? _height : super.height;}
	
	protected function arrange():void
	{
		arrangeLaterFlag = false;
	}
	
	protected var arrangeLaterFlag:Boolean;
	protected function arrangeLater():void
	{
		arrangeLaterFlag = true;
		FunctionUtil.callLater(arrange);
	}
	
	protected function arrangeLaterCall():void
	{
		if(arrangeLaterFlag)
		{
			arrange();
		}
	}
}
}
