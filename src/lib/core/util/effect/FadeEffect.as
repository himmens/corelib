package lib.core.util.effect
{
import flash.display.DisplayObject;

/**
 * Эффект появления через FadeIn/FadeOut
 */
public class FadeEffect extends Effect
{
	protected var showAlpha:Number;
	protected var hideAlpha:Number;

	public function FadeEffect(target:DisplayObject, duration:Number=1, showAlpha:Number = 1, hideAlpha:Number = 0)
	{
		this.showAlpha = showAlpha;
		this.hideAlpha = hideAlpha;

		super(target, duration);
	}

	override public function show(anim:Boolean = true):void
	{
		if (!enabled)
			return;
		
		if (tween)
		{
			tween.setValue("alpha", showAlpha);
		}
		super.show(anim);
	}

	override public function hide(anim:Boolean = true):void
	{
		if (!enabled)
			return;
		
		if (tween)
		{
			tween.setValue("alpha", hideAlpha);
		}
		super.hide(anim);
	}

}
}