package lib.core.command.service
{
import lib.core.AppErrorCodes;
import lib.core.command.Command;
import lib.core.util.log.Logger;

import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;

/**
* Базовая команда для работы с http сервисом.
*/
public class HttpServiceCommand extends Command
{
	public static const POST:String = URLRequestMethod.POST;
	public static const GET:String = URLRequestMethod.GET;

	public var log:Boolean = true;
	public var maxDataLog:int = 100; //0 - чтобы показывалась вся сторка

	/**
	 */
	public var endpoint:String;

	protected var format:String = URLLoaderDataFormat.TEXT;
	
	/**
	 * макс. время выполнения команды (мсек)
	 */
	private static const TIME_OUT:uint = 10000;

	/**
	 * Флаг, в значении true команда автоматически запукает событие complete после ответа с сервера.
	 */
	protected var autoNotify:Boolean = true;

	public function HttpServiceCommand()
	{
		super();
		timeOut = TIME_OUT;
	}

	/**
	 *
	 * @param context - контекст сервиса, добавляетяс с endpoint урлу через слеш.
	 * @param data данные формы для отправки
	 *
	 */
	protected function sendData(context:String, data:Object, method:String = POST):void
	{
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = format;
		loader.addEventListener(Event.COMPLETE, onResult);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);

		var request:URLRequest = new URLRequest(endpoint);
		if(context)
			request.url+="/"+context;

		request.method = method;
		request.data = data;

		Logger.debug(this, "sendData ["+method+"]: "+"url="+request.url + (data ? "?"+data : ""));
		loader.load(request);
	}

	/**
	 * обработчик респонса
	 */
	protected function onResult(event : Object) : void
	{
		if(complete)
			return;

		var loader:URLLoader = event.target as URLLoader;
		var data:String = loader.data;

		if(log)
		{
			var logData:String = data ? (maxDataLog > 0 ? data.substr(0, maxDataLog) + "..." : data) : null;
			Logger.debug(this, "::onResult, result = ",logData);
		}

		try
		{
			processResponse(data);
		}
		catch(error:Error)
		{
			Logger.error(this, error.name, error.message, error.getStackTrace());
			_errorCode = AppErrorCodes.PARSE_ERROR;
		}

		if(autoNotify)
			notifyComplete();
	}

	/**
	 * обработчик ошибки в процессе отправки запроса
	 */
	protected function onError(event : ErrorEvent) : void
	{
		if(complete)
			return;

		_errorCode = AppErrorCodes.HTTP_ERROR;

		processLoaderError(event);

		if(autoNotify)
			notifyComplete();
	}

	/**
	 * virtual (Переопределяется в наследниках)
	 *
	 * Обоработка ответа с сервера. Метод переопределяется в наследниках.
	 * @param data
	 *
	 */
	protected function processResponse(data:Object):void
	{
		Logger.debug(this, "processResponse: "+data);
	}

	/**
	 * virtual (Переопределяется в наследниках)
	 *
	 * Обработка ошибки URLLoader в процессе загрузки данных.
	 * @param event
	 *
	 */
	protected function processLoaderError(event:ErrorEvent):void
	{
		Logger.error(this, event.text);
	}

}
}