package lib.core.util.log
{
import flash.events.StatusEvent;
import flash.net.LocalConnection;
import flash.system.Security;

public class AbstractLoggerTarget implements ILoggerTarget
{
	private var _active:Boolean = true;
	public function set active (value:Boolean):void{_active = value;}
	public function get active ():Boolean{return _active;}

	public function AbstractLoggerTarget()
	{
	}

	public function internalLog(message:String, level:int):void
	{
	}
	
}
}