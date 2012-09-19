package lib.core.viewing
{
import lib.core.util.log.Logger;

import flash.events.Event;
import flash.events.EventDispatcher;

[Event (name="addView", type="com.kamagames.core.model.navigator.NavigatorModelEvent")] 
[Event (name="closeView", type="com.kamagames.core.model.navigator.NavigatorModelEvent")] 
[Event (name="updateView", type="com.kamagames.core.model.navigator.NavigatorModelEvent")] 

/**
 * Модель визуальных элементов. Основной функционал - разные политики показа view, см. комментарии и примеры к каждой из политик 
 */
public class ViewingsModel extends EventDispatcher
{
	/**
	 * политика показа окна - очередь:
	 *
	 * окно добавляется в очередь (окна из очереди открываются по очереди, только когда нет любых других открытых окон)
	 */
	public static const POLICY_QUEUE:int 	= 0x01;
	/**
	 * политика показа окна - дочерние/родитесльские окна
	 *
	 * 	Если уже есть открытое окно, можно открыть только его дочернее окно, либо окно с политикой POLICY_SINGLE.
	 */
	public static const POLICY_CHILD:int 	= 0x02;
	/**
	 * политика показа окна - Одно окно:
	 *
	 * все текущие открыте окна будут закрыты
	 */
	public static const POLICY_SINGLE:int 	= 0x04;

	/**
	 * настройки окон в формате:
	 * {
	 * 	parents: Array - массив окон, которые могут быть родительскими к данному окну.
	 * 			Если уже открыто, можно открыть только его дочернее окно.
	 * 			Поле true означает, что окно является дочерним ко всем окнам, т.е. будет показано
	 * 			при любых открытых окнах.
	 * 			Имеет смысл только при политике POLICY_CHILD
	 *	
	 * 	singlePolicyParents: Array - массив view к которому будет применена политика POLICY_SINGLE, т.е. закроются только эти view.
	 * 			на базе этого массива можно реализовать показ экранов, перечислив в этом массиве экраны одного стека. 
	 * 			Если массив не задан закроются все view
	 * 
	 * 
	 * 	excludedParents: Array - массив окон, которые не могут быть родительскими к данному окну (для политики POLICY_CHILD).
	 * 			Пример: Хотим окно ревардов, которое показывается всегда, а для самого себя выстраивается в очередь:
	 * 			{parents:true, excludedParents:[Screens.REWARD], policy:POLICY_CHILD | POLICY_QUEUE, multi:true};
	 *
	 * 	modal: окно будет модальным
	 * 	policy: политика открытия окна (что делать, если есть текущее топовое окно)
	 * 			Некоторые полотики можно совмещать:
	 *  		POLICY_CHILD | POLICY_SINGLE - при показе окна сначала смотрим на родителей (массив parents) и если топовое
	 * 				окно не является родителем то применяется POLICY_SINGLE.
	 * 			POLICY_CHILD | POLICY_QUEUE - так же сначала смотрим на родителя и если не родитель кладем окно в очередь
	 * 			Значение по умолчанию - POLICY_SINGLE
	 * 	multi: true || false (default value), если false, то данное окно можно создать только в одном экземпляре и
	 * 			если окно уже открыто, при повторном вызове showWindow открытое окно будет обновлено новыми данными.
	 * 			Если надо иметь возможность создавать несколько экземпляров окна - выставить в true
	 *  showFirst: true || false (default false), если false - окно добавляется в конец очереди, если true в начало.
	 * }
	 *
	 * Поля parents и queue являются взаимоисключающими, либо то, либо другое.
	 */
	protected var WIN_PARAMS_MAP:Object;

	protected var windowsId:Array = [];
	protected var windowsMap:Object = {};
	protected var queue:Array = [];

	private var _topName:String;
	private var topId:String;

	public function ViewingsModel()
	{
		super();
	}

	/**
	 * Добавить модуль в список видимых модулей.
	 * @param name
	 * @param params
	 * @return
	 *
	 */
	public function showWindow(name:String, params:ViewParams = null):String
	{
		return showWindowInternal({name:name, params:params});
	}

	protected function showWindowInternal(winObj:Object):String
	{
		var event:ViewingsModelEvent;
		var name:String = winObj.name;
		var params:ViewParams = winObj.params;

		var settings:Object = WIN_PARAMS_MAP[name] ? WIN_PARAMS_MAP[name] : {};
		var modal:Boolean = settings ? settings.modal : false;
		var obj:Object;
		winObj.modal = modal;

		//если такое окно уже открыто и оно не отмечено как multi, то апдейтим его
		for each(obj in windowsMap)
		{
			if (obj.name == name && !settings.multi)
			{
				obj.params = params;
				obj.modal = modal;
				event = new ViewingsModelEvent(ViewingsModelEvent.UPDATE_VIEW, name, obj.id, modal, params);
				dispatchEvent(event);
				return obj.id;
			}
		}

		var hasWindow:Boolean = _topName != null;

		Logger.debug(this, "showWindow: ",name, " topWin = ",_topName);

		var id:String = winObj.id;

		if(!id)
		{
			winObj.id = id = name+windowsId.length;
		}

		//проверяем можно ли открыть окно, если уже есть открытые окна
		if(hasWindow)
		{
			//по умолчанию - POLICY_SINGLE
			var policy:int = settings && settings.policy ? settings.policy : POLICY_SINGLE;
			var canShow:Boolean = false;

			if(policy & POLICY_CHILD)
			{
				//первый шаг - проверяем политику POLICY_CHILD
				//проверяем исключения родителей (для исключений нельзя показывать окно)
				var excludedParents:Array = settings ? settings.excludedParents : null;
				canShow = excludedParents ? excludedParents.indexOf(_topName) == -1 : true;

				//Если все ок, проверяем обычных родителей
				if (canShow)
				{
					var parents:Object = settings ? settings.parents : null;
					canShow = (parents == true) || (parents && parents.indexOf(_topName) >= 0);
				}
			}

			if(!canShow && (policy & POLICY_SINGLE))
			{
				//второй шаг - проверяем политику POLICY_SINGLE
				closeWindows(settings.singlePolicyParents);
				canShow = true;
			}

			//третий шаг - проверяем политику POLICY_QUEUE если предыдущие политики не разрешили показ окна
			if(!canShow && (policy & POLICY_QUEUE))
			{
				// Если был установлен флаг showFirst, то окно будет добавляться в начало очереди
				if(settings.showFirst)
				{
					queue.unshift(winObj);

				// Если флаг не был установлен, то окно будет устанавливаться в конец очереди
				}else
				{
					queue[queue.length] = winObj;
				}

				return id;
			}

			if(!canShow)
			{
				//окно не дочернее и не в очереди
				Logger.warning(this, "showWindow: нельзя открыть окно ",name," т.к. открыто окно ", _topName);
				return null;
			}
		}

		windowsMap[id] = winObj;
		windowsId[windowsId.length] = id;

		setTopName(name);

		topId = id;

		if(modal)
			this.modal = true;

		event = new ViewingsModelEvent(ViewingsModelEvent.ADD_VIEW, name, id, modal, params);
		dispatchEvent(event);

		return id;
	}

	protected function closeWindows(names:Array = null):void
	{
		_modal = 1;
		modal = false;

		if(names)
		{
			for each(var name:String in names)
			{
				closeWindowsByName(name);
			}
		}else
		{
			for each(var id:String in windowsId)
			{
				closeWindow(id);
			}
		}
	}

	/**
	 * Закрыает все ока с переданным именем
	 * @param name
	 *
	 */
	public function closeWindowsByName(name:String):void
	{
		var winObj:Object;
		for each(winObj in windowsMap)
		{
			if (winObj.name == name)
			{
				closeWindow(winObj.id);
			}
		}
	}

	/**
	 * закрыть окно по id
	 * @param id
	 *
	 */
	public function closeWindow(id:String):void
	{
		if(windowsMap[id])
		{
			var modal:Boolean = windowsMap[id].modal;
			if(modal)
				this.modal = false;

			windowsId.splice(windowsId.indexOf(id), 1);

			topId = windowsId[windowsId.length -1];
			setTopName(topId ? windowsMap[topId].name : null);

			var data:Object = windowsMap[id];
			var event:ViewingsModelEvent = new ViewingsModelEvent(ViewingsModelEvent.CLOSE_VIEW, data.name, id, data.modal, data.params);
			dispatchEvent(event);

			delete windowsMap[id];
		}

		showNextInQueue();
	}

	protected function showNextInQueue():void
	{
		if(queue.length > 0)
		{
			var winObj:Object = queue.shift();
			showWindowInternal(winObj);
		}
	}

	/**
	 * Флаг модальности. Выставляется в true для всех модальных окон, во время режима модальности не надо
	 * совершать никаких действий, отпралвять данные на сервер и т.п.
	 */
	protected var _modal:int = 0;

	public function set modal(value:Boolean):void
	{
		_modal += value ? 1 : -1;
		_modal = Math.max(0, _modal);

		dispatchEvent(new Event("modalChanged"));
	}

	[Bindable("modalChanged")]
	public function get modal():Boolean
	{
		return _modal > 0;
	}

	[Bindable("topNameChanged")]
	public function get topName():String
	{
		return _topName;
	}

	[Bindable("topNameChanged")]
	public function hasWindow(name:String):Boolean
	{
		return getViewDataByName(name) != null;
	}

	protected function setTopName(value:String):void
	{
		if (_topName != value)
		{
			_topName = value;
			dispatchEvent(new Event("topNameChanged"));
		}
	}
	
	protected function getViewDataByName(name:String):Object
	{
		for each(var obj:Object in windowsMap)
			if(windowsId.indexOf(obj.id) >= 0 && obj.name == name)
				return obj;
		
		return null;
		
	}
	
}
}