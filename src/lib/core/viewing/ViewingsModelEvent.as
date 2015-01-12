package lib.core.viewing
{
import flash.events.Event;

public class ViewingsModelEvent extends Event
{
	/**
	 * окно добавлено
	 */
	public static const ADD_VIEW:String = "addView";
	
	/**
	 * окно надо обновить (применить новые настройки к открытому окну)
	 */
	public static const UPDATE_VIEW:String = "updateView";
	
	/**
	 * окна закрыто
	 */
	public static const CLOSE_VIEW:String = "closeView";
	
	public var name:String;
	public var id:String;
	public var modal:Boolean;
	public var params:ViewParams;
	
	public function ViewingsModelEvent(type:String, name:String = null, id:String = null, modal:Boolean = false, params:ViewParams = null)
	{
		super(type);
		
		this.name = name;
		this.id = id;
		this.modal = modal;
		this.params = params;
	}
	
	override public function clone():Event
	{
		return new ViewingsModelEvent(type, name, id, modal, params);
	}
}
}