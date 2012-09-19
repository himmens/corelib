package lib.core.ui.layout
{

public interface ITableLayout extends ILayout
{
	/**
	 * Посчитать кол-во строк для переданной высоты ребенка
	 */ 
	function countRows(c:Container, childHeight:Number):uint;
	/**
	 * Посчитать кол-во столбцов для переданной ширины ребенка
	 */
	function countColumns(c:Container, childWidth:Number):uint;
}

}
