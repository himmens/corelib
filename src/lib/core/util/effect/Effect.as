package lib.core.util.effect
{
import com.gskinner.motion.GTween;

import flash.display.DisplayObject;
import flash.events.EventDispatcher;

/**
 * Базовый класс для эффектов, основанных на GTween
 */
public class Effect extends EventDispatcher
{
	protected var tween:GTween;

	protected var shown:Boolean = false;

	public function Effect(target:DisplayObject, duration:Number=1, values:Object=null, props:Object=null, pluginData:Object=null)
	{
		_target = target;
		tween = new GTween(target, duration, values, props, pluginData);
	}

	public function show(anim:Boolean = true):void
	{
		if (!enabled)
			return;

		shown = true;
		anim ? tween.paused = false : tween.end();
	}

	public function hide(anim:Boolean = true):void
	{
		if (!enabled)
			return;

		shown = false;
		anim ? tween.paused = false : tween.end();
	}

	protected var _target:DisplayObject;
	public function set target(value:DisplayObject):void
	{
		if (_target != value)
		{
			_target = value;
			commitTarget();
		}
	}
	public function get target():DisplayObject
	{
		return _target;
	}

	protected function commitTarget():void
	{
		if (tween)
			tween.target = target;
	}

	protected var _enabled:Boolean = true;
	public function set enabled(value:Boolean):void
	{
		if (_enabled != value)
		{
			_enabled = value;
		}
	}
	public function get enabled():Boolean
	{
		return _enabled;
	}

	protected function commitEnabled():void
	{
	}

}
}