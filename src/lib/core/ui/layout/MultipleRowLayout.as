package lib.core.ui.layout
{
import flash.display.DisplayObject;

/**
 * распологает элементы в строку с возможностью переноса, если не хватает места по ширине
 * [пока только слева направо]
 */
public class MultipleRowLayout implements ITableLayout
{
	public var vSpacing : Number;
	public var hSpacing : Number;
	public var vPadding : Number;
	public var hPadding : Number;
	public var align : String;
	
	private var _width:Number=0;
	private var _height:Number=0;
	
	/**
	 * @param hPadding отступ слева и справа от контента
	 * @param vPadding отступ сверху и снизу от контента
	 * @param hSpacing горизонтальный отступ между элементами
	 * @param vSpacing вертикальный отступ между элементами
	 * @param align выравнивание по горизонтали
	 */
	public function MultipleRowLayout (	hPadding:Number=0, 
										vPadding:Number=0, 
										hSpacing:Number=0, 
										vSpacing:Number=0, 
										align:String = Align.LEFT)
	{
		this.hPadding = hPadding;
		this.vPadding = vPadding;
		this.hSpacing = hSpacing;
		this.vSpacing = vSpacing;
		this.align = align;
	}

	public function arrange (c : Container) : void 
	{
		var containerWidth:Number = c.userWidth;
		// если у контейнера нет своей ширины, то не переносим
		if (containerWidth == 0)
			containerWidth = Number.POSITIVE_INFINITY;
		var child:DisplayObject;
		
		_width = hPadding;
		_height = vPadding;

		var maxHeight:Number = 0;
		var currentX:int = hPadding; // текущий x для элементов
		var currentY:int = vPadding; // текущий y для элементов
		
		var currentRowArray:Array = [];
		
		for (var i : uint = 0; i < c.children.length; i++) 
		{
			child = DisplayObject (c.children[i]);
			
			// перенос на другую строчку
			if (currentX + child.width > containerWidth - hPadding)
			{
				_width = Math.max(_width, currentX - hSpacing + hPadding);
				
				_height += maxHeight + vSpacing;
				maxHeight = 0;
				
				alignRow(currentRowArray, currentX - hSpacing + hPadding, containerWidth);
				currentRowArray = [];
				
				currentX = hPadding;
				currentY = _height;
			}
			
			currentRowArray.push(child);
			
			child.x = currentX;
			currentX += child.width + hSpacing;
			
			child.y = currentY;
			
			if (child.height > maxHeight)
				maxHeight = child.height;
		}
		
		_width = Math.max(_width, currentX - hSpacing + hPadding);
		_height = maxHeight + _height + vPadding;
//		_height = maxHeight + _height + vPadding;
		
		if (currentRowArray.length > 0)
			alignRow(currentRowArray, currentX - hSpacing + hPadding, containerWidth);
	}
	
	/**
	 * применяем выравнивание к "строке"-массиву ICell
	 */
	private function alignRow (row:Array, rowWidth:Number, containerWidth:Number):void
	{
		if (align == Align.LEFT)
			return;
		
		var delta:int = 0;
		if (align == Align.CENTER)
			delta = (containerWidth - rowWidth)/2;
		else if (align == Align.RIGHT)
			delta = containerWidth - rowWidth;

		for (var j : uint = 0; j < row.length; j++)
			DisplayObject(row[j]).x += delta;
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
		return new LayoutSettings(hPadding, vPadding, hSpacing, vSpacing, align);
	}
	
	public function countRows(c:Container, childSize:Number):uint
	{
		var containerHeight:Number = c.userHeight || c.height;
		return Math.floor((containerHeight - 2*vPadding + vSpacing)/(childSize + vSpacing));
	}
	
	public function countColumns(c:Container, childSize:Number):uint
	{
		var containerWidth:Number = c.userWidth || c.width;
		return Math.floor((containerWidth - 2*hPadding + hSpacing)/(childSize + hSpacing));
	}
}
}