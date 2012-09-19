package lib.core.service
{
import lib.core.service.transport.AbstractTransport;
import lib.core.service.transport.TransportEvent;
import lib.core.util.log.Logger;

import flash.events.EventDispatcher;
import flash.utils.getTimer;

[Event (name="command", 	type="lib.core.service.ServiceEvent")]
[Event (name="connect", 	type="lib.core.service.ServiceEvent")]
[Event (name="disconnect", 	type="lib.core.service.ServiceEvent")]
[Event (name="error", 		type="lib.core.service.ServiceEvent")]

/**
 * Обертка на AbstractTransport
 *
 */
public class RemoteService extends EventDispatcher
{
	public var log:Boolean = true
	
	protected var transport:AbstractTransport;
	protected var activeTrans:AbstractTransport;

	public function get connected():Boolean
	{
		return activeTrans ? activeTrans.connected : false;
	}

	public function RemoteService(transport:AbstractTransport = null):void
	{
		super();

		this.transport = transport;
		init();
	}

	protected function init():void
	{
		if(transport)
			setActiveTrans(transport);
	}

	public function connect(host:String, port:int, policyPort:int = 0):void
	{
		Logger.debug(this, "connect: "+host+":"+port+" (policyPort: "+policyPort+") time:" + getTimer());
		activeTrans.connect(host, port, policyPort);
	}

	public function setActiveTrans(trans:AbstractTransport):void
	{
		if(activeTrans)
		{
			activeTrans.removeEventListener(TransportEvent.CONNECT, onTransport);
			activeTrans.removeEventListener(TransportEvent.DATA, onTransport);
			activeTrans.removeEventListener(TransportEvent.DISCONNECT, onTransport);
			activeTrans.removeEventListener(TransportEvent.ERROR, onTransport);
		}
		activeTrans = trans;
		activeTrans.log = log;

		activeTrans.addEventListener(TransportEvent.CONNECT, onTransport);
		activeTrans.addEventListener(TransportEvent.DATA, onTransport);
		activeTrans.addEventListener(TransportEvent.DISCONNECT, onTransport);
		activeTrans.addEventListener(TransportEvent.ERROR, onTransport);
	}

	protected function onTransport(event:TransportEvent):void
	{
		var type:String = event.type;
		if(event.type == TransportEvent.DATA) type = ServiceEvent.COMMAND;

		var logMsg:String = "";
		var serverStr:String = activeTrans.host+":"+activeTrans.port;
		if(event.type == TransportEvent.ERROR)
		{
			logMsg = "Error connect to the server "+serverStr+" Reason: " + event.data + " time: " + getTimer();
			Logger.error(this, logMsg);
		}else if(event.type == TransportEvent.DISCONNECT)
		{
			logMsg = "! connection to the server "+serverStr+" was closed";
			Logger.debug(this, logMsg);
		}else if(event.type == TransportEvent.CONNECT)
		{
			logMsg = "! connection to the server "+serverStr+" was successfully esteblished";
			Logger.debug(this, logMsg);
		}

		dispatchEvent(new ServiceEvent(type, event.data));
	}

	public function close():void
	{
		if(activeTrans)
			activeTrans.close();
	}

	/**
	 * Отправка AMF объекта на игровой сервер
	 * @param request
	 */
	public function sendData(request:Object):void
	{
		if(activeTrans)
			activeTrans.sendData(request);
	}

}
}