package lib.core.service
{
import flash.events.Event;

public class ServiceEvent extends Event
{
	/**
	 * данные сокета
	 */
	public static const COMMAND:String = "command";
	/**
	 * коннект к сокету
	 */
	public static const CONNECT:String = "connect";
	/**
	 * дисконнект сокета
	 */
	public static const DISCONNECT:String = "disconnect";
	/**
	 * ошибка сокета
	 */
	public static const ERROR:String = "error";

	public var data:Object;

	public function ServiceEvent(type:String, data:Object = null)
	{
		super(type, false, true);
		this.data = data;
	}

	public override function clone():Event
	{
		return new ServiceEvent(type, data);
	}
}
}