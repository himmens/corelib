﻿package lib.core.service.transport
{
import flash.events.Event;

public class TransportEvent extends Event
{
	/**
	 * данные
	 */
	public static const DATA:String = "data";
	/**
	 * коннект
	 */
	public static const CONNECT:String = "connect";
	/**
	 * дисконнект
	 */
	public static const DISCONNECT:String = "disconnect";
	/**
	 * ошибка
	 */
	public static const ERROR:String = "error";

	public var data:Object;

	public function TransportEvent(type:String, data:Object = null, bubbles:Boolean=false, cancelable:Boolean=false)
	{
		super(type, bubbles, cancelable);
		this.data = data;
	}

	public override function clone():Event
	{
		return new TransportEvent(type, data, bubbles, cancelable);
	}
}
}