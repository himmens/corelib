package lib.core.ui.layout
{

import flash.display.DisplayObject;

/**
 * распологает элементы в столбик
 * [пока только сверху вниз]
 */
public class ColumnLayout implements ITableLayout
{
	public var vSpacing : Number;
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
	public function ColumnLayout (	hPadding:Number=0,
									vPadding:Number=0,
									vSpacing:Number=0,
									align:String=null,
									valign:String=null)
	{
		this.hPadding = hPadding;
		this.vPadding = vPadding;
		this.vSpacing = vSpacing;
		this.align = align==null ? Align.LEFT : align;
		this.valign = valign==null ? Valign.TOP : valign;
	}

	public function arrange(c : Container) : void
	{
		var child:DisplayObject;
		_width = hPadding*2;
		_height = vPadding;
		var tmpWidth:Number = 0;
		var delta:int;

		for (var i : uint = 0; i < c.children.length; i++)
		{
			child = DisplayObject (c.children[i]);
			child.y = int(_height);
			_height += child.height + vSpacing;

			tmpWidth = child.width + 2*hPadding;
			if (tmpWidth > _width)
				_width = tmpWidth;
		}
		_height = _height - vSpacing + vPadding;

		// set valign
		var containerHeight:Number = c.userHeight || c.height;
		//var containerHeight:Number = c.height;
		if (containerHeight != 0)
		{
			delta = 0;
			if (valign == Valign.MIDDLE)
				delta = Math.round((containerHeight - _height) / 2);
			else if (valign == Valign.BOTTOM)
				delta = containerHeight - _height;

			for (i = 0; i < c.children.length; i++)
				DisplayObject (c.children[i]).y += delta;
		}
		// set align
		if (align == Align.NONE) return;
		var containerWidth:Number = c.userWidth || c.width;
		//var containerWidth:Number = c.width;
		delta = 0;
		for (i = 0; i < c.children.length; i++)
		{
			child = DisplayObject (c.children[i]);
			if (containerWidth > child.width+2*hPadding && align != Align.LEFT)
			{
				if (align == Align.CENTER)
				{
					delta = (containerWidth-child.width)/2;
				}
				else if (align == Align.RIGHT)
				{
					delta = containerWidth-child.width-hPadding;
				}
			}
			else
			{
				delta = hPadding;
			}
			child.x = delta;
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
		return new LayoutSettings(hPadding, vPadding, 0, vSpacing, align, valign);
	}
	
	public function countRows(c:Container, childSize:Number):uint
	{
		var containerHeight:Number = c.userHeight || c.height;
		return Math.floor((containerHeight - 2*vPadding + vSpacing)/(childSize + vSpacing));
	}
	
	public function countColumns(c:Container, childSize:Number):uint
	{
		return 1;
	}
}
}