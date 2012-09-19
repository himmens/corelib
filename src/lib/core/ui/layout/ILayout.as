package lib.core.ui.layout
{

public interface ILayout
{
	function arrange (c:Container):void;
	
	function get settings():LayoutSettings;

	function get width():Number;
	function get height():Number;
}

}
