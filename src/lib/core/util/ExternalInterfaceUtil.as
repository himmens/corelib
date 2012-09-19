package lib.core.util
{
import flash.external.ExternalInterface;

import lib.core.util.log.Logger;
import lib.core.util.log.Logger;

/**
 * Обертка для ExternalInterface для вызова JS методов.
 * Проверяет наличие js функции перед тем, как ее вызвать.
 */
public class ExternalInterfaceUtil
{
	/**
	 * Проверяет наличие функции js
	 */
	public static function hasJSFunction(func:String):Boolean
	{
		var res:Boolean;
		try {
			res = ExternalInterface.call("function(){return typeof "+func+" == 'function'}");
		}
		catch (e:Error) {
			Logger.debug("ExternalInterfaceUtil::", e.message);
		}
		return res;
	}

	/**
	 * Обертка для метода ExternalInterface.addCallback с обработкой ошибок доступа
	 * return Удалось ли создать callback
	 */
	public static function addCallback(callbackName:String, callback:Function):Boolean
	{
		Logger.debug("ExternalInterfaceUtil::", "addCallback", callbackName, callback);
		var res:Boolean;
		try {
			ExternalInterface.addCallback(callbackName, callback);
			res = true;
		}
		catch (e:Error) {
			Logger.debug("ExternalInterfaceUtil::", e.message);
		}
		return res;
	}

	/**
	 * Обертка для метода ExternalInterface.call с обработкой ошибок доступа.
	 * Возвращает:
	 *  - значение функции, если есть возвращаемое значение
	 *  - true, если нет возвращаемого значения и функция успешно вызвалась
	 *  - false при любой ошибке.
	 */
	public static function call(func:String, ...params):*
	{
		Logger.debug("ExternalInterfaceUtil::", "call", func, params);
		var res:* = false;
		try {
			var hasFunction:Boolean = hasJSFunction(func);
			if (hasFunction)
			{
				res = ExternalInterface.call.apply(null, [func].concat(params));
				//Если функция возвращает void (В as значение равно undefined), возвращаем успешное завершение как true
				if (res == undefined)
					res = true;
			}
			else
			{
				Logger.debug("ExternalInterfaceUtil::", "There is no js function "+ func + ". Check js file for it!");
			}
		}
		catch (e:Error) {
			Logger.debug("ExternalInterfaceUtil::", e.message);
		}
		return res;
	}

	public static function refresh():void
	{
		call("window.location.reload");
	}

	public static function showApp(show:Boolean):void
	{
		var js:String = "function(){var app = document.getElementById('"+appDomId+"'); " +
			"if(app){" +
			"app.style.width = " + (show ? "''; " : "'1px'; ") +
			"app.style.height = " + (show ? "''; " : "'1px'; ") +
			"}}";
		call(js);
	}

	public static function get appDomId():String
	{
		var app_id:String = ExternalInterface.available ? ExternalInterface.objectID : null;
		app_id = app_id || "flash-app";

		return app_id;
	}
	
	/**
	 * Выполняет скрипт js.
	 */
	public static function execJs(str:String):void
	{
		ExternalInterfaceUtil.call("function(){"+str+"}");
	}

}
}