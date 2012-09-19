package lib.core.ui.controls
{
	import flash.events.Event;
	
	public class ToggleGroupEvent extends Event
	{
		public static const SELECT:String = "select";
		
		public var clicked:Boolean;
		
		public function ToggleGroupEvent(type:String, clicked:Boolean = false, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.clicked = clicked;
		}
		
		override public function clone():Event
		{
			return new ToggleGroupEvent(type, clicked);
		}
	}
}