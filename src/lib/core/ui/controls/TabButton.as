package lib.core.ui.controls
{
import flash.display.SimpleButton;
import flash.text.TextFormat;

import lib.core.ui.skins.SkinsManager;

public class TabButton extends LabelButton
{
	public var labelFunction:Function;

	public function TabButton()
	{
		super();

		autoSize = false;
	}

	protected function init():void
	{
	}

	override public function set data(value:Object):void
	{
		super.data = value;

		label = labelFunction is Function ? labelFunction(value) : defaultLabelString(value);
		enabled = typeof(data) == "object" ? data.enabled != false : true;
		arrange();
	}

	protected function defaultLabelString(value:Object):String
	{
		return (typeof(data) == "object") && value.hasOwnProperty("label") ? value.label : String(value);
	}
}
}