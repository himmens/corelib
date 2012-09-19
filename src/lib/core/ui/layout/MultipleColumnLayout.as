package lib.core.ui.layout
{
import flash.display.DisplayObject;

/**
 * распологает элементы в столбик с возможностью переноса, если не хватает места по высоте
 * [пока только слева направо]
 */
public class MultipleColumnLayout implements ITableLayout
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
	public function MultipleColumnLayout(	hPadding:Number=0, 
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
		var containerHeight:Number = c.userHeight;
		// если у контейнера нет своей ширины, то не переносим
		if (containerHeight == 0)
			containerHeight = Number.POSITIVE_INFINITY;
		var child:DisplayObject;
		
		_width = hPadding;
		_height = vPadding;

		var maxWidth:Number = 0;
		var currentX:int = hPadding; // текущий x для элементов
		var currentY:int = vPadding; // текущий y для элементов
		
		var currentColumntArray:Array = [];
		
		for (var i : uint = 0; i < c.children.length; i++) 
		{
			child = DisplayObject (c.children[i]);
			
			// перенос на другой стролбик
			if (currentY + child.height > containerHeight - vPadding)
			{
				_height = Math.max(_height, currentY - vSpacing + vPadding);
				
				_width += maxWidth + hSpacing;
				maxWidth = 0;
				
				alignColumn(currentColumntArray, currentY - vSpacing + vPadding, containerHeight);
				currentColumntArray = [];
				
				currentX = _width;
				currentY = vPadding;
			}
			
			currentColumntArray[currentColumntArray.length] = child;
			
			child.x = currentX;
			child.y = currentY;
			
			currentY += child.height + vSpacing;
			
			
			if (child.width > maxWidth)
				maxWidth = child.width;
		}
		
		_height = Math.max(_height, currentY - vSpacing + vPadding);
		_width = maxWidth + _width + hPadding;
		
		if (currentColumntArray.length > 0)
			alignColumn(currentColumntArray, currentY - vSpacing + vPadding, containerHeight);
	}
	
	/**
	 * применяем выравнивание к "строке"-массиву ICell
	 */
	private function alignColumn (row:Array, rowHeight:Number, containerHeight:Number):void
	{
		if (align == Align.LEFT)
			return;
		
		var delta:int = 0;
		if (align == Align.CENTER)
			delta = (containerHeight - rowHeight)/2;
		else if (align == Align.RIGHT)
			delta = containerHeight - rowHeight;

		for (var j : uint = 0; j < row.length; j++)
			DisplayObject(row[j]).y += delta;
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