package lib.core.ui.controls
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;

import lib.core.util.ArrayUtils;

[Event(name="change", type="flash.events.Event")]
/**
 * Стек экрано
 * Кеширует скрин по id, не пересоздает при повторном открытии.
 */
public class ViewStack extends Sprite
{
	protected var modulesCache:Object = {};
	protected var _module:DisplayObject;
	protected var _moduleContainer:Sprite;

	public var autoSelectFirst:Boolean = false;

	public function ViewStack()
	{
		super();
		init();
	}

	protected function init():void
	{
		addChild(_moduleContainer = new Sprite());
	}

	protected var _dataProvider:Array;
	/**
	 *	Массив объектов для инициализации табов. Обязательное поле id. Если передать поле <code>module<code>
	 *  то при выборе вкладки компонент сам создаст ребенка. Созданные дети кладутся в кеш и повторно не создаются.
	 * 	Из самого ребенка нужно слушать событие onAddedToStage, чтобы понять, что ребенка показали.
	 *
	 * Пример:  [{id:"1", module:Object}]
	 * 		module - DisplayObject или Class
	 * @param value
	 *
	 */
	public function set dataProvider(value:Array):void
	{
		_dataProvider = value;
		commitData();
	}
	public function get dataProvider():Array
	{
		return _dataProvider;
	}

	protected function commitData():void
	{
		if(autoSelectFirst)
			commitSelectedIndex();
	}

	protected var _selectedIndex:int;
	public function set selectedIndex(value:int):void
	{
		if(_selectedIndex != value)
		{
			_selectedIndex = value;
			commitSelectedIndex();
		}
	}
	public function get selectedIndex():int
	{
		return _selectedIndex;
	}

	public var idPropName:String = "id";

	protected var _selectedId:String;
	public function set selectedId(value:String):void
	{
		if(_selectedId != value)
		{
			_selectedId = value;
			if(dataProvider)
			{
				_selectedIndex = -1;
				for(var i:int=0; i<dataProvider.length; i++)
				{
					if(String(dataProvider[i].id) == value)
					{
						_selectedIndex = i;
						break;
					}
				}

				commitSelectedIndex();
			}
		}
	}
	public function get selectedId():String
	{
		return _selectedId;
	}

	override public function get height():Number
	{
		return _module ? _module.height : super.height;
	}
	
	public function arrange():void
	{
	}

	public function get module():DisplayObject
	{
		return _module;
	}

	public function get moduleContainer():DisplayObjectContainer
	{
		return _moduleContainer;
	}

	protected function commitSelectedIndex():void
	{
		var data:Object = dataProvider && dataProvider[selectedIndex];
		if (data)
			setContent(data.id, data.module);
		else
			setContent(null, null);

		dispatchEvent(new Event(Event.CHANGE));
	}

	protected function setContent(id:String, module:Object):void
	{
		if (_module && _module.name != ("module" + id) && moduleContainer.contains(_module))
			moduleContainer.removeChild(_module);

		if(!module)
			return;

		_module = modulesCache[id];
		if (!_module)
		{
			if (module is Class)
			{
				_module = moduleContainer.addChild(new module()) as DisplayObject;
			}else
			{
				_module = module as DisplayObject;
			}
			modulesCache[id] = _module;
			_module.name = "module" + id;
		}

		if (_module)
		{
			moduleContainer.addChild(_module);
		}
	}
}
}