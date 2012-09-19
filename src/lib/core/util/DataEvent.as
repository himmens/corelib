package lib.core.util
{
import flash.events.Event;

[Event (name="someData", type="lib.core.util.DataEvent")]
public class DataEvent extends Event
{
	public static const SOME_DATA:String = "someData";

	public var data:*;

	public function DataEvent(type:String, data:*, bubbles:Boolean=false, cancelable:Boolean=false)
	{
		super(type, bubbles, cancelable);

		this.data = data;
	}

	override public function clone():Event
	{
		return new DataEvent(type, data);
	}

}
}