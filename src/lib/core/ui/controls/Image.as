package lib.core.ui.controls
{
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import lib.core.util.log.Logger;

[Event(name="complete", type="flash.events.Event")]
[Event(name="ioError", type="flash.events.IOErrorEvent")]
[Event(name="securityError", type="flash.events.SecurityErrorEvent")]

/**
 * Класс для загрузки битпам изображений.
 * Функционал:
 * 	- загрузить новое с автоматической очисткой текущего
 *  - загрузка с доступом к контенту (скриншоты, сглаживание, размеры) по любому урлу (в том числе без crossdomain.xml)
 * 	- удобная поддержка сглаживания изображения через флаг smoothing
 *  - геттеры на bitmapData и bitmap
 *  - возможность кеширования bitmapData. При включенном кеше картинка берется из кеша без повторной загрузки
 */
public class Image extends Sprite
{
	public static var checkPolicyDefault:Boolean = true;

	protected var _loader:Loader;
	protected var _prepareloader:Loader;
	protected var _request:URLRequest;
	protected var _context:LoaderContext;

	/**
	 * снаружи можно назначить кеш - карта
	 * {url:BitmapData}
	 * Если по урлу будет найдет объект в кеше он подставится.
	 * Удобно для кеширования аватаров юзеров, баннеров и т.п.
	 */
	public var cache:Object;

	public function Image()
	{
		init();
	}

	protected function init():void
	{
	}

	//полная очистка текущего контента перед загрузкой нового
	protected function clear():void
	{
		clearLoaders();

		if(_bitmap)
		{
			deleteChild(_bitmap);
			_bitmap = null;
		}

		if(_bitmapData)
		{
			if(!cache)
				_bitmapData.dispose();
			_bitmapData = null;
		}
	}

	//удаляет загрузчики
	protected function clearLoaders():void
	{
		if(_loader)
		{
			deleteChild(_loader);
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoader);
			_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoader);
			_loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoader);
			_loader.unloadAndStop(false);
			_loader = null;
		}

		if (_prepareloader)
		{
			deleteChild(_prepareloader);
			_prepareloader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPrepareLoader);
			_prepareloader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPrepareLoader);
			_prepareloader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onPrepareLoader);
			_prepareloader.unloadAndStop(false);
			_prepareloader = null;
		}

	}

	//утилитный меотд для удаления DisplayObject-а со всеми проверками на null, чтобы не падало
	protected function deleteChild(child:DisplayObject):void
	{
		if(!child)
			return;

		if(child && contains(child))
			child.parent.removeChild(child);
	}

	/**
	 * Загрузить изображение по ссылке. Для загрузки нового, текущее изображение выгружать необазательно
	 * @param request реквест или null
	 *
	 */
	public function load(request:URLRequest, context:LoaderContext = null):void
	{
		if(request && url == request.url)
		{
			return;
		}

		unload();

		if(request)
		{
			_request = request;
			_context = context || new LoaderContext(checkPolicyDefault);

			if(cache && cache[url] is BitmapData)
			{
				_bitmapData = cache[url];
				drawBitmap();
			}else
			{
				//хак, грузим через промежуточный загрузчик, чтобы не привязываться к наличию crossdomain.xml
				prepareLoad(request);
			}
		}
	}

	/**
	 * Удалить текущее изображение
	 * Метод синхронный.
	 *
	 */
	public function unload():void
	{
		_request = null;
		_context = null;

		clear();
	}

	protected function prepareLoad(request:URLRequest):void
	{
		_prepareloader = new Loader();
		_prepareloader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPrepareLoader);
		_prepareloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPrepareLoader);
		_prepareloader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onPrepareLoader);
		_prepareloader.load(request);
	}

	//отрисовать BitmapData по загруженному контенту (для оптимизации - если один раз отрисовали больше не рисуем, так что не забываем чистить)
	protected function drawBitmapData():BitmapData
	{
		if(!_bitmapData)
		{
			try
			{
				var source:DisplayObject = _loader.content;
				_bitmapData = new BitmapData(source.width, source.height, smoothing, 0x00000000);
				_bitmapData.draw(source);
			}
			catch(error:Error)
			{
				_bitmapData = null;
//				Logger.debug(this, error.getStackTrace());
			}
		}

		return _bitmapData;
	}

	// вставляет битпаму из того, что загрузилось вместо загрузчика
	protected function drawBitmap():Bitmap
	{
		_bitmap = cloneBitmap();

		clearLoaders();

		if(_bitmap)
			addChild(_bitmap);

		return _bitmap;
	}

	public function get url():String
	{
		return _request ? _request.url : null;
	}

	protected var _bitmapData:BitmapData;
	public function get bitmapData():BitmapData
	{
		return _bitmapData;
	}

	protected var _bitmap:Bitmap;
	public function get bitmap():Bitmap
	{
		return _bitmap;
	}

	/**
	 * Создает новый экземпляр битмапы по тому, что сейчас отрисовано.
	 * Если картинки нет, возвращает null
	 * @return
	 *
	 */
	public function cloneBitmap():Bitmap
	{
		var bitmap:Bitmap;
		var bd:BitmapData = bitmapData;
		if(bd)
		{
			bitmap = new Bitmap(bd, PixelSnapping.AUTO, smoothing);
		}
		return bitmap;

	}

	//обработчик прелоадера для картинки
	protected function onPrepareLoader(event:Event):void
	{
		if (event.type == Event.COMPLETE)
		{
			loadBytes(LoaderInfo(event.target).bytes)
		}
		else
		{
			Logger.debug(this, "onPrepareLoader", event.type, url);
			if(hasEventListener(event.type))
				dispatchEvent(event);
		}
	}

	protected function loadBytes(bytes:ByteArray):void
	{
		addChild(_loader = new Loader());

		_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoader);
		_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoader);
		_loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoader);

		_loader.loadBytes(bytes);
	}

	protected function onLoader(event:Event):void
	{
		Logger.debug(this, "onLoader", event.type, url);

		//вставляем загруженую битмапу
		drawBitmapData();
		drawBitmap();

		//если используется кеширование - кешируем картинку
		if(cache)
			cache[url] = bitmapData;

		if(hasEventListener(event.type))
			dispatchEvent(event);
	}


	private var _smoothing:Boolean = true;
	/**
	 * Сглаживать загруженную битмапу.
	 * @param value
	 *
	 */
	public function set smoothing (value:Boolean):void
	{
		if(_smoothing != value)
		{
			_smoothing = value;
			if(_bitmap)
				_bitmap.smoothing = value;
		}
	}

	public function get smoothing ():Boolean
	{
		return _smoothing;
	}

	[Deprecated("use get bitmap instead of loader")]
	public function get loader():Loader
	{
		return _loader;
	}

	[Deprecated("use get bitmap instead of cached")]
	public function get cached():DisplayObject
	{
		return _bitmap;
	}



}
}