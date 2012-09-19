package lib.core.util.log
{
import flash.events.EventDispatcher;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;
import flash.utils.getTimer;


public class Logger extends EventDispatcher
{
	/**
	 * Активен ли лог
	 */
	private static var active:Boolean = true;

	/**
	 * Масимальное количество оплей объекта в логе
	 */
	public static var OBJECT_FIELDS_CNT:int = 30;

	public static var level:uint = DEBUG;
//	private static var level:uint = PROTOCOL;

	public static const ALL:uint 			= 0;
	public static const PROTOCOL:uint 		= 1;
	public static const DEBUG:uint 			= 2;
	public static const PERFORMANCE:uint 	= 3;
	public static const WARNINGS:uint 		= 4;
	public static const ERRORS:uint 		= 5;
	public static const NOTHING:uint 		= 6;

	/**
	 * массив объектов получающих колбеки от логгера
	 */
	private static var targets:Array;

	public static function addTarget (target:ILoggerTarget):void
	{
		if(!targets)
			targets = [];

		targets[targets.length] = target;
	}

	public static function removeTarget (target:ILoggerTarget):void
	{
		if(targets)
			targets.splice(targets.indexOf(target), 1);
	}

	public static function getTargets ():Array
	{
		return targets;
	}

	/**
	 * Сообщение для дебага
	 */
	public static function debug (... args):void
	{
		if (level <= DEBUG)
		{
			messageOut("[DEBUG] : " + getTimer() + " : " + argsToMsg(args), DEBUG);
		}
	}
	
	public static function custom (level:int, ... args):void
	{
		//if (level <= DEBUG)
		//{
			messageOut("[LEVEL_"+level+"] : " + getTimer() + " : " + argsToMsg(args), level);
		//}
	}
	
	/**
	 * Сообщения для вывода времени исполнения кода в ms
	 * @param timestamp - начало времени исполнения кода
	 * @param args
	 *
	 * использование:
	 * <pre>
	 * var t:int = getTimer();
	 * someFunctionToMeasureMs();
	 * Logger.performance(t, "someFunctionToMeasureMs")
	 * </pre>
	 */
	public static function performance (timestamp:int = 0, ... args):void
	{
		if (level <= PERFORMANCE)
		{
			if(timestamp > 0)
				args[args.length] = ", time = "+(getTimer() - timestamp) + " ms";
			messageOut("[PERFORMANCE] : "+argsToMsg(args), PERFORMANCE);
		}
	}
	
	public static function protocol (... args):void
	{
		if (level <= PROTOCOL)
		{
			messageOut("[PROTOCOL] : "+argsToMsg(args), PROTOCOL);
		}
	}
	
	public static function error (... args):void
	{
		if (level <= ERRORS)
		{
			messageOut("[ERROR] : "+argsToMsg(args), ERRORS);
		}
	}
	
	public static function warning (... args):void
	{
		if (level <= WARNINGS)
		{
			messageOut("[WARNING] : "+argsToMsg(args), WARNINGS);
		}
	}
	
	private static function messageOut (message:String, level:int):void
	{
		if (active)
		{
			_log+=message+"\r";
			
			for each(var target:ILoggerTarget in targets)
			target.internalLog(message, level);
		}
	}
	
	private static var _log:String = "";
	public static function get log():String
	{
		return _log;
	}
	
	private static const tabStr:String = "    ";
	private static function argsToMsg(arr:Array):String
	{
		var msg:String = "";
		
		if(arr.length > 0)
			for(var i:uint; i < arr.length; i++)
			{
				msg += (arr[i] is Array) ? "Array " : arr[i];
				
				if(!isSimple(arr[i]))
					msg += ":"+parse(arr[i], tabStr);
				else if (i < arr.length - 1)
//					msg+=",";
					msg+=" ";
			}
		
		return msg+"\r";
	}
	
	private static var tabs:String = " ";
	private static function parse(o:Object, tabs:String):String
	{
		var out:String = "";
		
		if(!(o is ByteArray) && o.hasOwnProperty("toObject"))
			o = o.toObject();
		
		//счетчик - показываем не более N записей обьекта. чтобы не засорять лог
		var cnt:int = OBJECT_FIELDS_CNT;
		for(var prop:* in o)
		{
			out+= tabs + String(prop) + ":" + getType(o[prop]) + " = ";
			
			if(isSimple(o[prop]))
				out+=o[prop]+"\r";
			else
				out+=getType(o[prop])+parse(o[prop], tabs+tabStr);
			
			if(--cnt<=0)
			{
				out+=tabs+"...\r";
				break;
			}
		}
		
		return out ? "\r"+out : "";
	}

	private static const simpleTypes:Array = ["int", "uint", "String", "Number", "Boolean", "null", "XML", "void"];
	private static function isSimple(o:*):Boolean
	{
		var _type:String = getType(o);
		return simpleTypes.indexOf(_type) >=0;
	}

	private static function getType(o:*):String
	{
		var type:String = "null";
		try
		{
			type = getQualifiedClassName(o);
//			type = describeType(o).@name;
		}catch(error:Error)
		{

		}
		return type;
	}
}

}

