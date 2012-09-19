package lib.core.ui.layout
{

import flash.display.DisplayObject;
	

/**
 * Пустой лейаут - нет никакого выравнивания элементов
 */
public class AbsoluteLayout implements ILayout
{
	private var _width:Number=0;
	private var _height:Number=0;
	
	public function AbsoluteLayout () 
	{
	}

	public function arrange(c : Container) : void 
	{
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

