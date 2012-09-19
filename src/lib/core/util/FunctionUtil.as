package lib.core.util
{
import flash.display.Shape;
import flash.events.Event;

public class FunctionUtil
{
	private static var mc:Shape = new Shape();

	//стек объектов для вызова функций CallObject
	private static var callLaterMethods:Array = new Array();

	/**
	* Для выполнения функции через заданное количество кадров.
	 *
	 * @param func функция выполнения
	 * @param framesNumber количество кадров
	 * @param params аргументы функции
	 */
	public static function callLater(func:Function, framesNumber:int=1, ...params):void
	{
		var callObject:CallObject = new CallObject(func, params, framesNumber, 0);

		//Проверка, содержится ли данная функция в стеке вызовов с аналогичными параметрами
		var obj:CallObject = ArrayUtils.getElementByPropertyValue(callLaterMethods, "func", callObject.func) as CallObject;
		if (obj && obj.equals(callObject))
			return;

		callLaterMethods.push(callObject);
		if (!mc.hasEventListener(Event.ENTER_FRAME)) {
			mc.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
	}

	private static function onEnterFrame(event:Event):void
	{
		for (var i:int=0; i<callLaterMethods.length; i++) {
			var obj:CallObject = callLaterMethods[i] as CallObject;
			obj.count++;
			if (obj.count >= obj.framesNumber) {
				callLaterMethods.splice(i, 1);
				obj.func.apply(null, obj.params);
			}
		}

		if (callLaterMethods.length <= 0) {
			if (mc.hasEventListener(Event.ENTER_FRAME))	{
				mc.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
	}
}
}

internal class CallObject extends Object
{
	public var func:Function;
	public var params:Array;
	public var framesNumber:int;
	public var count:int;

	public function CallObject(func:Function, params:Array, framesNumber:int, count:int)
	{
		this.func = func;
		this.params = params;
		this.framesNumber = framesNumber;
		this.count = count;
	}

	public function equals(value:CallObject):Boolean
	{
		if (value) {
			//Проверяем количество framesNumber
			if (value.func == func) {
				if (value.framesNumber == framesNumber) {
					//Проверяем количество параметров
					if (value.params.length == params.length) {
						//Проверяем каждый параметр
						for (var i:int=0; i<params.length; i++) {
							if (value.params[i] != params[i])
								return false;
						}
						return true;
					}
				}
			}
		}
		return false;
	}
}