package lib.core.ui.controls
{
import lib.core.data.ItemSet;
import lib.core.ui.layout.ILayout;
import lib.core.ui.layout.RowLayout;

import flash.display.DisplayObject;
import flash.events.Event;

[Event (name="select", type="flash.events.Event")]

public class TabBar extends SimpleList
{
	protected var group:ToggleGroup;

	public var firstButtonRenderer:Class = null;
	public var lastButtonRenderer:Class = null;

	public var autoSelectFirst:Boolean = true;

	/**
	 * Функция получения метки по обьекту данных.
	 * Назначить необходимо перед dataProvider-ом.
	 *
	 * Пример:
	 * 		function(data:Object):String{return data.label}
	 */
	public var labelFunction:Function;

	protected var _enabled:Boolean = true;
	public function get enabled():Boolean{
		return _enabled;
	}
	public function set enabled(value:Boolean):void{
		_enabled = value;
		for each (var b:ToggleButton in children)
		{
			b.enabled = value;
		}
	}

	public function TabBar(itemRenderer:Class = null, layout:ILayout = null)
	{
		super(layout || new RowLayout(0, 0, 2));

		this.itemRenderer = itemRenderer || TabButton;
		init();
	}

	override protected function commitProperties():void
	{
		if(dataProviderChanged)
		{
			if(!autoSelectFirst)
				group.canBeUnselected = true;

			super.commitProperties();
			group.canBeUnselected = false;

//			removeAll();
//			group.removeAll();
//
//			if(dataProvider)
//			{
//				var child:DisplayObject;
//				var data:Object;
//				for (var i:int=0; i<dataProvider.length; i++)
//				{
//					data = dataProvider[i];
//
//					child = createItemRenderer(data);
//					if(child)
//					{
//						add(child);
//					}
//
//					//данные назначаем после добавления
//					if(child && child.hasOwnProperty("data"))
//						child["data"] = data;
//
//					if(child && child.hasOwnProperty("labelFunction"))
//						child["labelFunction"] = labelFunction;
//
//					if(!autoSelectFirst)
////						group.removeEventListener(ToggleGroupEvent.SELECT, onButtonSelect);
//						group.canBeUnselected = true;
//
//					group.add(child as ToggleButton);
//				}
//			}
//
////			group.addEventListener(ToggleGroupEvent.SELECT, onButtonSelect);
//			group.canBeUnselected = false;
//			arrange();
		}
	}

	override public function add(o:DisplayObject, index:int=int.MAX_VALUE):DisplayObject
	{
		super.add(o, index);
		return o;
	}

	override protected function setChildData(child:DisplayObject, data:Object=null):void
	{
		super.setChildData(child, data);
		group.add(child as ToggleButton);
		
		if(data && (labelFunction != null) && child is LabelButton)
		{
			(child as LabelButton).label = labelFunction(data);
			(child as LabelButton).arrange();
		}
	}

	override public function remove(o:DisplayObject):DisplayObject
	{
		super.remove(o);

		group.remove(o as ToggleButton);
		return o;
	}

	public function get selected():Object
	{
		return group && group.selected ? ToggleButton(group.selected).data : null;
	}

	public function set selectedIndex(value:int):void
	{
		if(selectedIndex != value)
		{
			var btn:ToggleButton = children[value];
			group.selected = btn;
		}
	}

	public function get selectedIndex():int
	{
		return group.selected ? children.indexOf(group.selected) : -1;
	}

	public var idPropName:String = "id";
	public function set selectedId(value:String):void
	{
		if(selectedId != value)
		{
			var dataArray:Array = (dataProvider is ItemSet) ? ItemSet(dataProvider).toArray() : dataProvider as Array;
			if(dataArray)
			{
				for(var i:int=0; i<dataArray.length; i++)
				{
					if(String(dataArray[i][idPropName]) == value)
					{
						selectedIndex = i;
						break;
					}
				}
			}
		}
	}
	public function get selectedId():String
	{
		return selected ? selected[idPropName] : null;
	}

	protected function init():void
	{
		group = new ToggleGroup();
		group.canBeUnselected = false;
		group.addEventListener(ToggleGroupEvent.SELECT, onButtonSelect);
	}

	protected function onButtonSelect(event:ToggleGroupEvent):void
	{
		if (!enabled)
			return;

		//не смотрим на button.enabled т.к. даже в задизабленном состоянии кнопка может оказаться выделенной (например группой)
//		if(group.selected && group.selected.enabled)
		if(group.selected)
			dispatchEvent(event);
	}

	override protected function createItemRenderer(data:Object):DisplayObject
	{
		var dataArray:Array = (dataProvider is ItemSet) ? ItemSet(dataProvider).toArray() : dataProvider as Array;
		if(!dataArray)
			return null;

		var index:int = dataArray.indexOf(data);
		if(index == 0 && firstButtonRenderer)
			return new firstButtonRenderer()
		else if(index == dataProvider.length-1 && lastButtonRenderer)
			return new lastButtonRenderer();
		else
			return super.createItemRenderer(data);
	}
}
}