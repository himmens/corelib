package lib.core.service.transport
{
import com.hurlant.crypto.tls.SSLSecurityParameters;
import com.hurlant.crypto.tls.TLSConfig;
import com.hurlant.crypto.tls.TLSEngine;
import com.hurlant.crypto.tls.TLSSecurityParameters;
import com.hurlant.crypto.tls.TLSSocket;
import lib.core.service.protocol.IProtocol;
import lib.core.util.log.Logger;

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.utils.getDefinitionByName;

public class SecureSocketTransport extends SocketTransport
{
	public static const VER_TLS:String = "tls";
	public static const VER_SSL:String = "ssl";
	
	protected var disableNaviteSecure:Boolean = true;
	
	protected var naviteSecure:Boolean;
	
	protected var _tlsConfig:TLSConfig;
//	public function get tlsConfig():TLSConfig{return _tlsConfig};
	
	public var secureVer:String = VER_TLS;
	
	public function SecureSocketTransport(protocol:IProtocol=null)
	{
		super(protocol);
	}
	
	override protected function init():void
	{
		var nativeSocket:* = getDefinitionByName("flash.net.SecureSocket");
//		naviteSecure = nativeSocket && nativeSocket.isSupported;
		naviteSecure = !disableNaviteSecure && nativeSocket;
		
		if(naviteSecure)
		{
			_socket = new nativeSocket();
		}
		else
		{
			_socket = new TLSSocket(null, 0, _tlsConfig = createTlsConfig());
			TLSSocket(_socket).traceFunction = traceTlsSocket;
		}
		
		super.init();
	}

	public function traceTlsSocket(...params):void
	{
		Logger.error.apply(null, [this].concat(params));
	}
	
	override public function connect(host:String, port:int, policyPort:int=0):void
	{
		_tlsConfig.version = secureVer == VER_TLS ? TLSSecurityParameters.PROTOCOL_VERSION : SSLSecurityParameters.PROTOCOL_VERSION;
		super.connect(host, port, policyPort);
	}
	
	protected function createTlsConfig():TLSConfig
	{
		var config:TLSConfig = new TLSConfig(TLSEngine.CLIENT,
			null, 
			null, 
			null, 
			null, 
			null, 
			SSLSecurityParameters.PROTOCOL_VERSION
//			TLSSecurityParameters.PROTOCOL_VERSION
		);
		config.trustSelfSignedCertificates = true;
		config.ignoreCommonNameMismatch = true;
		
		return config;
	}
	
	override protected function onConnectionError(event:ErrorEvent):void
	{
//		if(naviteSecure)
//		{
//			Logger.error(this, "serverCertificateStatus = ", _socket["serverCertificateStatus"]);
//		}
		
		super.onConnectionError(event);
	}
	
	override protected function onConnectionConnected(event:Event=null):void
	{
//		if(naviteSecure)
//		{
//			Logger.error(this, "serverCertificateStatus = ", _socket["serverCertificateStatus"]);
//		}
		
		super.onConnectionConnected(event);
	}
	
	override protected function onConnectionClose(event:Event=null):void
	{
		if(_socket is TLSSocket)
		{
			TLSSocket(_socket).releaseSocket();
		}
		
		super.onConnectionClose(event);
	}
}
}