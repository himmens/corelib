package lib.core.util
{
	public class DateUtil
	{
		// Количество миллисекунд в разных отрезках времени
		static public const MILLISECONDS_IN_SECOND:Number = 1000;
		static public const MILLISECONDS_IN_MINUTE:Number = DateUtil.MILLISECONDS_IN_SECOND * 60;
		static public const MILLISECONDS_IN_HOUR:Number = DateUtil.MILLISECONDS_IN_MINUTE * 60;
		static public const MILLISECONDS_IN_DAY:Number = DateUtil.MILLISECONDS_IN_HOUR * 24;
		// Количество секунд в разных отрезках времени
		static public const SECONDS_IN_SECOND:Number = DateUtil.MILLISECONDS_IN_SECOND / DateUtil.MILLISECONDS_IN_SECOND;
		static public const SECONDS_IN_MINUTE:Number = DateUtil.MILLISECONDS_IN_MINUTE / DateUtil.MILLISECONDS_IN_SECOND;
		static public const SECONDS_IN_HOUR:Number = DateUtil.MILLISECONDS_IN_HOUR / DateUtil.MILLISECONDS_IN_SECOND;
		static public const SECONDS_IN_DAY:Number = DateUtil.MILLISECONDS_IN_DAY / DateUtil.MILLISECONDS_IN_SECOND; 
		
		
		public function DateUtil()
		{
		}
		
		/**
		 * Проверка, наступили ли новые сутки с указанного момента времени.
		 * 
		 * @param value время в мсек, относительно которого делаем проверку
		 */ 
		public static function checkNextDateFrom(value:Number):Boolean 
		{
			var date:Date = new Date(value);
			var nextDate:Date = new Date(date.fullYear, date.month, date.date+1, 0, 0, 0, 0);
			var curDate:Date = new Date();
			
			return curDate.getTime() >= nextDate.getTime();
		}
	}
}