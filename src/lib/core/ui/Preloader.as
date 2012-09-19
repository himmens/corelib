package lib.core.ui
{
import flash.display.DisplayObject;
import flash.display.LoaderInfo;
import flash.display.MovieClip;
import flash.events.Event;
import flash.utils.getDefinitionByName;

/**
*Загрузчик, можно использовать для двухкадрого механизма загрузки swf в качестве первого кадра.
*/
public class Preloader extends MovieClip
{
	// Имя класса основного приложения
	private var mainAppClassName:String;

	protected var app:DisplayObject;
	protected var mainLoaded:Boolean;
	
	protected var listenLoaderInfo:LoaderInfo;

	public function Preloader(mainAppClassName:String = null)
	{
		this.mainAppClassName = mainAppClassName;

		this.stop();

		if(stage)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
	}

	protected function onAdded(event:Event = null):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAdded);
		init();
	}

	protected function init():void
	{
		if(!listenLoaderInfo)
			listenLoaderInfo = root.loaderInfo;
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	/**
	 * Возвращает флешварсы
	 * @param display ссылка на любой DisplayObject, добавленынй в display list, т.е. со ссылкой на stage
	 * @return
	 *
	 */
	public static function getParams(display:DisplayObject):Object
	{
		var params:Object;
		if(display && display.stage && display.stage.loaderInfo)
		{
			params = display.stage.loaderInfo.parameters;
			//проверяем, чтобы объект не был пустым
			for(var prop:String in params)
				return params;
		}

		return null;
	}

	protected function getBytesTotal():int
	{
		return listenLoaderInfo.bytesTotal;
	}

	protected function getBytesLoaded():int
	{
		return listenLoaderInfo.bytesLoaded;
	}

	// Вызывается при окончании загрузки .swf файла
	// главного приложения
	protected function createMain():void
	{
		nextFrame();

		if(mainAppClassName)
		{
			var mainClass:Class = Class(getDefinitionByName(mainAppClassName));
			if (mainClass)
			{
			    app = new mainClass();
//			    addChildAt(app as DisplayObject, 0);
			    addChild(app);
			}
		}
	}

	protected var allLoaded:Boolean;
	protected function onAllLoaded():void
	{
		if(!allLoaded)
		{
			allLoaded = true;
			createMain();
		}
	}

	/**
	 * вызывается в процесса загрузки главного приложения.
	 * Переопределить в загрузчиках модулей для отображения скорректированного
	 * прогресса, например, если помимо основнойф флешки, надо загрузить дополнительные
	 * модули.
	 *
	 * @param percent
	 *
	 */
	protected function updateProgressBar(event:Event = null):void
	{
		var percent:Number = getBytesLoaded() / getBytesTotal();
		setMainProgress(percent);
	}

	/**
	 * Прогресс загрузки ядра
	 * @param progress
	 *
	 */
	virtual protected function setMainProgress(progress:Number):void
	{

	}

	protected function onEnterFrame(event:Event):void
	{
		if(framesLoaded == totalFrames)
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			onMainLoaded();
		}
		else
		{
			updateProgressBar();
		}
	}

	protected function onMainLoaded():void
	{
		setMainProgress(1);

		mainLoaded = true;
		checkAllLoaded();
	}

	protected function checkAllLoaded():void
	{
		if(mainLoaded)
		{
			onAllLoaded();
		}
	}
}
}