package lib.core.ui.list
{
import lib.core.ui.controls.SimpleList;
import lib.core.ui.layout.ILayout;
import lib.core.ui.layout.RowLayout;
import lib.core.ui.scroll.HorizontalScrollPaneToKill;

import flash.display.DisplayObject;
import flash.events.Event;

//[Deprecated("use HorizontalList")]
/**
 * SimpleList горизонтальной прокруткой, создает рендереры под всех детей, можно использовать для детей с переменной высотой
 * (с тремя кнопками горизонтальной прокрутки - поэлементно, постранично, на всю длину)
 * Usage:
 * 		var list:HorizontalList = new HorizontalList();
 * 		list.width = 400;
 * 		list.height = 80;
 * 		list.itemRenderer = MyItemRenderer;
 * 		list.dataProvider = [{id:1, label:1}, {id2:label2}]
 * 
 * TODO Заменить наследование от BaseScrollPane
 */
public class HorizontalSimpleList extends HorizontalScrollPaneToKill
{
	public static const EVENT_SCROLL_INDEX_CHANGED:String = "scrollIndexChanged";
	
	protected var _list:SimpleList;
	
	public function get list():SimpleList{return _list;}
	
	public var autoScrollOnDataChanged:Boolean = true;
	
	public function HorizontalSimpleList(layout:ILayout = null)
	{
		_layout = layout || new RowLayout(0, 0, 2);
		super();
	}
	
	override protected function init():void
	{
		super.init();
		
		_list = new SimpleList(layout);
		_list.itemRenderer = itemRenderer;
		content = _list;	
	}
	
	override protected function update() : void
	{
		super.update();
		
		if(_list)
		{
			_list.userHeight = height;
			_list.userWidth = width - 2*hSpacing - leftButtons.width - rightButtons.width;
		}
	}
	
	private var _dataProvider:*;
	/**
	 * Данные - Array или ItemSet
	 * @param value
	 * 
	 */
	public function set dataProvider (value:*):void
	{
		_dataProvider = value;
		commitProperties();
	}

	public function get dataProvider ():*
	{
		return _dataProvider;
	}
	
	private var _itemRenderer:Class;
	
	public function set itemRenderer(value:Class):void
	{
		if(_itemRenderer != value)
		{
			_itemRenderer = value;
			if(_list)
				_list.itemRenderer = value;
		}
	}
	
	public function get itemRenderer():Class
	{
		return _itemRenderer;
	}
	
	private var _layout:ILayout;
	
	public function set layout(value:ILayout):void
	{
		if(_layout != value)
		{
			_layout = value;
			if(_list)
				_list.layout = value;
		}
	}
	
	public function get layout():ILayout
	{
		return _layout;
	}
	
	protected function commitProperties():void 
	{
		if(_list)
		{
			_list.dataProvider = dataProvider;
			
			if(autoScrollOnDataChanged)
				horizontalScrollPosition = 0;
		}
	}
	
	public function scrollToIndex(index:uint):void
	{
		if (index > list.children.length - 1)
			return;
		
		//не скролимся, если первый элемент а мы уже в нуле.
		//if(horizontalScrollPosition == 0 && index == 0)
		//	return;
		
		var item:DisplayObject = list.children[index];	
		scrollToItem(item);
	}
	
	public function scrollToItem(item:DisplayObject):void
	{
		if (!item)
			return;
		
		horizontalScrollPosition = item.x - layout.settings.hPadding;
	}
	
	override protected function onTweenComplete(tween:Object = null):void 
	{
		super.onTweenComplete(tween);
		dispatchEvent(new Event(EVENT_SCROLL_INDEX_CHANGED));
	}
}
}