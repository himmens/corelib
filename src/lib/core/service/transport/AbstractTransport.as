package lib.core.service.transport
{
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import lib.core.service.protocol.IProtocol;
import lib.core.service.protocol.ProtocolData;
import lib.core.util.log.Logger;

[Event (name="data", 		type="lib.core.service.transport.TransportEvent")]
[Event (name="connect", 	type="lib.core.service.transport.TransportEvent")]
[Event (name="disconnect", 	type="lib.core.service.transport.TransportEvent")]
[Event (name="error", 		type="lib.core.service.transport.TransportEvent")]

/**
 * Базовый класс для транспорта данных - например через socket или http
 *
 * Задача транспорта уметь общаться пакетами данных с удаленным сервером.
 * Сам пакет формируется протоколом (например ByteArray для сокета или URLLoader-Binary, URLVariables для урл лоадера и т.п.)
 */
public class AbstractTransport extends EventDispatcher
{
	public var log:Boolean = false;

	protected var _host:String;
	public function get host():String
	{
		return _host;
	}

	protected var _policyPort:int;

	protected var _port:int;
	public function get port():int
	{
		return _port;
	}

	protected var _isConnect:Boolean = false;
	public function get connected():Boolean
	{
		return _isConnect;
	}

	protected var _protocol:IProtocol;
	public function get protocol():IProtocol
	{
		return _protocol;
	}
	public function set protocol (value:IProtocol):void
	{
		_protocol = value;
	}

	public function AbstractTransport(protocol:IProtocol = null)
	{
		this.protocol = protocol;

		init();
	}

	protected function init():void
	{

	}

	public function connect(host:String, port:int, policyPort:int = 0):void
	{
		_host = host;
		_port = port;
		_policyPort = policyPort;

		if(log)
			Logger.debug(this, "Connecting to the server: "+_host+", port = "+_port+" (policyPort: "+_policyPort+")");
	}

	public function close():void
	{
		_isConnect = false;
	}

	/**
	 * Отправка запроса на удаленный сервер
	 * @param data
	 */
	public function sendData(data:Object):void
	{
		if (!connected) return;

		if(log)
			Logger.debug(this, "REQUEST to server:  at ", getTimer() ,">>>\r"+data);

		var request:Object = protocol.writeObject(data);
		sendRequest(request);
	}

	/**
	 * Внутренний механизм трансопрта отправки запроса (например через Socket или URLLoader)
	 * @param data
	 */
	virtual protected function sendRequest(data:Object):void
	{

	}

	/**
	 * Обработка сырых данных от транспорта.
	 * Если данные считаны не полностью, вызываем метод обновления данных
	 * @param data
	 */
	protected function readData(data:Object):void
	{
		if(!protocol)
		{
			Logger.error(this, "::readData, protocol must be set for reading incoming data");
			return;
		}

		var protoData:ProtocolData = protocol.readObject(data);
		processProtoData(protoData);
	}

	/**
	 *  Обработка данных от протокола
	 * @param data
	 */
	protected function processProtoData(protoData:ProtocolData):void
	{
		if(protoData.readError)
		{
			Logger.error(this, "read data error", protoData.readError);
			dispatchEvent(new TransportEvent(TransportEvent.ERROR, "read data error: error = " + protoData.readError));
			return;
		}

		var readData:Array = protoData.readData;
		while(readData.length)
			processData(readData.shift());

		if(!protoData.readCompleted)
			peekData();
	}

	protected function processData(data:Object):void
	{
		if(log)
			Logger.debug(this, "RESPONSE from server: <<< ", data);

		var event:Event = new TransportEvent(TransportEvent.DATA, data, false, true);
		dispatchEvent(event);
	}

	/**
	 * Проверить, есть ли новые данные (для сокета метод остается пустым, для http лезем сами на сервер
	 */
	protected function peekData():void
	{

	}

	//только для сокетов
	protected function onConnectionClose(event:Event = null):void
	{
		_isConnect = false;
		dispatchEvent(new TransportEvent(TransportEvent.DISCONNECT));
	}

	protected function onConnectionConnected(event:Event = null):void
	{
		_isConnect = true;
		dispatchEvent(new TransportEvent(TransportEvent.CONNECT));
	}

	protected function onConnectionError(event:ErrorEvent):void
	{
		_isConnect = false;
		dispatchEvent(new TransportEvent(TransportEvent.ERROR, event.text));
	}

}
}