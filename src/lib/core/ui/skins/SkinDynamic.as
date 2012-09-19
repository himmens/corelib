package lib.core.ui.skins
{
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;

import lib.core.util.log.Logger;

/**
 * начали гружать контент
 */
[Event (name="init", type="flash.events.Event")]
/**
 * загрузили контент
 */
[Event (name="complete", type="flash.events.Event")]
/**
 * ошибка при загрузке контента
 */
[Event (name="error", type="flash.events.ErrorEvent")]
/**
 * ошибка при загрузке контента
 */
[Event (name="noSkin", type="lib.core.ui.skins.SkinDynamic")]

/**
 * Абстрактный класс динамического скина.
 * Расширяет функционал родительского Skin - runtime загрузка графики.
 *
 * Для использования надо сделать класс наследник:
 * 	При назначении id скина, если такого скина нет в скин менеджере проверяет наличие библиотеки методом getSkinLib(id),
 * 	который пеерписывается в наследнике - GameSkin.
 * 	Наследник переопределяет метод - возвращая ссылку на скин из карты, которую может брать в моделе.
 *
 * Функционал:
 * 	- runtime загрузка swf файлов с графикой по id (графика собрана в swf библиотеки с прописанными linkage)
 * 	- noSkinId id скина, который вставится, если скин по переданному id не показался (нет такого или ошибка в загрузке),
 * 		аналог "крестика" при загрузке картинки
 * 	- keepSkin - не удалять предыдущий скин, пока не загрузился новый. Удобно использовать там, где не должно быть мигания,
 * 		при смене графики.
 */
public class SkinDynamic extends Skin
{
	public static const NO_SKIN:String = "noSkin";

	protected var _loading:Boolean = false;
	public function get loading():Boolean{return _loading}

	/**
	 * если скина нет в либе, будет использоваться этот скин.
	 * Удобно для выставления дефолной картинки
	 */
	public var noSkinId:String;

	/**
	 * когда true, храним предыдущий скин до тех пор, пока не загрузился новый
	 */
	public var keepSkin:Boolean = false;

	public function SkinDynamic(id:String = null, width:Number = 0, height:Number = 0)
	{
		super(id, width, height);
	}

	override protected function updateSkin ():void
	{
		unhandleLoader();

		if(!id)
		{
			if(!keepSkin)
				setSkin(null);
			return;
		}

		var skin:DisplayObject = createSkin(id);

		if(skin)
			setSkin(skin);
		else
		{
			//удаляем текущий скин, пока не загрузился новый
			if(_content && !keepSkin)
				setSkin(null);

			//если есть урл для скина пробуем его загрузить
			var url:Object = getSkinLib(id);
			if(!url)
			{
				thereIsNotSkin();
				return;
			}
			//Loader в котором есть данный скин, если он уже был загружен
			var loader:Loader = skinsManager.getLib(url);
			if(!loader)
				loadSkin(url);
			//урл уже загружен или грузится, слушаем его события
			else
			{
				//если еще не загружен, слушаем загрузку
				if(!skinsManager.isLibLoaded(url))
					handleLoader(loader);
				else
					thereIsNotSkin();
			}
		}
	}

	override protected function createSkin(id:String):DisplayObject
	{
		//отключаем warning-и при получении скина, чтобы не засорять лог. Нужные вартинги кинутся из thereIsNotSkin
		var cachedWarnings:Boolean = skinsManager.logWarnings;
		skinsManager.logWarnings = false;

		var skin:DisplayObject = super.createSkin(id);

		skinsManager.logWarnings = cachedWarnings;
		return skin;
	}

	protected function thereIsNotSkin():void
	{
		var url:Object = getSkinLib(id);
		Logger.warning(this, " there isn't skin \""+skinId+"\""+ (url ? " in "+url : ""));

		id = noSkinId;

		if(hasEventListener(NO_SKIN))
			dispatchEvent(new Event(NO_SKIN));
	}

	/**
	 * @virtual
	 * Возвращает урл swf файла ,в котором есть данный скин.
	 * @param id
	 * @return
	 *
	 */
	protected function getSkinLib(id:String):String
	{
		return null;
	}

	protected var loader:Loader;
	protected function loadSkin(url:Object):void
	{
		unhandleLoader();

		loader = skinsManager.loadSkin(url);

		handleLoader(loader);
	}

	protected function handleLoader(loader:Loader):void
	{
		this.loader = loader;

		setLoadingProgress(0);
		_loading = true;
		showLoading(_loading);

		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadCompelte, false, 0);
		loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress, false, 0);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError, false, 0);
		loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError, false, 0);

		if(hasEventListener(Event.INIT))
			dispatchEvent(new Event(Event.INIT));
	}

	protected function unhandleLoader():void
	{
		if(!loader) return;

		setLoadingProgress(1);
		_loading = false;
		showLoading(_loading);

		loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadCompelte, false);
		loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onLoadProgress, false);
		loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError, false);
		loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError, false);

		loader = null;
	}

	private function onLoadProgress(event:ProgressEvent):void
	{
		setLoadingProgress(event.bytesLoaded/event.bytesLoaded);
	}

	protected function onLoadCompelte(event:Event):void
	{
		unhandleLoader();

		var skin:DisplayObject = createSkin(id);

		if(skin)
		{
			setSkin(skin);
		}
		else
		{
			thereIsNotSkin();
		}

		if(hasEventListener(Event.COMPLETE))
			dispatchEvent(new Event(Event.COMPLETE));
	}

	override protected function setSkin(skin:DisplayObject):void
	{
		super.setSkin(skin);

		//if(skin)
		//	showLoading(false);
	}

	protected function onLoadError(event:ErrorEvent):void
	{
		//showLoading(true);
		unhandleLoader();

		//if(_showLoadingLabel)
		//	setLoadingFeedback(true);

		if(hasEventListener(ErrorEvent.ERROR))
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, event.text));
		}
	}

	/**
	 * Вызывается при прогерссе загрузки, по умолчанию ничего не делает. Можно переопредлить в наследниках.
	 * @param progress
	 *
	 */
	protected function setLoadingProgress(progress:Number):void
	{
	}

	/**
	 * Показывает/прячет визуалку, отвечающую за отображение статуса загруки - можно переопредлить меотд и
	 * показывать например вращающийся бублик и т.п.
	 * @param show
	 *
	 */
	protected function showLoading(show:Boolean):void
	{
	}

	[Deprecated("use noSkinId to set the graphics if there isn't skin for given id")]
	protected function setLoadingFeedback(error:Boolean):void
	{
	}
}
}