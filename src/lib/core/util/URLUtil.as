package lib.core.util
{
import flash.text.Font;
	

public class URLUtil
{
	/**
	 * Возвращает рутовый урл сервера (с портом) по переданному урлу
	 * Например:
	 * 
	 * 
	 * @param url
	 * @return урл сервера, если он есть, если переданный урл локальный (без http) возвращается null
	 * 
	 */
	public static function getServerUrl (url:String):String
	{
		//строка протокола, например http:// или https://
		var protocol:String;
		var index:int = url.indexOf(protocol = "http://");
		if(index == -1)
			index = url.indexOf(protocol = "https://");
		
		if(index == -1)
			return null;
		
		index = protocol.length;
		var srvIndex:int = url.indexOf("?", index);
		if(srvIndex == -1)
			srvIndex = url.indexOf("/", index);
		
		//строка сервера, например cs4510.vkontakte.ru
		var server:String = url.substring(index, srvIndex > 0 ? srvIndex : int.MAX_VALUE);
		
			
		return protocol+server;
	}
	
}

}