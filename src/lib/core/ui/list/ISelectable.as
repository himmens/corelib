package lib.core.ui.list
{
import flash.events.IEventDispatcher;

public interface ISelectable extends IEventDispatcher
{
	function set selectable(value:Boolean):void;
	function get selectable():Boolean;
	
	function set selected(value:Boolean):void;
	function get selected():Boolean;
}
}