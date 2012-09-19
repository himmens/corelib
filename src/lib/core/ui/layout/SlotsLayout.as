package lib.core.ui.layout
{

import flash.display.DisplayObject;
	

/**
 * Лайтаут по слотам - переданному массиву объектов с координатами (x, y)
 */
public class SlotsLayout implements ILayout
{
	private var _width:Number=0;
	private var _height:Number=0;
	
	public var slots:Array;
	
	public var hideExcessesChildren:Boolean = true;
	public var hideSlot:Boolean = true;
	public var precisePos:Boolean = true;
	
	/**
	 * 
	 * @param slots массив слотов  - любые объекты с пропертями (x,y)
	 * @param hideSlot - прятать слот (visible = false)
	 * @param hideExcessesChildren - прятать лишних детей или нет (для которых нет слотов) через поле visible
	 * @return 
	 * 
	 */
	public function SlotsLayout (slots:Array = null, hideSlot:Boolean = true, hideExcessesChildren:Boolean = true) 
	{
		this.slots = slots;
		this.hideExcessesChildren = hideExcessesChildren;
		this.hideSlot = hideSlot;
	}

	public function arrange(c : Container) : void 
	{
		var slot:Object;
		var child:DisplayObject;
		var len:int = slots.length;
		
		for(var i:int = 0; i < len; i++)
		{
			slot = slots ? slots[i] : null;
			child = c.children[i];
			
			if(slot)
			{
				if(child)
				{
					child.visible = true;
					child.x = precisePos ? int(slot.x) : slot.x;
					child.y = precisePos ? int(slot.y) : slot.y;
				}
				slot.visible = !hideSlot;
			}else if(child)
			{
				child.visible = hideExcessesChildren;
			}
		}
	}
	
	public function get width():Number
	{
		return _width;
	}
	
	public function get height():Number
	{
		return _height;
	}

	public function get settings():LayoutSettings
	{
		return new LayoutSettings();
	}
}	
	
}

