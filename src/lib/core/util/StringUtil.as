package lib.core.util
{
import de.popforge.utils.sprintf;

import flash.utils.ByteArray;

import mx.utils.Base64Decoder;
import mx.utils.Base64Encoder;
import lib.core.util.log.Logger;

public class StringUtil
{

	// Текст пробельных символов
	public static const WHITESPACE:String = " \t\n\r";

	/**
	 * Вставляем параметры в строку (формат аналогичен Java Formatter):
	 *
	 * Пример:
	 *    	StringUtil.format("%4$2s %3$2s %2$2s %1$2s", "a", "b", "c", "d")
	 *   	// -> " d  c  b  a"
	 *
	 * 		StringUtil.format("e = %+10.4f", Math.E);
	 * 		//-> "e =    +2,7183"
	 * @param str
	 * @param params
	 * @return
	 *
	 * @see http://java.sun.com/j2se/1.5.0/docs/api/java/util/Formatter.html
	 */
	public static function format(str:String, ... params):String
	{
		//Алгоритм - переставялем параметры исходя из номеров в строке %1$, %2$, ...
		//потом скармливаем строку и переставленные параметры sprintf

		//расставляем параметры в нужном порядке
		var arr:Array = str.match(/\%(\d+)\$/gs);
		if (arr && arr.length > 1)
		{
			//пересортированные параметры
			var remaped:Array = [];
			var index:int;
			var val:String;
			for (var i:int = 0; i < arr.length; i++)
			{
				val = arr[i];
				index = int(val.substring(1, val.length - 1)) - 1;
				remaped[index] = params[i];
			}

			params = remaped;
		}

		//удаляем номера параметров, чтобы привести к формату sprintf
		str = str.replace(/\%\d+\$/gis, "\%");

		try
		{
			str = sprintf.apply(null, [str].concat(params));
		}catch(error:Error)
		{
			Logger.error("StringUtil::format, " + error.message);
		}
		return str;
	}

	public static function base64encode(value:Object):String
	{
		var ba:ByteArray = new ByteArray();
		ba.writeObject(value);

		var encoder:Base64Encoder = new Base64Encoder();
		encoder.encodeBytes(ba);

		return encoder.flush();
	}

	public static function base64decode(value:String):Object
	{
		var decoder:Base64Decoder = new Base64Decoder();
		decoder.decode(value);

		var ba:ByteArray = decoder.flush();

		return ba.readObject();
	}

	/**
	 * Возвращает сокращенную строку, с указанием тыс, млн, млрд
	 * @param num число
	 * @param strings массив строк. Пример ["тыс.","млн.","млрд"]
	 */
	public static function trimNumber(num:Number, strings:Array):String
	{
		// миллиарды
		if (num >= 1000000000)
		{
			return (num / 1000000000).toFixed(1) + " " + strings[2];
		}
		// миллионы
		if (num >= 100000)
		{
			return (num / 1000000).toFixed(1) + " " + strings[1];
		}
		// Тысячи
		if (num >= 10000)
		{
			return (num / 1000).toFixed(1) + " " + strings[0];
		}
		return num.toString();
	}

	/**
	 * Удаление символов из начала текста.
	 *
	 * @param source
	 * @param removeChars
	 *
	 * @return
	 */
	public static function trimLeft(source:String, removeChars:String = StringUtil.WHITESPACE):String
	{
		var pattern:RegExp = new RegExp('^[' + removeChars + ']+', '');
		return source.replace(pattern, '');
	}

	/**
	 * Удаление символов из конца текста.
	 *
	 * @param source
	 * @param removeChars
	 *
	 * @return
	 */
	public static function trimRight(source:String, removeChars:String = StringUtil.WHITESPACE):String
	{
		var pattern:RegExp = new RegExp('[' + removeChars + ']+$', '');
		return source.replace(pattern, '');
	}

	/**
	 * Удаление символов из начала и конца текста.
	 *
	 * @param source
	 * @param removeChars
	 *
	 * @return
	 */
	public static function trim(source:String, removeChars:String = StringUtil.WHITESPACE):String
	{
		var pattern:RegExp = new RegExp('^[' + removeChars + ']+|[' + removeChars + ']+$', 'g');
		return source.replace(pattern, '');
	}

	/**
	 * Возвращает строку количества элементов в нужном падеже.
	 *
	 * @param number - количество элементов
	 * @param ends - массив з-х окончаний. Пример: ["день","дня","дней"]
	 */
	public static function getCountString(count:int, ends:Array):String
	{
		//если в массиве только одна строка используем ее для всех падежей (предполагая, что в текущей локале нет падежей)
		if(ends.length == 1)
		{
			ends[ends.length] = ends[0];
			ends[ends.length] = ends[0];
		}

		if (ends.length < 3)
		{
			Logger.error("StringUtil.formatCount:: Массив ends должен содержать 3 элемента");
			return "";
		}

		var restStr:String = "";
		var count:int = count > 14 ? count % 10 : count;
		if (count == 1)
			restStr = ends[0];
		else if (count == 2 || count == 3 || count == 4)
			restStr = ends[1];
		else
			restStr = ends[2];

		return restStr;
	}

	[Deprecated("use StringUtil::getCountString method instead of StringUtil::formatCount")]
	/**
	 * Возвращает строку количества элементов в нужном падеже.
	 *
	 * @param number - количество элементов
	 * @param ends - массив з-х окончаний. Пример: ["день","дня","дней"]
	 */
	public static function formatCount(count:int, ends:Array):String
	{
		//если в массиве только одна строка используем ее для всех падежей (предполагая, что в текущей локале нет падежей)
		if(ends.length == 1)
		{
			ends[ends.length] = ends[0];
			ends[ends.length] = ends[0];
		}

		if (ends.length < 3)
		{
			Logger.error("StringUtil.formatCount:: Массив ends должен содержать 3 элемента");
			return "";
		}

		var restStr:String = "";
		var rest:int = count % 10;
		var del:int = count - rest;
		restStr = ends[2];
		if (del != 10)
		{
			if (rest == 1)
				restStr = ends[0];
			else if (rest == 2 || rest == 3 || rest == 4)
				restStr = ends[1];
		}
		return count + " " + restStr;
	}

	/**
	 * Форматирование текста исходя из количества символов
	 * (разбиение по группам символов и добавление цифры 9 в нужном количестве, если количество символов больше, чем нужно).
	 *
	 * Примеры:
	 * 1)Запрос: formatToPrecise("123456", -1, "", true) - оставить исходный текст не тронутым,
	 * 	но разбить по группам. 
	 * 	Результат: 123 456
	 * 2) Запрос: formatToPrecise("123456", 5, "", true) - проверить, 
	 * 	не превышает ли количество символов в исходном тексте 5 символов,
	 * 	и разбить текст по группам. 
	 *  Результат: 99 999
	 * 3) Запрос: formatToPrecise("123456", 5, "+", true) - проверить, 
	 * 	не превышает ли количество символов в исходном тексте 5 символов,
	 *  если превышает, то добавить вконце символ "+", и разбить текст по группам. 
	 *  Результат: 99 999+
	 * 4) Запрос: formatToPrecise("123456", 5, "+", false) - проверить, 
	 * 	не превышает ли количество символов в исходном тексте 5 символов,
	 *  если превышает, то добавить вконце символ "+" (без разбития на группы)
	 *  Результат: 99999+
	 * 
	 * @param	source исходный текст.
	 * @param	precise количество символов, которое нужно оставить
	 * 			(если передано -1, то кол-во символов не будет учитываться).
	 * @param	greaterSign строка, которая будет передаваться, если в исходной строке символов больше, чем нужно.
	 * @param	delimitGroups нужно ли разделять группы символов (напр. из 10000 делать 10 000).
	 *
	 * @return	отформатированная строка.
	 */
	public static function formatToPrecise(source:String, precise:int = -1, greaterSign:String = "", delimitGroups:Boolean = false):String
	{
		var arr:Array;
		var temp:Array;

		// Если количество символов больше, чем нужно, то изменяем исходный текст,
		// чтобы он содержал только цифру 9 в нужном количестве, а так же символ greaterSign
		var isNeedAddGreaterSign:Boolean = false;
		if(precise != -1 && source.length > precise)
		{
			source = "";
			while (precise > 0)
			{
				source += "9";
				precise--;
			}
			isNeedAddGreaterSign = true;
		}

		// Если нужно, то разбиваем текст по группам
		if (delimitGroups)
		{
			arr = source.split("");
			temp = [];
			while (arr.length > 2)
			{
				temp.push([arr.pop(), arr.pop(), arr.pop()].reverse().join(""));
			}
			if (arr.length)
				temp.push(arr.join(""));
			temp.reverse();
			source = temp.join(" ");
		}

		if(isNeedAddGreaterSign)
		{
			source += greaterSign;
		}

		return source;
	}
	
	/**
	 * Возвращает строку из заданных строк разбитую на колонки шириной указанной в width 
	 * @param width ширина колонки в символах. Можно указать число, можно указать массив размеров каждого столбца
	 * @param params параметры для разбиения по колонкам
	 * @return 
	 * 
	 */
	public static function paramsToColumns(width:*, ...params):String
	{
		var result:String = "";
		var widths:Array = [];
		if (width is Number || width is int || width is uint)
		{
			widths.push(width);
		}
		else if (width is Array)
		{
			widths = width;
		}
		else
		{
			Logger.error("StringUtil.paramsToColumns:: параметр width должен быть либо массивом, либо числом");
			return "";
		}
		// позиция первого символа текущего парметра
		var paramStartIndex:int = 0;
		for (var i:int = 0; i< params.length; i++)
		{
			result += params[i];
			var currentWidth:Number = widths[Math.min(i, widths.length - 1)];
			
			var needSpaces:int = currentWidth - (result.length - paramStartIndex);
			// добавим количество недостающих пробелов до ширины колонки
			for (var k:int = 0; k < needSpaces; k++)
			{
				result += " ";
			}
			paramStartIndex = result.length;
		}
		return result;
		
	}
}
}