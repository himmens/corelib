package lib.core.util.log
{

public class TraceTarget extends AbstractLoggerTarget implements ILoggerTarget
{
	public function TraceTarget()
	{
	}

	override public function internalLog(message:String, level:int):void
	{
		if(active)
			trace(message);
	}
	
}
}