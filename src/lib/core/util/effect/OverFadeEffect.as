package lib.core.util.effect
{
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;

public class OverFadeEffect extends FadeEffect
{
	protected var mouseTarget:DisplayObject;

	public function OverFadeEffect(mouseTarget:DisplayObject, target:DisplayObject, duration:Number=1, showAlpha:Number = 1, hideAlpha:Number = 0)
	{
		super(target, duration, showAlpha, hideAlpha);

		this.mouseTarget = mouseTarget;

		if (mouseTarget)
		{
			mouseTarget.addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			mouseTarget.addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
		}
	}

	protected function onRollOver(event:MouseEvent):void
	{
		show();
	}

	protected function onRollOut(event:MouseEvent):void
	{
		hide();
	}

}
}