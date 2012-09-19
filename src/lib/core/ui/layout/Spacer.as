package lib.core.ui.layout
{
import flash.display.Sprite;

public class Spacer extends Sprite
{
	public function Spacer(width:Number = 0, height:Number = 0)
	{
		_width = width;
		_height = height;
		
		super();
	}
	
	protected function draw():void
	{
		graphics.clear();
		
		if(fill)
		{
			graphics.lineStyle(fill.lineThickness, fill.borderColor, fill.borderAlpha);
			graphics.beginFill(fill.fillColor, fill.fillAlpha);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();
		}
	}
	
	private var _height:Number;
	override public function set height (value:Number):void
	{
		if(_height != value)
		{
			_height = value;
			draw();
		}
	}
	
	override public function get height ():Number
	{
		return _height;
	}
	
	private var _width:Number;
	override public function set width (value:Number):void
	{
		if(_width != value)
		{
			_width = value;
			draw();
		}
	}
	
	override public function get width ():Number
	{
		return _width;
	}
	

	private var _fill:Object;
	/**
	 * 
	 * @param value заливка в формате {fillColor:0xFF0000, fillAlpha:1, borderColor:0xFF0000, borderAlpha:1, lineThickness:0}
	 * 
	 */
	public function set fill (value:Object):void
	{
		_fill = value;
		if(isNaN(fill.fillColor)) fill.fillColor = 0x000000;
		if(isNaN(fill.fillAlpha)) fill.fillAlpha = 1;
		if(isNaN(fill.borderColor)) fill.borderColor = 0x000000;
		if(isNaN(fill.borderAlpha)) fill.borderAlpha = 1;
		if(isNaN(fill.lineThickness)) fill.lineThickness = 0;
		
		draw();
	}

	public function get fill ():Object
	{
		return _fill;
	}

}
}