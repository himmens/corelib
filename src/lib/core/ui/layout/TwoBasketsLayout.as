package lib.core.ui.layout
{
import flash.display.DisplayObject;

import lib.core.ui.layout.Align;
import lib.core.ui.layout.Container;
import lib.core.ui.layout.ILayout;
import lib.core.ui.layout.RowLayout;
import lib.core.ui.layout.Valign;

/**
 * Перемещение объекта из одной строки в другую - по сути такая же строка но для указанного элемента 
 * extraSpacingIndex расстояние между ним и предыдущим элементом варьируется от 0 до hExtraSpacing в 
 * зависимости от position
 */
public class TwoBasketsLayout extends RowLayout implements ILayout
{
	public var hExtraSpacing : Number;
	public var extraSpacingIndex : Number;

	public var position : Number = 1;

	public function TwoBasketsLayout (	hPadding:Number=0,
								vPadding:Number=0,
								hSpacing:Number=0,
								hExtraSpacing:Number=0,
								extraSpacingIndex:Number=0,
								align:String=Align.LEFT,
								valign:String=Valign.TOP)
	{
		super(hPadding, vPadding, hSpacing, align, valign);

		this.hExtraSpacing = hExtraSpacing;
		this.extraSpacingIndex = extraSpacingIndex;
	}

	override public function arrange(c:Container):void
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

			if(i == extraSpacingIndex -1)
			{
				_width += hExtraSpacing * position;
//				child.scaleX = child.scaleY = 1 + ( 1 - position);
			}
			else if(i == extraSpacingIndex)
			{
				_width += hExtraSpacing;
//				child.scaleX = child.scaleY = 2;
//				child.scaleX = child.scaleY = 1 + position;
			}
			else if(i == extraSpacingIndex + 1)
			{
				_width += hExtraSpacing * (1 - position);
//				child.scaleX = child.scaleY = 1 + ( 1 - position);
			}

			tmpHeight = child.height + 2*vPadding;
			if (tmpHeight > _height)
				_height = tmpHeight;
		}
		_width = _width - hSpacing + hPadding;

	}

}
}