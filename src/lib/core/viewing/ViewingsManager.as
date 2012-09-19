package lib.core.viewing
{

import lib.core.util.Graph;
import lib.core.util.log.Logger;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.utils.Dictionary;

import mx.binding.utils.BindingUtils;

/**
* Менеджер модулей, добавляет/удаляет модули по их id по осбытиям от объекта навигатор - NavigatorModel.
 *
*/
public class ViewingsManager
{
	/**
	 * Карта экранов screenId:className
	 */
	protected var SCREENS_MAP:Object = {};

	/**
	 * карта настроек показа окон.
	 * Объекты типа:
	 * {
	 * 	cache: true || false			//отключает кеширование, если false
	 * 	holder: DisplayObjectContainer 	//родитель для окна
	 * 	index: int 						//по какому индексу добавлять (будет автоматическая проверка допустимого диапазона)
	 * 	skipArrange						//не позиционировать окно
	 *  checkBounds						//проверять bounds при выставлении x,y(по stage и windth/height view объекта) чтобы влазило
	 * 	modalColor						//цвет модальности
	 * 	modalAlpha						//прозрачность модальности
	 * }
	 */
	protected var SETTINGS_MAP:Object = {};

	protected var navigator:ViewingsModel;
	protected var topWin:DisplayObject;

	//карта windowObject:id
	protected var windows:Dictionary = new Dictionary();
	//карта id:WindowObject
	protected var windowsMap:Object = {};

	/**
	 * кеширование окон - если включить, менеджер будет кешировать окна по имени окна.
	 * Бывает полезно, есть есть сложно удаляемые из памяти окна пересоздание которых
	 * приводит к большому росту числа объектов.
	 * TODO: сделать для случая одно имя - несколько окон
	 */
	protected var cacheWindows:Boolean = true;

	/**
	 * родитель для окон и модального щита
	 */
	public var holder:DisplayObjectContainer;
	
	protected var modalColor:uint = 0x000000;
	protected var modalAlpha:Number = .6;

	protected var modalHolder:Sprite;

	public function ViewingsManager(navigator:ViewingsModel)
	{
		this.navigator = navigator;

		init();
	}

	protected function init():void
	{
		navigator.addEventListener(ViewingsModelEvent.ADD_VIEW, onNavigator);
		navigator.addEventListener(ViewingsModelEvent.UPDATE_VIEW, onNavigator);
		navigator.addEventListener(ViewingsModelEvent.CLOSE_VIEW, onNavigator);

		BindingUtils.bindSetter(setModal, navigator, "modal");
	}

	/**
	 * Делает модальным весь интерфейс, кроме окон
	 * @param value
	 *
	 */
	protected function setModal(value:Boolean):void
	{
		if (!modalHolder)
		{
			modalHolder = new Sprite();
			modalHolder.mouseEnabled = false;
		}
		if (holder && holder.stage)
		{
			holder.addChildAt(modalHolder, 0);
			holder.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
			drawModalShield();
		}

		modalHolder.visible = value;
	}

	protected function onStageResize(event:Event = null):void
	{
		if(navigator.modal)
			drawModalShield();
	}

	protected function drawModalShield():void
	{
		modalHolder.graphics.clear();
		Graph.drawFillRec(modalHolder.graphics, 0, 0, holder.stage.stageWidth, holder.stage.stageHeight, modalColor, modalAlpha);
	}

	private function onNavigator(event:ViewingsModelEvent):void
	{
		if (event.type == ViewingsModelEvent.ADD_VIEW)
		{
			showWindow(event.name, event.id, event.modal, event.params);
		}
		else if (event.type == ViewingsModelEvent.CLOSE_VIEW)
		{
			closeWindowById(event.id);
		}
		else if (event.type == ViewingsModelEvent.UPDATE_VIEW)
		{
			updateWindow(event.id, event.params);
		}
	}

	/**
	 * Кеш созданных экранов по id экрана.
	 * Кеширование экранов введено для ускорения процесса создания экранов
	 */
	protected var screensCache:Object = {};

	protected function showWindow(name:String, id:String, modal:Boolean, params:Object = null):void
	{
		var settings:Object = SETTINGS_MAP[name] || {};
		var winHolder:DisplayObjectContainer = settings.holder || holder;

		if (!winHolder)
		{
			Logger.warning(this, "showWindow:: there isn't parent for windows");
			return;
		}

		var winClass:Class = SCREENS_MAP[name];
		
		var cacheWindow:Boolean = ("cache" in settings) ? settings.cache : true;
		var winIndex:int = ("index" in settings) ? int(settings.index) : -1;

		var created:Boolean = false;

		if (winClass || screensCache[name])
		{
			topWin = screensCache[name];

			//try/catch блок создания окна
			try
			{
				var paramsPassed:Boolean = false;
				if (!topWin)
				{
					try
					{
						topWin = new winClass(params);
						paramsPassed = true;
					}
					catch (error:Error)
					{
						topWin = new winClass();
					}
				}

				if(cacheWindows && cacheWindow)
					screensCache[name] = topWin;

				topWin.name = name;

				winIndex == -1 ? winHolder.addChild(topWin) : winHolder.addChildAt(topWin, Math.max(0, Math.min(winIndex, winHolder.numChildren-1)));

				if (!paramsPassed)
				{
					if(topWin.hasOwnProperty("params"))
						topWin["params"] = params;
					else if(params && topWin.hasOwnProperty("data"))
						topWin["data"] = params.data;
				}

				//if(params)
					arrangeWindow(topWin, params ? params.position : null);

				windows[topWin] = id;
				windowsMap[id] = topWin;
				//слушаем REMOVED_FROM_STAGE, чтобы быть уверенными. что окно будет удалено из списков, для предотвращения ликов
				topWin.addEventListener(Event.REMOVED_FROM_STAGE, onWindowRemoved);

				Logger.debug(this, "showWindow ", name, ", params = ", params);
				created = true;
			}
			catch (error:Error)
			{
				//окно не создалось по каким-либо причинам (как правило из-за кривых скинов и отсутсвия try/catch блока при парсинге скина
				//удаляем окно, в том числе из модели.
				Logger.error(this, "showWindow : ", error.getStackTrace());
				created = false;
				closeWindowById(id);
				navigator.closeWindow(id);
			}
		}
		else
		{
			Logger.warning(this, "no window bind to \""+ name+ "\" id");
		}

		if (modal && created)
			makeWindowModal(topWin as DisplayObjectContainer)
	}

	protected function onWindowRemoved(event:Event):void
	{
		removeWindow(event.target as DisplayObject, false);
	}

	/**
	 * Удаляет окно из менеджера и модели навигатора со всеми ссылками на него и данными (кроме кеша).
	 * Вызывается из самого окна через события.
	 * @param window
	 * @param removeFromDisplayList
	 *
	 */
	protected function removeWindow(window:DisplayObject, removeFromDisplayList:Boolean = true):void
	{
		var windowId:String = windows[window];

		if (window && windowId)
		{
			closeWindowById(windowId, removeFromDisplayList);
			navigator.closeWindow(windowId);
		}
		else
		{
			Logger.warning(this, "::onWindowRemoved, window " + window + " is not registered");
		}

	}

	protected function updateWindow(id:String, params:ViewParams):void
	{
		var window:DisplayObject = windowsMap[id];

		if (window && window.hasOwnProperty("params"))
		{
			window["params"] = params;
			//if(params)
				arrangeWindow(window, params ? params.position : null);
		}

	}

	/**
	 * Удаляет окно и все ссылки на него из менеджера
	 * @param id
	 * @param removeFromDisplayList
	 *
	 */
	protected function closeWindowById(id:String, removeFromDisplayList:Boolean = true):void
	{
		var window:DisplayObject = windowsMap[id];
		delete windowsMap[id];
		delete windows[window];

		if (window && window.parent && removeFromDisplayList)
		{
			window.removeEventListener(Event.REMOVED_FROM_STAGE, onWindowRemoved);
			window.parent.removeChild(window);
		}
	}

	/**
	 * FYI: лучше реализовать окном интерфейс IModal, что модальный щит вел себя корректно при ресайзе/смещении окна
	 * @param window
	 *
	 */
	protected function makeWindowModal(window:DisplayObjectContainer):void
	{
		if (!holder || !holder.stage || !window)
			return;

		//если окно само умеет делать себя модальным, пусть делает.
		if(window is IModal)
		{
			IModal(window).setModal(true);
		}else
		{
			var settings:Object = SETTINGS_MAP[window.name] || {};
			var modalHolder:Sprite = window.numChildren > 0 ? window.getChildAt(0) as Sprite : new Sprite();
			if (!modalHolder || modalHolder.name != "modalHolder")
				modalHolder = new Sprite();

			modalHolder.name = "modalHolder";
			window.addChildAt(modalHolder, 0);

			var mColor:uint = ("modalColor" in settings) ? settings.modalColor : modalColor;
			var mAlpha:Number = ("modalAlpha" in settings) ? settings.modalAlpha : 0;
			modalHolder.graphics.clear();
			Graph.drawFillRec(modalHolder.graphics, 0, 0, holder.stage.stageWidth, holder.stage.stageHeight, mColor, mAlpha);
			modalHolder.mouseEnabled = false;

			var p:Point = new Point(-window.x, -window.y);
			p = holder.stage.localToGlobal(p);
			modalHolder.x = p.x;
			modalHolder.y = p.y;
		}
	}

	protected function arrangeWindow(window:DisplayObject, point:Point = null):void
	{
		var settings:Object = SETTINGS_MAP[window.name] || {};
		if(settings.skipArrange)
			return;

		if (point)
		{
			window.x = point.x;
			window.y = point.y;
		}
		
		
		if(settings.checkBounds)
		{
			// Если окно вылезло за экран, изменяем его координаты, чтобы его было видно
			if (window.x < 0)
				window.x = 0;
			if (window.y < 0)
				window.y = 0;
			
			if(window.stage)
			{
				if (window.x + window.width > window.stage.stageWidth)
					window.x = window.stage.stageWidth - window.width;
				if (window.y + window.height > window.stage.stageHeight)
					window.y = window.stage.stageHeight - window.height;
			}
		}
		
	}
	
	public function registerViewing(view:Object, name:String, settings:Object = null):void
	{
		if(view is DisplayObject)
			screensCache[name] = view;
		else if(view is Class)
			SCREENS_MAP[name] = view;
		else
		{
			Logger.error(this, "registerViewing, view should be DisplayObject or Class");
			return;
		}
		
		SETTINGS_MAP[name] = settings;
	}
	
}
}