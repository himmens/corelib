package lib.core.ui.managers
{

import lib.core.util.StringUtil;
import lib.core.util.log.Logger;

/**
 * Содежрит базовые методы по проекту по получению ресурсов, таких как логика формирование
 * тултипов по объекту даных, строки локализации и т.п.
 */
public class ResourceManager
{
	public var returnKeysForEmptyStrings:Boolean = true;

	protected static var _instance:ResourceManager;
	public static function get instance():ResourceManager
	{
		return _instance;
	}

	public function ResourceManager()
	{
		if(!_instance)
		{
			_instance = this;
		}
		else
		{
			throw(new Error("Only one instance of ResourceManager is allowed"));
		}
	}

	protected var locale:String;
	protected var currentMap:Object;

	protected var localeMap:Object = {};
	/**
	 *  Возвращает строку по ключу.
	 * @param key id строки
	 * @param params параметры, формат строки для автозамены:
	 *  %d - целое число
	 * 	%.3f - число с плавающйе точкой с фиксированным выводом 3 знака после запятой (если меньше добьется нулями - Math.toFixed)
	 * 	%s - строка
	 * 	123L - ссылка на строку по ключу 123, т.к. в результирующей строке вместо 123L будет подставлена строка по ключу 123
	 *	для полного списка параметров смотри @see de.popforge.utils.sprintf
	 * @return
	 *
	 * @see de.popforge.utils.sprintf
	 */
	public function getString(key:String, ...params):String
	{
		if(key == "-1" || !key)
			return "";
		
		var str:String = returnKeysForEmptyStrings ? "@"+key : null;
		//var str:String = null;
		if(currentMap && currentMap[key])
		{
			str = currentMap[key];
		}
		
		if(str)
		{
			str = format.apply(null, [str].concat(params));
		}
		
		return str;
	}

	public function hasText(key:String):Boolean
	{
		return currentMap && currentMap[key];
	}
	
	/**
	 * заменяет найденный ключ (в конструкции 123L, ключем будет 123) на строку по указанному ключу
	 */
	protected function replaceKeyByStrings(matchedSubstring:String, capturedMatch:String, index:int, str:String):String
	{
		//для ускорения исопльзуем карту напряму, т.к. параметров здесь нет
//		return getString(int(capturedMatch));
		return currentMap[int(capturedMatch)];
	}

	/**
	 * форматирует переданную строку - вставляет параметры.
	 * Вызывается автоматически из getString, либо межно вызвать вручную передав в качестве параметра паттерн из локализации, это
	 * удобно, когда паттерны приходят с сервера в виде параметров в динамике
	 * @param str
	 * @param params
	 * @return
	 *
	 */
	public function format(str:String, ...params):String
	{
		var res:String = str;

		//заменяем ссылки по ключу L на соответвующие строки перед примененением параметров, т.к. в строках по ключу тоже могут быть ссылки на параметры
		res = res.replace(/(\d+)L/gsi, replaceKeyByStrings);

		//на втором шаге в строке нет ссылок на ключи L, вставляем параметры
		if(str && params && params.length > 0)
		{
			res = StringUtil.format.apply(null, [res].concat(params));
		}

		//после вставки параметров еще раз заменяем ссылки по ключу L (второй уровень вложенности), если в параметрах они были
		res = res.replace(/(\d+)L/gsi, replaceKeyByStrings);

		return res;
	}

	/**
	 * То же что format но с параметрами в виде массива, утилитный метод
	 * @param str
	 * @param param
	 * @return
	 *
	 */
	public function formatArr(str:String, params:Array):String
	{
		return format.apply(null, [str].concat(params));
	}

	public function setLocaleMap(locale:String, map:Object):void
	{
		localeMap[locale] = map;

		if(!this.locale)
			setLocale(locale);
		else
			setLocale(this.locale);
			
	}

	public function setLocale(locale:String):void
	{
		this.locale = locale;
		currentMap = localeMap ? localeMap[locale] : null;

		Logger.debug(this, "set locale: ",locale, ", map = ", currentMap);
	}
	
	/**
	 * Получить строку с нунжым склонение для переданного числа, например
	 * getNumberDeclinationString(3, 123) вернет "голоса"
	 * где под номером 123 в карте локализации должно быть забито "голос,голоса,голосов"
	 *
	 * @param value
	 * @param declinationStrKey
	 * @return
	 *
	 */
	public function getNumberDeclinationString(value:Number, declinationStrKey:String):String
	{
		return StringUtil.getCountString(value, getDeclinationArray(declinationStrKey));
	}
	
	/**
	 * Получить массив склонений по ключу, например
	 *  getDeclinationArray(123) вернет ["голос","голоса","голосов"]
	 * где под номером 123 в карте локализации должно быть забито "голос,голоса,голосов"
	 * @param declinationStrKey
	 * @return
	 *
	 */
	public function getDeclinationArray(declinationStrKey:String):Array
	{
		var str:String = getString(declinationStrKey);
		return str ? getString(declinationStrKey).split("|") : [];
	}

}
}