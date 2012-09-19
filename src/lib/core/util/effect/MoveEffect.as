package lib.core.util.effect
{
import flash.display.DisplayObject;
import flash.geom.Point;

/**
 * Эффект перемещения в точку
 */
public class MoveEffect extends Effect
{
	protected var showPosition:Point;
	protected var hidePosition:Point;

	public function MoveEffect(target:DisplayObject, duration:Number=1, showPosition:Point = null, hidePosition:Point = null)
	{
		this.showPosition = showPosition;
		this.hidePosition = hidePosition ? hidePosition : target ? new Point(target.x, target.y) : new Point(0, 0);

		super(target, duration);
	}

	override public function show(anim:Boolean = true):void
	{
		if (tween)
		{
			tween.setValue("x", showPosition.x);
			tween.setValue("y", showPosition.y);
		}
		super.show(anim);
	}

	override public function hide(anim:Boolean = true):void
	{
		if (tween)
		{
			tween.setValue("x", hidePosition.x);
			tween.setValue("y", hidePosition.y);
		}
		super.hide(anim);
	}

	override protected function commitTarget():void
	{
		super.commitTarget();
		if (!hidePosition)
			hidePosition = new Point(target.x, target.y);
	}
}
}