package lib.core.ui.controls
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;

import lib.core.ui.layout.ILayout;

/**
 * Навигатор скринов с таббаром.
 * Кеширует скрин по id, не пересоздает при повторном открытии.
 */
public class TabNavigator extends Sprite
{
	protected var modulesCache:Object = {};
	protected var _module:DisplayObject;
	protected var _moduleContainer:DisplayObjectContainer;

	protected var _tabBar:TabBar;
	protected var _stack:ViewStack;

	protected var _enabled:Boolean = true;
	public function get enabled():Boolean{
		return _enabled;
	}
	public function set enabled(value:Boolean):void{
		_enabled = value;
		tabBar.enabled = value;
	}

	public function TabNavigator(tabBarRenderer:Class=null, tabBarLayout:ILayout = null)
	{
		super();

		_tabBarRenderer = tabBarRenderer;
		_tabBarLayout = tabBarLayout;

		init();
		arrange();
	}

	protected function init():void
	{
		addChild(_stack = new ViewStack());
		addChild(_tabBar = new TabBar(tabBarRenderer, tabBarLayout));
		_moduleContainer = _stack.moduleContainer;

		tabBar.addEventListener(Event.SELECT, onTabs);
		onTabs();
	}

	/**
	 *	Рендерер для таббара
	 */
	protected var _tabBarRenderer:Class;
	public function get tabBarRenderer():Class
	{
		return _tabBarRenderer;
	}
	public function set tabBarRenderer(value:Class):void
	{
		_tabBarRenderer = value;
		if (tabBar)
			tabBar.itemRenderer = value;
		arrange();
	}

	/**
	 *	лайаут для таббара
	 */
	protected var _tabBarLayout:ILayout;
	public function get tabBarLayout():ILayout
	{
		return _tabBarLayout;
	}
	public function set tabBarLayout(value:ILayout):void
	{
		_tabBarLayout = value;
		if (tabBar)
			tabBar.layout = value;
		arrange();
	}

	/**
	 *	Массив объектов для инициализации табов. Обязательное поле id. Если передать поле <code>module<code>
	 *  то при выборе вкладки компонент сам создаст ребенка. Созданные дети кладутся в кеш и повторно не создаются.
	 * 	Из самого ребенка нужно слушать событие onAddedToStage, чтобы понять, что ребенка показали.
	 *  Пример:  [{id:"1", module:Object},{id:"2", module:Object}]
	 * @param value
	 *
	 */
	private var _dataProvider:Array;
	public function get dataProvider():Array
	{
		return _dataProvider;
	}
	public function set dataProvider(value:Array):void
	{
		_dataProvider = value;
		commitProperties();
	}

	protected function commitProperties():void
	{
		_stack.dataProvider = dataProvider;
		_tabBar.dataProvider = dataProvider;
		onTabs();
		arrange();
	}

	/**
	 *	Массив идентификаторов модулей.
	 *  Пример:  [{id:"1"},{id:"2"}]
	 */
	[Deprecated("use dataProvider instead")]
	public function set tabIds(value:Array):void
	{
	}

	public function get tabModulesMap():Object
	{
		return {};
	}
	[Deprecated("use dataProvider instead")]
	public function set tabModulesMap(value:Object):void
	{
	}

	public function selectTab(id:int):void{
		if (tabBar.dataProvider is Array){
			for (var i:int = 0; i< tabBar.dataProvider.length; i++){
				if (tabBar.dataProvider[i].hasOwnProperty("id") && tabBar.dataProvider[i].id == id){
					tabBar.selectedIndex = i;
					break;
				}
			}
		}
	}

	public function set selectedIndex(value:int):void
	{
		tabBar.selectedIndex = value;
	}

	public function get selectedIndex():int
	{
		return tabBar.selectedIndex;
	}

	protected var _selectedId:String;
	public function set selectedId(value:String):void
	{
		tabBar.selectedId = value;
	}
	public function get selectedId():String
	{
		return tabBar.selectedId;
	}

	public function arrange():void
	{
		moduleContainer.y = tabBar.y + tabBar.height;
	}

	public function get tabBar():TabBar
	{
		return _tabBar;
	}

	public function get module():DisplayObject
	{
		return _stack.module;
	}

	public function get moduleContainer():DisplayObjectContainer
	{
		return _moduleContainer;
	}

	protected function onTabs(event:ToggleGroupEvent = null):void
	{
		if (!enabled)
			return;

		_stack.selectedIndex = tabBar.selectedIndex;
	}
}
}