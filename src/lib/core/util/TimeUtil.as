package lib.core.util
{

public class TimeUtil
{
	public static var days:Array = ["day", "day", "day"];
	public static var hours:Array = ["hour", "hour", "hour"];
	public static var minutes:Array = ["minutes", "minutes", "minutes"];
	public static var seconds:Array = ["seconds", "seconds", "seconds"];

	public static var monthsFull:Array = ["January","February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
	public static var daysFull:Array = ["Monday", "Tuesday", "Wednesday",  "Thursday", "Friday", "Sturday", "Sunday"];

	public static var days_s:String = "d.";
	public static var hours_s:String = "h.";
	public static var minutes_s:String = "m.";
	public static var seconds_s:String = "s.";
	
	//идентификаторы даты и времени
	public static const DATE_IDS:Array = ["hh", "mm", "ss", "h", "m", "s", "YYYY", "YYY", "MMM", "DD", "MM", "YY", "D", "M", "Y"];
	
	
	/**
	 * Возвращает строку времени в формате h:m:s, h-часы,m-минуты,s-секунды
	 *
	 * @param value время в секундах
	 * @param shorten сокращать ли время вывода до минут и секунд, если количество часов равно нулю
	 */
	public static function formatTime(value:int, shorten:Boolean = true):String
	{
		if (value <= 0)
			value = 0;
//			return shorten ? "00:00" : "00:00:00";

		var res:String = "";
		var sec:Number = Math.floor(value % 60);
		var min:Number = Math.floor(value / 60);
		var hour:Number = Math.floor(min / 60);

		var parts:Array = [];

		if (hour >= 1 || !shorten)
		{
			min = Math.floor(min % 60);
			parts[parts.length] = hour;
		}

		parts[parts.length] = min < 10 ? '0' + min : min;
		parts[parts.length] = sec < 10 ? '0' + sec : sec;

//			res = String(hour + ':' + (min < 10 ? '0' + min : min) + ':' + (sec < 10 ? '0' + sec : sec));
//		else
//		{
//			if (shorten)
//				res = String((min < 10 ? '0' + min : min) + ':' + (sec < 10 ? '0' + sec : sec));
//			else
//				res = String(hour + ':' + (min < 10 ? '0' + min : min) + ':' + (sec < 10 ? '0' + sec : sec));
//		}

		var delimiter:String = ":";
		res = parts.join(delimiter);

		return res;
	}

	/**
	 * Возвращает время в формате "1 день, 16 часов, 5 минут, 59 секунд"
	 * @param value время в секундах
	 * @param shortstr использовать короткие строки: "ч.", а не "часов"
	 * @return
	 *
	 */
	public static function formatTime2(
		value:int,
		shortstr:Boolean = true,
		showDays:Boolean = true,
		days:Array = null,
		hours:Array = null,
		minutes:Array = null,
		seconds:Array = null):String
	{
		if (value <= 0)
			value = 0;

		days = days || TimeUtil.days;
		hours = hours || TimeUtil.hours;
		minutes = minutes || TimeUtil.minutes;
		seconds = seconds || TimeUtil.seconds;

		var res:String = "";

		//TODO: парсить дни более красивым способом.. ) без вычитания из value распарсенных дней
		var day:int = value / (24*60*60);
		value-=day*24*60*60;

		var sec:int = value % 60;
		var min:int = value / 60;
		var hour:int = min / 60;

		var parts:Array = [];
		var delim:String = " ";
		if (day >= 1 && showDays)
		{
			hour = hour % 24;
			parts[parts.length] = (shortstr ? day + days_s : day + delim +StringUtil.getCountString(day, days));
		}

		if (hour >= 1)
		{
			min = min % 60;
			parts[parts.length] = (shortstr ? hour + hours_s : hour + delim +StringUtil.getCountString(hour, hours));
		}
		if(min >= 1)
		{
			parts[parts.length] = (shortstr ? min + minutes_s : min + delim + StringUtil.getCountString(min, minutes));
		}

//		if(!shorten || value == 0)
		if(sec >= 1)
		{
			parts[parts.length] = (shortstr ? sec + seconds_s : sec + delim +StringUtil.getCountString(sec, seconds));
		}

		var delimiter:String = " ";
		res = parts.join(delimiter);

		return res;
	}

	/**
	 * Возвращает строку с датой в формате dd/mm/yyyy
	 * @param timeStamp время unix
	 *
	 */
	public static function formatDate(timeStamp:Number):String
	{
		timeStamp *= 1000;
		var date:Date = new Date(timeStamp);
		var day:String = (date.date >= 10) ? date.date.toString() : "0" +  date.date.toString();
		var month:String = (date.month+1 >= 10) ? (date.month+1).toString() : "0" +  (date.month+1).toString();
		return day + "/" + month + "/" + date.fullYear;
	}
	
	/**
	 * Возвращает строку с датой в формате dd/mm
	 * @param timeStamp время unix
	 *
	 */
	public static function formatDateToMonth(timeStamp:Number):String
	{
		timeStamp *= 1000;
		var date:Date = new Date(timeStamp);
		var day:String = (date.date >= 10) ? date.date.toString() : "0" +  date.date.toString();
		var month:String = (date.month+1 >= 10) ? (date.month+1).toString() : "0" +  (date.month+1).toString();
		return day + "/" + month;
	}
	
	/**
	 * Возвращает строку с датой в указанном формате
	 * @param timeStamp время unix
	 * @param format формат времени
	 * 
	 * примеры форматирования
	 * год: YYYY - 2012, YY - 12
	 * месяц: MMM - June, MM - 02, M - 2
	 * день: DDD - Monday, DD - 05, D - 5
	 * часы: hh - 03, h - 3
	 * минуты: mm - 07, m - 7
	 * секунды: ss - 09, s - 9
	 * пример 1: timeStamp=1234567890 и format="DD.MM.YYYY hh:mm:ss" выведет 14.02.2009 03:31:30
	 * пример 2: timeStamp=1234567890 и format="h:m YY.M.D" выведет 3:31 09.2.14
	 */
	public static function getFormatDate(timeStamp:Number, format:String = "DD.MM.YY hh:mm:ss"):String
	{
		var date:Date = new Date(timeStamp);
		var dateMap:Object =
		{
			DDD: daysFull[date.date],
			DD: (date.date < 10) ? "0" +  date.date.toString() : date.date.toString(),
			D: date.date.toString(),
			MM: (date.month + 1 < 10) ? "0" + (date.month + 1).toString() : (date.month + 1).toString(),
			MMM: monthsFull[date.month],
			M: (date.month + 1).toString(),
			YYYY: date.fullYear.toString(),
			YYY: date.fullYear.toString(),
			YY: date.fullYear.toString().substring(2, 4),
			Y: date.fullYear.toString(),
			
			hh: (date.hours	 < 10) ? "0" + date.hours.toString()	: date.hours.toString(),
			h: date.hours.toString(),
			mm: (date.minutes < 10) ? "0" + date.minutes.toString()	: date.minutes.toString(),
			m: date.minutes.toString(),
			ss: (date.seconds < 10) ? "0" + date.seconds.toString()	: date.seconds.toString(),
			s: date.seconds.toString()
		};
		
		var retStr:String = new String(format);
		for (var i:int = 0; i < DATE_IDS.length; i++ )
		{
			retStr = retStr.replace(new RegExp("" + DATE_IDS[i], "g"), dateMap[DATE_IDS[i]]);
		}
		
		return retStr;
	}
	
	/**
	 * Текущее ремя в миллисек
	 */ 
	public static function getCurrentTime():Number
	{
		return (new Date()).time;
	}
	
}
}