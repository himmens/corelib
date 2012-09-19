package lib.core.ui.controls
{
import lib.core.data.ItemSet;
import lib.core.ui.layout.ILayout;
import lib.core.ui.layout.RowLayout;

import flash.display.DisplayObject;
import flash.events.Event;

[Event (name="select", type="flash.events.Event")]

public class ButtonBar extends SimpleList
{
	public var group:ToggleGroup;

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

	public function ButtonBar(itemRenderer:Class = null, layout:ILayout = null)
	{
		super(layout || new RowLayout(0, 0, 2));

		this.itemRenderer = itemRenderer || TabButton;
		init();
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

	public function set selected(value:Object):void
	{
		group.selectedValue = value;
	}
	
	public function get selected():Object
	{
		return group.selectedValue
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
		group.canBeUnselected = true;
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

}
}