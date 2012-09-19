package lib.core.ui.dnd
{
import flash.events.Event;
import flash.geom.Point;

public class DragEvent extends Event
{
	public static const START_DRAG:String = "startDrag";
	public static const STOP_DRAG:String = "stopDrag";
	public static const MOVE:String = "moveDrag";

	/**
	 * бросили на HotArea
	 */
	public static const DROP_OK:String = "dropOk";
	/**
	 * бросили не на HotArea
	 */
	public static const DROP_BAD:String = "dropBad";

	protected var _point:Point;
	public function get point():Point{return _point;}

	protected var _ctrlKey:Boolean;
	public function get ctrlKey():Boolean{return _ctrlKey;}

	protected var _shiftKey:Boolean;
	public function get shiftKey():Boolean{return _shiftKey;}

	public function DragEvent (type:String, point:Point = null, ctrlKey:Boolean = false, shiftKey:Boolean = false, bubbles:Boolean = false)
	{
		super(type, bubbles);
		_point = point;
		_ctrlKey = ctrlKey;
		_shiftKey = shiftKey;
	}

	override public function clone():Event
	{
		return new DragEvent(type, point, ctrlKey, shiftKey, cancelable);
	}
}
}