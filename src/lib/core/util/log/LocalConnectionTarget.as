package lib.core.util.log
{
import flash.events.StatusEvent;
import flash.net.LocalConnection;
import flash.system.Security;

public class LocalConnectionTarget extends AbstractLoggerTarget implements ILoggerTarget
{
	private static var lc:LocalConnection = new LocalConnection();
	
	private var lcName:String;
	
	public function LocalConnectionTarget(lcName:String = "LoggerOutput")
	{
		this.lcName = lcName;
	}

	override public function internalLog(message:String, level:int):void
	{
		if(active)
			sendToLC(message, level)
	}
	
	private function sendToLC (message:String, level:int):void
	{
		if(! lc.hasEventListener(StatusEvent.STATUS)) 
		{
			lc.addEventListener(StatusEvent.STATUS, onLCStatus);
			//Security.allowDomain("*");
			lc.allowDomain("*");
		}
		
		var lcmsg:String = message.substring(0, 1000);
		lc.send(lcName, "log", lcmsg, level);
	}
	
	private function onLCStatus(event:StatusEvent):void
	{
//		msg(event);
	}
		
	
	
}
}