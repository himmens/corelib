package lib.core.service.transport
{
import lib.core.service.protocol.IProtocol;
import lib.core.util.log.Logger;

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.Socket;
import flash.system.Security;
import flash.utils.ByteArray;

/**
 * Транспорт данных на базе Socket
 */
public class SocketTransport extends AbstractTransport
{
	//для использование TLSSocket из as3crypto приходится ставить тип Object, но объект должен обладать всеми свойствами и методами Socket
	protected var _socket:Object;

	public function SocketTransport(protocol:IProtocol=null)
	{
		super(protocol);
	}

	override protected function init():void
	{
		super.init();
		
		_socket = _socket || new Socket();
		_socket.addEventListener( Event.CONNECT,						onConnectionConnected );
		_socket.addEventListener( ProgressEvent.SOCKET_DATA,			onSocketData );
		_socket.addEventListener( IOErrorEvent.IO_ERROR,				onConnectionError );
		_socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR,	onConnectionError );
		_socket.addEventListener( Event.CLOSE,							onConnectionClose );
	}
	
	override public function connect(host:String, port:int, policyPort:int = 0):void
	{
		if (connected) return;

		super.connect(host, port, policyPort);

		if(_policyPort)
			Security.loadPolicyFile("xmlsocket://"+_host+":"+_policyPort);

		_socket.connect(_host, _port);
	}

	override public function close():void
	{
		if (!connected) return;

		_socket.close();

		super.close();
	}

	private function onSocketData(event:ProgressEvent):void
	{
		var bytes:ByteArray = new ByteArray();
		_socket.readBytes(bytes);
		readData(bytes);
	}

	override protected function sendRequest(data:Object):void
	{
		var bytes:ByteArray = data as ByteArray;
		_socket.writeBytes(bytes);
		_socket.flush();
	}

}
}