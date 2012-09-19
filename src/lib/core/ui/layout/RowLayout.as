package lib.core.ui.layout
{

import flash.display.DisplayObject;

/**
 * распологает элементы в строку
 * [пока только слева направо]
 */
public class RowLayout implements ITableLayout
{
	public var hSpacing : Number;
	public var vPadding : Number;
	public var hPadding : Number;
	public var align : String;
	public var valign : String;

	protected var _width:Number=0;
	protected var _height:Number=0;

	/**
	 * @param hPadding отступ слева и справа от контента
	 * @param vPadding отступ сверху и снизу от контента
	 * @param hSpacing горизонтальный отступ между элементами
	 */
	public function RowLayout (	hPadding:Number=0,
								vPadding:Number=0,
								hSpacing:Number=0,
								align:String=Align.LEFT,
								valign:String=Valign.TOP)
	{
		this.hPadding = hPadding;
		this.vPadding = vPadding;
		this.hSpacing = hSpacing;
		this.align = align;
		this.valign = valign;
	}

	public function arrange(c : Container) : void
	{
		var child:DisplayObject;

		_width = hPadding;
		_height = vPadding*2;

		var tmpHeight:Number = 0;
		var delta:int;

		for (var i : uint = 0; i < c.children.length; i++)
		{
			child = DisplayObject (c.children[i]);
			child.x = Math.round(_width);
			_width += child.width + hSpacing;

			tmpHeight = child.height + 2*vPadding;
			if (tmpHeight > _height)
				_height = tmpHeight;
		}
		_width = _width - hSpacing + hPadding;

		// set align
		var containerWidth:Number = c.userWidth || c.width;
		//var containerWidth:Number = c.width;
		if (containerWidth != 0)
		{
			delta = 0;
			if (align == Align.CENTER)
				delta = (containerWidth - _width)/2;
			else if (align == Align.RIGHT)
				delta = Math.ceil(containerWidth - _width);

//			for (i = 0; i < c.numChildren; i++)
//				c.getChildAt(i).x += delta;
			for (i = 0; i < c.children.length; i++)
				DisplayObject (c.children[i]).x += delta;
		}
		// set valign
		if (valign==Valign.NONE) return;

		//если высота контейнера явно не задана выравниваем по максимальной высоте ребенка
		var containerHeight:Number = c.userHeight || c.height;
		//var containerHeight:Number = c.height;
		delta = 0;
//		for (i = 0; i < c.numChildren; i++)
//		{
//			child = c.getChildAt(i);
		for (i = 0; i < c.children.length; i++)
		{
			child = DisplayObject (c.children[i]);
			if (containerHeight > child.height+2*vPadding && valign != Valign.TOP)
			{
				if (valign == Valign.MIDDLE)
					delta = Math.round((containerHeight-child.height) /2);
				else if (valign == Valign.BOTTOM)
					delta = containerHeight-child.height-vPadding;
			}
			else
				delta = vPadding;

			child.y = delta;
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
		return new LayoutSettings(hPadding, vPadding, hSpacing, 0, align, valign);
	}
	
	public function countRows(c:Container, childSize:Number):uint
	{
		return 1;
	}
	
	public function countColumns(c:Container, childSize:Number):uint
	{
		var containerWidth:Number = c.userWidth || c.width;
		return Math.floor((containerWidth - 2*hPadding + hSpacing)/(childSize + hSpacing));
	}
}
}