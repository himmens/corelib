package lib.core.ui.managers
{
import flash.display.InteractiveObject;
import flash.display.Stage;
import flash.events.EventDispatcher;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;

[Event (name="keyDown", type="flash.events.KeyboardEvent")]
[Event (name="keyUp", type="flash.events.KeyboardEvent")]

/**
 * Утилитный класс - диспатчит события клавиатуры, независимо от текущего фокуса в рамках приложения, решает проблему с пропущенными
 * событиями клавиатуры и необходимости кликать на объекты вручную передавая фокус.
*/
public class KeyboardDispatcher extends EventDispatcher
{
	protected var stage:Stage;

	/**
	 *
	 * @param stage Stage - необходим, чтобы получать ссылку на текущий фокус обьект
	 *
	 */
	public function KeyboardDispatcher(stage:Stage)
	{
		this.stage = stage;

		updateFocus();
	}

	protected function updateFocus():void
	{
		listenFocus(stage.focus || stage);
	}

	private function onFocus(even:FocusEvent):void
	{
		//Logger.debug(this, "onFocus: type = "+even.type ,"target = ", even.target+", stage.focus = "+stage.focus);
		updateFocus();
	}

	private var focusTarget:InteractiveObject;

	private function listenFocus(target:InteractiveObject):void
	{
		if(focusTarget)
		{
			focusTarget.removeEventListener(FocusEvent.KEY_FOCUS_CHANGE, onFocus);
			focusTarget.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, onFocus);
			focusTarget.removeEventListener(FocusEvent.FOCUS_IN, onFocus);
			focusTarget.removeEventListener(FocusEvent.FOCUS_OUT, onFocus);
		}

		focusTarget = target;
		listenKeyboard(focusTarget);

		//по всем событиям фокуса с текущим диспатчером обновляем обьект диспатчера
		//TODO: другой вариант более надежные - обновлять по enterFrame
		focusTarget.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, onFocus, false, 0, true);
		focusTarget.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, onFocus, false, 0, true);
		focusTarget.addEventListener(FocusEvent.FOCUS_IN, onFocus, false, 0, true);
		focusTarget.addEventListener(FocusEvent.FOCUS_OUT, onFocus, false, 0, true);
	}

	private var kbTarget:InteractiveObject;
	private function listenKeyboard(target:InteractiveObject):void
	{
		if(kbTarget)
		{
			kbTarget.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyboard, false);
			kbTarget.removeEventListener(KeyboardEvent.KEY_UP, onKeyboard, false);
		}

		kbTarget = target;
		//kbTarget.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboard, false, 0, true);
		//kbTarget.addEventListener(KeyboardEvent.KEY_UP, onKeyboard, false, 0, true);

		kbTarget.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboard, false);
		kbTarget.addEventListener(KeyboardEvent.KEY_UP, onKeyboard, false);

		//Logger.debug(this, "listenKeyboard, kbTarget = "+kbTarget);
	}

	protected function onKeyboard(event:KeyboardEvent):void
	{
		//Logger.debug(this, "onKeyboard, key = "+event.charCode+", type = "+event.type);
		dispatchEvent(event);
	}
}
}