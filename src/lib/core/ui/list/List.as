package lib.core.ui.list
{
import lib.core.ui.controls.SimpleList;
import lib.core.ui.layout.ColumnLayout;
import lib.core.ui.layout.ILayout;
import lib.core.ui.scroll.ScrollPaneToKill;

import flash.display.DisplayObject;

[Deprecated("use VerticalListWithButtons")]
/**
 * Базовый лист с вертикальной прокруткой
 * 		var list:List = new List();
 * 		list.width = 80;
 * 		list.height = 400;
 * 		list.itemRenderer = MyItemRenderer;
 * 		list.dataProvider = [{id:1, label:1}, {id2:label2}]
 */
public class List extends ScrollPaneToKill
{
	protected var _list:SimpleList;
	
	public function List()
	{
		super();
		init();
	}
	
	override protected function init():void
	{
		super.init();
		
		_list = createList();
		if (_list) {
			addChild(_list);
			content = _list;
		}
	}
	
	protected function createList():SimpleList
	{
		var list:SimpleList = new SimpleList(layout || new ColumnLayout(0, 0, 0));
		if (itemRenderer)
			list.itemRenderer = itemRenderer;
		return list;
	}
	
	public function get list():SimpleList {
		return _list;
	}
	
	private var _dataProvider:*;
	public function get dataProvider ():*
	{
		return _dataProvider;
	}
	public function set dataProvider (value:*):void
	{
		_dataProvider = value;
		commitProperties();
	}
	
	private var _itemRenderer:Class;
	public function get itemRenderer():Class
	{
		return _itemRenderer;
	}
	public function set itemRenderer(value:Class):void
	{
		if(_itemRenderer != value)
		{
			_itemRenderer = value;
			if(list)
				list.itemRenderer = value;
		}
	}
	
	private var _layout:ILayout;
	public function get layout():ILayout
	{
		return _layout;
	}
	public function set layout(value:ILayout):void
	{
		if(_layout != value)
		{
			_layout = value;
			if(list)
				list.layout = value;
		}
	}
	
	/**
	 * Скролить до элемента с индексом
	 */ 
	public function scrollToIndex(index:uint):void
	{
		if (index > list.children.length - 1)
			return;
		
		var item:DisplayObject = list.children[index];	
		scrollToItem(item);
	}
	
	/**
	 * Скролить до элемента
	 */
	public function scrollToItem(item:DisplayObject):void
	{
		if (!item)
			return;
		
		verticalScrollPosition = item.y;
	}
	
	override public function set width(value:Number):void {
		super.width = value;
		if (list)
			list.userWidth = value;
	}
	
	override public function set height(value:Number):void {
		super.height = value;
		if (list)
			list.userHeight = value;
	}
	
	/**
	 * Назначаем данные листу
	 */
	protected function commitProperties():void 
	{
		if(list && dataProvider) {
			list.dataProvider = dataProvider;
			verticalScrollPosition = 0;
		}
	}
}
}