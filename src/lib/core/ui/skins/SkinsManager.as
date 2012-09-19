package lib.core.ui.skins
{
import lib.core.util.log.Logger;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.PixelSnapping;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.net.LocalConnection;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.SecurityDomain;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.getTimer;

[Event(name="complete", type="flash.events.Event")]
/**
 * Менеджер скинов
 *
 * Загружает swf с классами скинов и предоставялет доступ получения скина по id класса.
 */
public class SkinsManager extends EventDispatcher
{
	//если true - добавляем флаг версии о всем swf, предотвращая загрузку из кеша
	public static const noCache:Boolean = true;

	//ApplicationDomain в который будут грузиться скины, по умолчанию дочерний домен ApplicationDomain.currentDomain
	public var skinsDomain:ApplicationDomain = new ApplicationDomain(null);

	//домен для rsl библиотек
	private var currentDomain:ApplicationDomain = ApplicationDomain.currentDomain;

	//список доменов со скинами. Т.к. при удаленной загрузке каждый swf помещается в свой домен
	private var remoteDomains:Array = [];
	//SecurityDomain для удаленных скинов
	public var securityDomain:SecurityDomain = SecurityDomain.currentDomain;

	//кеш загрузчиков, важно что ключ не слабый, иначе загручики удалятся из кеша сборщиком мусора
	protected var loaders:Dictionary = new Dictionary(false);

	/**
	 * выводить warnings если нет скина
	 */
	public var logWarnings:Boolean = true;
	/**
	 * Флаг высталявется снаружи, показывает приложение загружено с http сервера, а не локально.
	 * Для локального тестирования установить на false;
	 * В случае, если приложение загружено нелокально, скины грузятся в текущий SecurityDomain
	 */
	private static var isRemote:Boolean = true;

	private static var _instance:SkinsManager;
	public static function get instance():SkinsManager
	{
		return _instance;
	}

	public function SkinsManager()
	{
		if(!_instance)
		{
			_instance = this;
			isRemote = (new LocalConnection()).domain != "localhost";
		}
		else
		{
			throw(new Error('Only one instance of SkinsManager is allowed'));
		}
	}

	/**
	 * Возвращает Class скина по идентификатору
	 * @param id идентификатор скина
	 * @return Class скина
	 *
	 */
	public function getSkinDefinition (id:String):Class
	{
		var skinClass:Class = findDefinition(id, skinsDomain);

		if(!skinClass)
		{
			for each(var appDomain:ApplicationDomain in remoteDomains)
			{
				skinClass = findDefinition(id, appDomain);
				if(skinClass)
					break;
			}
		}

		if(!skinClass && logWarnings)
			Logger.warning('Warning: Loaded skins hasn\'t definition for "'+id+'"', this);

		return skinClass;
	}

	public function hasSkin (id:String):Boolean
	{
		var skinClass:Class = findDefinition(id, skinsDomain);

		if(!skinClass)
		{
			for each(var appDomain:ApplicationDomain in remoteDomains)
			{
				skinClass = findDefinition(id, appDomain);
				if(skinClass)
					break;
			}
		}

		return skinClass != null;
	}

	protected function findDefinition (id:String, domain:ApplicationDomain):Class
	{
		if (domain.hasDefinition(id))
			return Class (domain.getDefinition(id));

		//if (domain.hasDefinition("ArtLibraryHolder_"+id))
		//	return Class (domain.getDefinition("ArtLibraryHolder_"+id));

		return null;
	}

	/**
	 * Возвращает инстанс скина по идентификатору
	 * @param id идентификатор скина
	 * @return объект скина
	 *
	 */
	public function getSkin (id:String):DisplayObject
	{
		var className:Class = getSkinDefinition(id);
		if(className)
		{
			var obj:Object;

			try
			{
				obj = new className();
				
				// В некоторых случаях (если флэшка собирается в css >= чем 5.5)
				// случается так что выражение new className(); не вызвает эксепшн 
				// при создании BitmapData - не требуются обязательные параметры ширины и высоты. 
				// Попробуем привети объект к DiaplayObject, если это BitmapData то вывалится эксепшн.
				DisplayObject(obj);

				return obj as DisplayObject;
			}catch(error:Error)
			{
				try
				{
					var err1:Error = error;
					obj = new className(100, 100);
					//Logger.error(this, " can't create skin instance for class = ",className, " \r-",error.message);
					return bdToDisp(obj as BitmapData);
				}catch(error:Error)
				{
					Logger.error(this, " can't create skin instance for class = ",className, " \r-",err1.message, " \r-",error.message);
				}
			}
		}

		return null;
	}

	/**
	 *
	 * @param id идентификатор скина
	 * @param bitmap поставить true для конвертации векторного скина в растр. Метод исопльзовать лучше в паре с кешированием BitmapData, иначе
	 * неэффективно по памяти.
	 * @param bdCache кеш битмап дат по id скина
	 * @return
	 *
	 */
	public function getBitmapSkin (id:String, bdCache:Object = null):DisplayObject
	{
		var skin:DisplayObject = getSkin(id);
		return vectorToBitmap(skin, id, bdCache);
	}

	/**
	 * Есть ли загруженная библиотека
	 * @param source
	 * @return
	 *
	 */
	public function getLib (source:Object):Loader
	{
		return loaders[source] ? loaders[source].loader as Loader : null;
	}

	public function isLibLoaded (source:Object):Boolean
	{
		return loaders[source] ? loaders[source].loaded : false;
	}

	protected function bdToDisp (bd:BitmapData):DisplayObject
	{
		var shape:Shape = new Shape();
		shape.graphics.beginBitmapFill(bd, null, false, true);
		shape.graphics.drawRect(0, 0, bd.width, bd.height);
		return shape;
	}

	protected function vectorToBitmap (vector:DisplayObject, id:String, bdCache:Object):DisplayObject
	{
		if(!vector)
			return null;

		var rect:Rectangle = vector.getBounds(vector);
		var bd:BitmapData = bdCache ? bdCache[id] : null;

		if(!bd)
		{
			bd = new BitmapData(rect.width, rect.height, true, 0x00FFFFFF);
			bd.draw(vector, new Matrix(1, 0, 0, 1, -rect.x, -rect.y), null, null, null, true);
		}

		if(bdCache)
			bdCache[id] = bd;

		var bitmap:DisplayObject = new Bitmap(bd, PixelSnapping.AUTO, true);
		//var bitmap:DisplayObject = bdToDisp(bd);
		var sp:Sprite = new Sprite();
		sp.addChild(bitmap);
		bitmap.x = rect.x;
		bitmap.y = rect.y;

		return sp;
		//return bdToDisp(bd);
	}

	/**
	 *
	 * @param source путь к swf со скинами или byteArray с swf файлом
	 *
	 */
	public function unloadSkin(source:Object):Loader
	{
		var loader:Loader = loaders[source] ? loaders[source].loader : null;
		if(loader)
		{
//			loader.unload();
			loader.unloadAndStop(true);
		}
		delete loaders[source];

		return loader;

	}

	/**
	 *
	 * @param source путь к swf со скинами или byteArray с swf файлом
	 *
	 */
	public function loadSkin(source:Object):Loader
	{
		return loadInternal(source);
	}

	/**
	 * Загрузка swf файла (например внешний модуль или библиотека с классами)
	 *
	 * @param source
	 * @param localDomainFlag если true, загрузится в домен самого приложения, таким образом будут доступны все классы из
	 * загруженного файла, если false файл загрузится в собственный домен и не будет видеть классы приложения, это
	 * удобно для обособленных модулей.
	 * @return
	 *
	 */
	public function loadSwf(source:Object, localDomainFlag:Boolean = true):Loader
	{
		return loadInternal(source, localDomainFlag ? currentDomain  : new ApplicationDomain(null));
	}

	protected function loadInternal(source:Object, domain:ApplicationDomain = null):Loader
	{
		var loader:Loader;
		if(loaders[source])
		{
			loader = loaders[source].loader as Loader;
			return loader;
			//loader.unload();
		}else
		{
			loader = new Loader();
			loaders[source] = {loader:loader, loaderInfo:loader.contentLoaderInfo, starttime:getTimer()};
		}

		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete, false, 1, true);
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError, false, 1, true);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError, false, 1, true);

		//checkPolicyFile только для картинок, политика доступа между swf файлы регулируется секьюрным доменом
       var context:LoaderContext = new LoaderContext(false);
		//fp11 надо выставить этот флаг. чтобы работало в мобильной версии
		if("allowCodeImport" in context) context["allowCodeImport"] = true;
		
        if(source is ByteArray)
        {
			//context.allowLoadBytesCodeExecution = true;
			context.applicationDomain = skinsDomain;
			loader.loadBytes(source as ByteArray, context);
        }
		else
		{
			var url:String = String(source);
			Logger.debug(this, "load swf: url = "+url + ", localDomain = ", domain == currentDomain);

			var remoteSwf:Boolean = url.indexOf("http://") >= 0 || url.indexOf("https://") >= 0;
			//нелокальные swf грузим в свой домен
			if(!domain)
				domain = remoteSwf ? new ApplicationDomain(null) : skinsDomain;

			context.applicationDomain = domain;
			//если приложение загружено удаленно, грузим скины в текущий секьюрный домен, чтобы иметь доступ к скриптованию
			context.securityDomain = isRemote ? securityDomain : null;

			//разрешаем доступ скинов к клиентскому swf. Если этого не сделать скрипт в скинах не будет выполняться
			if(remoteSwf)
				Security.allowDomain(source);

			loader.load(new URLRequest(String(source)), context);
		}

		return loader;
	}

	/**
	 *
	 * @param event
	 *
	 */
	private function onLoadError(event:ErrorEvent):void
	{
		var error : String = event.target+' : '+event.type + '  '+ErrorEvent(event).text;
		Logger.error(this, "onLoadError : "+error);
		
		//удаляем закешированный лоадер, чтобы в след раз по той же ссылке могло нормально загрузиться
		var cached:Object = clearCachedLoader(LoaderInfo(event.target));
	}

	//карта домен<->url, для отладки, чтобы можно было узнать с какого урла загрузился даный скин по id скина
	private var domainMap:Dictionary = new Dictionary(true);

	private function onLoadComplete (event:Event):void
	{
		var info:LoaderInfo = LoaderInfo(event.target);

		//все нелокальные домены добавляем в удаленные домены
		if(info.applicationDomain != skinsDomain)
			remoteDomains[remoteDomains.length] = info.applicationDomain;

		domainMap[info.applicationDomain] = info.url;

		var cached:Object = findCachedLoader(info);
		var time:int = 0;
		if(cached)
		{
			cached.loaded = true;
			time = getTimer() - cached.starttime;
			cached.time = time;
		}
		else
			Logger.error(this, "internal error, can't find cached info by loader, url = ", info.url);

		Logger.debug(this, " onLoadComplete, url = "+info.url+ ", loading time = "+ time+ " ms");

		clearSwfScene(info);

		dispatchEvent(new Event(Event.COMPLETE));
	}

	/**
	 * Чистим всех детей в загруженном swf, иначе они будут висеть в памяти
	 * @param scene
	 *
	 */
	private function clearSwfScene(info:LoaderInfo):void
	{
		try
		{
			if(info.content is DisplayObjectContainer)
			{
				while(DisplayObjectContainer(info.content).numChildren)
				{
					DisplayObjectContainer(info.content).removeChildAt(DisplayObjectContainer(info.content).numChildren-1);
				}
			}
		}catch(error:Error){}
	}

	/**
	 * Ищет ссылку на закешированную информацию по загрузчику
	 * @param loader
	 * @return
	 *
	 */
	private function findCachedLoader(loaderInfo:LoaderInfo):Object
	{
		for each(var obj:Object in loaders)
		{
			if(obj.loaderInfo == loaderInfo)
				return obj;
		}

		return null;
	}
	
	/**
	 * Удаляет закешированную информацию по загрузчику
	 * @param loader
	 * @return 
	 * 
	 */
	private function clearCachedLoader(loaderInfo:LoaderInfo):Object
	{
		var loaderObj:Object;
		for (var source:String in loaders)
		{
			var obj:Object = loaders[source];
			if(obj && obj.loaderInfo == loaderInfo)
			{
				loaderObj = obj;
				delete loaders[source];
			}
		}

		return loaderObj;
	}

	/**
	 * Удаляет все загруженные swf и чистит ссылку instance
	 * Объект становится доступным для сборки GC
	 *
	 */
	public function clear():void
	{
		_instance = null;
		for (var source:Object in loaders)
		{
			unloadSkin(source);
		}
	}

}
}