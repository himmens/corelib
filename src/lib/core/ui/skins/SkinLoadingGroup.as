package lib.core.ui.skins
{
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.utils.Dictionary;

import lib.core.ui.skins.SkinDynamic;

/**
 * все скины загрузились
 */
[Event (name="complete", type="flash.events.Event")]

/**
 * Помощник для отслеживания загрузки группы SkinDynamic, удобен для случаев, когда надо долждаться загрузки группы
 * разрозненных динамических скинов.
 * Использование:
 *
 * var group:SkinLoadingGroup = new SkinLoadingGroup();
 * group.addEventListener(Event.COMPETE, onSkinsLoaded);
 *
 * group.handleSkin(skin1);
 * group.handleSkin(skin2);
 * group.handleSkin(skin3);
 */
public class SkinLoadingGroup extends EventDispatcher
{
	protected var _total:int;
	public function get total():int{return _total;};

	protected var _complete:Boolean = true;
	public function get complete():Boolean{return _complete;};

	protected var _numErrors:int;
	/**
	 * число ошибок в процессе загрузки скинов (сколько ксинов не загрузилось)
	 * @return
	 *
	 */
	public function get numErrors():int{return _numErrors;};

	protected var map:Dictionary;

	public function SkinLoadingGroup()
	{
		super();

		reset();
	}

	public function reset():void
	{
		_total = 0;
		_numErrors = 0;
		_complete = true;
		map = new Dictionary(true);
	}

	public function handleSkin(skin:SkinDynamic):SkinDynamic
	{
		if(skin && skin.loading && !map[skin])
//		if(skin && !map[skin])
		{
			_total++;
			_complete = false;
			map[skin] = {skin:skin};

			skin.addEventListener(ErrorEvent.ERROR, onSkin, false, 0, true);
			skin.addEventListener(Event.COMPLETE, onSkin, false, 0, true);
		}

		return skin;
	}

	protected function onSkin(event:Event):void
	{
		_total--;
		if(event is ErrorEvent) _numErrors++;

		var skin:SkinDynamic = event.target as SkinDynamic;
		delete map[skin];

		if(_total <= 0)
		{
			_complete = true;
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}
}