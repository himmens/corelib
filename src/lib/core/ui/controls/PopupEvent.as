package lib.core.ui.controls
{
import flash.events.Event;

public class PopupEvent extends Event
{
	public static const POPUP_OK:String = "popupOk";
	public static const POPUP_CANCEL:String = "popupCancel";
	
	public static const POPUP_HIDE:String = "popupHide";
	
	/**
	 * some data holder
	*/	
	public var data:*

	public function PopupEvent (type:String, data:* = null)
	{
		super(type, false, false);
	}

	override public function clone():Event
	{
		return new PopupEvent(type, data);
	}
	
}

}