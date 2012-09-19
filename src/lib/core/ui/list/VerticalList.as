package lib.core.ui.list
{
import lib.core.ui.layout.ILayout;

import flash.display.InteractiveObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.events.Event;
import flash.events.MouseEvent;

/**
 * Вертикальный лист с кнопками перемотки по центру.
 * 
 */		
public class VerticalList extends BaseScrollList
{
	protected var buttonUp:InteractiveObject;
	protected var buttonDn:InteractiveObject;
	
	//расстояние между кнопками и контентом
	public var buttonsPadding:Number = 3;
	protected var buttonsHeight:Number;
	
	/**
	 * Автоматически прятать кнопки если нечего скролить
	 */
	public var autoBtnPolicy:Boolean = true;
	
	public function VerticalList(layout:ILayout = null)
	{
		super(layout, DIRECTION_VERTICAL);
	}
	
	override protected function init():void
	{
		useScrollBar = false;
		
		super.init();
		
		buttonUp = createButtonUp();
		if (buttonUp) {
			buttonUp.addEventListener(MouseEvent.CLICK, onButtonUp);
			addChild(buttonUp);
		}
		
		buttonDn = createButtonDn();
		if (buttonDn) {
			buttonDn.addEventListener(MouseEvent.CLICK, onButtonDn);
			addChild(buttonDn);
		}
		
		if (buttonUp && buttonDn)
			buttonsHeight = buttonUp.height + buttonDn.height;
	}
	
	protected function createButtonUp():InteractiveObject {
		var button:SimpleButton = new SimpleButton();
		var upState:Shape = new Shape();
		with (upState.graphics) {
			lineStyle(0, 0x0000ff, 1);
			beginFill(0xffff00, 1);
			moveTo(0, 10);
			lineTo(10, 10);
			lineTo(5, 0);
			lineTo(0, 10);
			endFill();
		}
		button.upState = upState;
		button.overState = upState;
		button.downState = upState;
		button.hitTestState = upState;
		return button;
	}
	
	protected function createButtonDn():InteractiveObject {
		var button:SimpleButton = new SimpleButton();
		var upState:Shape = new Shape();
		with (upState.graphics) {
			lineStyle(0, 0x0000ff, 1);
			beginFill(0xffff00, 1);
			lineTo(10, 0);
			lineTo(5, 10);
			lineTo(0, 0);
			endFill();
		}
		button.upState = upState;
		button.overState = upState;
		button.downState = upState;
		button.hitTestState = upState;
		return button;
	}
	
	override protected function get contentHeight():Number
	{
		return height - buttonsHeight - 2*buttonsPadding;
	}
	
	override public function get maxScrollPosition():Number 
	{
		return Math.max(0, contentSize - contentHeight);
	}
	
	override protected function updateLayout():void 
	{
		super.updateLayout();
		
		if(!contentClip || !buttonUp || !buttonDn)
			return;
		
		buttonUp.x = Math.round((width - buttonUp.width)/2);
		buttonDn.x = Math.round((width - buttonDn.width)/2);
		buttonDn.y = height - buttonDn.height;
		
		contentClip.y = buttonUp.height + buttonsPadding; 
		contentScrollRect = contentClip.scrollRect;
		contentScrollRect.height = height - buttonUp.height - buttonDn.height - 2*buttonsPadding;
		contentClip.scrollRect = contentScrollRect;
	}
	
	protected function updateButtons():void
	{
//		buttonUp.visible = scrollPosition > minScrollPosition;
//		buttonDn.visible = maxScrollPosition > scrollPosition;
	}
	
	protected function onButtonUp(event:MouseEvent):void 
	{
		stepScrollPosition(-scrollSize);
	}
	
	protected function onButtonDn(event:MouseEvent):void 
	{
		stepScrollPosition(scrollSize);
	}
	
	override protected function onEnterFrame(event:Event = null):void
	{
		super.onEnterFrame(event);
		
		if(autoBtnPolicy)
		{
			updateButtons();
		}
	}
}
}