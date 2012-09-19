package lib.core.ui.list
{
import lib.core.ui.controls.ToggleButton;
import lib.core.ui.layout.ILayout;
import lib.core.ui.layout.Valign;

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

/**
 * Лист с горизонтальной прокруткой и тремя кнопками прокрутки - поэлементно, постранично, на всю длину.
 * Usage:
 * 		var list:HorizontallList = new HorizontallList();
 * 		list.width = 400;
 * 		list.height = 80;
 * 		list.countLines = 6;
 * 		list.countInLine = 1;
 * 		list.itemRenderer = MyItemRenderer;
 * 		list.dataProvider = [{id:1, label:1}, {id2:label2}]
 */

public class HorizontalList extends BaseScrollList
{
	protected var rightArrowBtn:InteractiveObject;
	protected var rightArrow2Btn:InteractiveObject;
	protected var rightArrow3Btn:InteractiveObject;

	protected var leftArrowBtn:InteractiveObject;
	protected var leftArrow2Btn:InteractiveObject;
	protected var leftArrow3Btn:InteractiveObject;

	/**
	 * сколько элементов скролить на страницу (по клику на вторую кнопку)
	 */
	public var scrollPageNum:int = 5;

	/**
	 * расстояние между кнопками и контентом
	 */
	protected var _hSpacing:Number = 0;
	public function get hSpacing():Number
	{
		return _hSpacing;
	}
	public function set hSpacing(value:Number):void
	{
		_hSpacing = value;
		//Если задали вручную, сбрасываем флаг
		autoSpacing = false;
	}

	/**
	 * автоматически подгонять расстояние hSpacing, чтобы в ширину списка влезало целое число элементов
	 * При выставлении этого поля в true, параметр hSpacing вручную менять не надо
	 */
	private var _autoSpacing:Boolean = true;
	public function get autoSpacing():Boolean
	{
		return _autoSpacing;
	}
	public function set autoSpacing(value:Boolean):void
	{
		_autoSpacing = value;
		_autoLayoutSpacing = false;
	}
	
	/**
	 * автоматически подгонять расстояние hSpacing у layout, чтобы в ширину списка влезало целое число элементов
	 */
	private var _autoLayoutSpacing:Boolean;
	public function get autoLayoutSpacing():Boolean
	{
		return _autoLayoutSpacing;
	}
	public function set autoLayoutSpacing(value:Boolean):void
	{
		_autoLayoutSpacing = value;
		_autoSpacing = false;
	}

	public var minLayoutSpacing:Number = 0;
	
	protected var leftButtons:Sprite;
	protected var rightButtons:Sprite;

	protected var buttonsWidth:Number;

	protected var _buttonsAlignH:String = Valign.MIDDLE;

	/**
	 * Автоматически прятать кнопки если нечего скролить
	 * Если false кнопки дизейбляться, но остаются видимыми
	 */
	public var autoBtnPolicy:Boolean;

	public function HorizontalList(layout:ILayout = null)
	{
		super(layout, DIRECTION_HORIZONTAL);
	}

	override protected function init():void
	{
		useScrollBar = false;

		super.init();

		addChild(leftButtons = new Sprite());
		addChild(rightButtons = new Sprite());

		//если кнопка задана в наследниках используем ее, если не задана создаем дефолтную
		rightArrowBtn = rightArrowBtn || createRightArrowBtn();
		rightArrowBtn.addEventListener(MouseEvent.CLICK, onBtnArrowDown);

		rightArrow2Btn 	= rightArrow2Btn || createRightArrow2Btn();
		rightArrow2Btn.addEventListener(MouseEvent.CLICK, onBtnArrowRight);

		rightArrow3Btn 	= rightArrow3Btn || createRightArrow3Btn();
		rightArrow3Btn.addEventListener(MouseEvent.CLICK, onBtnArrowRight);

		rightButtons.addChild(rightArrowBtn);
		rightButtons.addChild(rightArrow2Btn);
		rightButtons.addChild(rightArrow3Btn);

		leftArrowBtn 	= leftArrowBtn || createLeftArrowBtn();
		leftArrowBtn.addEventListener(MouseEvent.CLICK, onBtnArrowUp);

		leftArrow2Btn 	= leftArrow2Btn || createLeftArrow2Btn();
		leftArrow2Btn.addEventListener(MouseEvent.CLICK, onBtnArrowLeft);

		leftArrow3Btn 	= leftArrow3Btn || createLeftArrow3Btn();
		leftArrow3Btn.addEventListener(MouseEvent.CLICK, onBtnArrowLeft);

		leftButtons.addChild(leftArrowBtn);
		leftButtons.addChild(leftArrow2Btn);
		leftButtons.addChild(leftArrow3Btn);

		buttonsWidth = rightButtons.width + leftButtons.width;
		updateButtons();
	}

	protected function createLeftArrowBtn():InteractiveObject {
		return createButton();
	}
	
	protected function createLeftArrow2Btn():InteractiveObject {
		return createButton();
	}
	
	protected function createLeftArrow3Btn():InteractiveObject {
		return createButton();
	}
	
	protected function createRightArrowBtn():InteractiveObject {
		return createButton();
	}
	
	protected function createRightArrow2Btn():InteractiveObject {
		return createButton();
	}
	
	protected function createRightArrow3Btn():InteractiveObject {
		return createButton();
	}
	
	protected function createButton():InteractiveObject {
		var button:SimpleButton = new SimpleButton();
		var upState:Sprite = new Sprite();
		var overState:Sprite = new Sprite();
		var downState:Sprite = new Sprite();
		with (upState.graphics) {
			lineStyle(0, 0x0000ff, 1);
			beginFill(0xffff00, 1);
			lineTo(0, 10);
			lineTo(10, 5);
			lineTo(0, 0);
			endFill();
		}
		with (overState.graphics) {
			lineStyle(0, 0x0000ff, 1);
			beginFill(0xff0000, 1);
			lineTo(0, 10);
			lineTo(10, 5);
			lineTo(0, 0);
			endFill();
		}
		with (downState.graphics) {
			lineStyle(0, 0x0000ff, 1);
			beginFill(0xffff00, 1);
			lineTo(0, 10);
			lineTo(10, 5);
			lineTo(0, 0);
			endFill();
		}
		button.upState = upState;
		button.overState = overState;
		button.downState = downState;
		button.hitTestState = upState;
		return button;
	}

	protected var _showScroll1:Boolean = true;
	public function set showScroll1(value:Boolean):void{
		_showScroll1 = value;
		if (rightArrowBtn && leftArrowBtn)
			rightArrowBtn.visible = leftArrowBtn.visible = value;
	}
	
	protected var _showScroll2:Boolean;
	public function set showScroll2(value:Boolean):void{
		_showScroll2 = value;
		if (rightArrow2Btn && leftArrow2Btn)
			rightArrow2Btn.visible = leftArrow2Btn.visible = value;
	}
	
	protected var _showScroll3:Boolean;
	public function set showScroll3(value:Boolean):void{
		_showScroll3 = value;
		if (rightArrow3Btn && leftArrow3Btn)
			rightArrow3Btn.visible = leftArrow3Btn.visible = value;
	}
	
	/**
	 * Вертикальный пэддинг для крайних кнопок (как они прижимаются к центру)
	 */
	protected var _vPadding:int;
	public function get vPadding():int
	{
		return _vPadding;
	}
	public function set vPadding(value:int):void
	{
		_vPadding = value;
		updateLayout();
	}

	override protected function get contentWidth():Number
	{
		return width - buttonsWidth - 2*hSpacing;
	}
	
	override public function get maxScrollPosition():Number
	{
		if (cyclic)
			return Number.MAX_VALUE;
		else
			return Math.max(0, contentSize - contentWidth);
	}
	
	override protected function updateLayout():void
	{
		super.updateLayout();

		if (leftButtons && rightButtons)
		{
			contentScrollRect.width = width - leftButtons.width - rightButtons.width - 2*hSpacing;
			contentClip.scrollRect = contentScrollRect;
			leftButtons.x = 0;
			rightButtons.x = Math.round(width - rightButtons.width);

			leftArrowBtn.x 	= Math.round(leftButtons.width/2 	- leftArrowBtn.width/2);
			leftArrow2Btn.x = Math.round(leftButtons.width/2 	- leftArrow2Btn.width/2);
			leftArrow3Btn.x = Math.round(leftButtons.width/2 	- leftArrow3Btn.width/2);

			rightArrowBtn.x  = Math.round(rightButtons.width/2 - rightArrowBtn.width/2);
			rightArrow2Btn.x = Math.round(rightButtons.width/2 - rightArrow2Btn.width/2);
			rightArrow3Btn.x = Math.round(rightButtons.width/2 - rightArrow3Btn.width/2);

			leftArrowBtn.y 	= vPadding;
			leftArrow2Btn.y = Math.round(height/2 - leftArrow2Btn.height/2);
			leftArrow3Btn.y = Math.round(height - leftArrow3Btn.height - vPadding);

			rightArrowBtn.y  = vPadding;
			rightArrow2Btn.y = Math.round(height/2 - rightArrow2Btn.height/2);
			rightArrow3Btn.y = Math.round(height - rightArrow3Btn.height - vPadding);

			if (contentClip)
				contentClip.x = Math.round(leftButtons.width + hSpacing);
		}
	}

	override protected function measureScrollSize():void
	{
		//Если стоит режим автовычисления отступов, выставляем списку ширину без учета отступа, 
		//поскольку список считает количество вмещаемых элементов по этой ширине
		if(autoSpacing)
		{
			if (list)
				list.userWidth = width - buttonsWidth;
		}
		super.measureScrollSize();
	}
	
	override protected function commitScrollSize():void
	{
		super.commitScrollSize();
		
		if(autoSpacing)
		{
			//округяем вверх, чтобы контент "не торчал" из под маски
			var spacing:Number = isHorizontal ?	layout.settings.hSpacing :layout.settings.vSpacing;
			_hSpacing = (width - buttonsWidth - countLines*scrollSize + spacing)/2;
		}
		else if(autoLayoutSpacing)
		{
			var contentWidth:Number = this.contentWidth;
			var hPadding:int = Object(layout).hasOwnProperty("hPadding") ? layout["hPadding"] : 0;
			
			var child:DisplayObject = createMeasuredChild();
			var childWidth:Number = child ? child.width : 1;
			
			//сколько целых элементов
			var n:int = Math.floor((contentWidth - 2*hPadding + minLayoutSpacing)/(childWidth + minLayoutSpacing));
			var layoutSpacing:Number = n > 1 ? (contentWidth - 2*hPadding - n*childWidth)/(n - 1) : 0;
			
			if (Object(layout).hasOwnProperty("hSpacing"))
				layout["hSpacing"] = layoutSpacing;
			
			_scrollSize = childWidth + layoutSpacing;
			_countLines = n;
		}
		
		//Round current scrollPosition to int value
		scrollPosition = scrollSize*Math.round(scrollPosition/scrollSize);
		updateLayout();
	}

	override protected function checkAutoCenterContent():void
	{
		if (!content)
			return;

		if (autoCenterContent)
		{
			if(contentSize < size)
			{
				contentClip.x = int((width - contentSize)/2);
			}
			else
			{
				contentClip.x = leftButtons.x + leftButtons.width + hSpacing;
			}
		}
	}

	protected function onBtnArrowUp(event:MouseEvent):void
	{
		stepScrollPosition(-scrollSize);
	}

	protected function onBtnArrowDown(event:MouseEvent):void
	{
		stepScrollPosition(scrollSize);
	}

	protected function onBtnArrowRight(event:MouseEvent):void
	{
		var btn:InteractiveObject = event.target as InteractiveObject;
		if (btn == rightArrow2Btn)
			stepScrollPosition(scrollPageNum*scrollSize);
		else if (btn == rightArrow3Btn)
			scrollPosition = maxScrollPosition;
	}

	protected function onBtnArrowLeft(event:MouseEvent):void
	{
		var btn:InteractiveObject = event.target as InteractiveObject;
		if(btn == leftArrow2Btn)
			stepScrollPosition(-scrollPageNum*scrollSize);
		else if(btn == leftArrow3Btn)
			scrollPosition = minScrollPosition;
	}

	protected function updateButtons():void
	{
		var leftEnabled:Boolean = scrollPosition > minScrollPosition;
		var rightEnabled:Boolean = maxScrollPosition > scrollPosition;
		
		updateButton(leftArrowBtn, leftEnabled);
		updateButton(leftArrow2Btn, leftEnabled);
		updateButton(leftArrow3Btn, leftEnabled);
		
		updateButton(rightArrowBtn, rightEnabled);
		updateButton(rightArrow2Btn, rightEnabled);
		updateButton(rightArrow3Btn, rightEnabled);
		
		if (leftButtons)
			leftButtons.visible = leftEnabled || (!leftEnabled && !autoBtnPolicy);
		if (rightButtons)
			rightButtons.visible = rightEnabled || (!rightEnabled && !autoBtnPolicy);
	}

	private function updateButton(btn:InteractiveObject, enabled:Boolean = true):void
	{
		if (btn is ToggleButton)
			ToggleButton(btn).enabled = enabled;
		else
			btn.mouseEnabled = enabled;
	}
	
	override protected function onEnterFrame(event:Event = null):void
	{
		super.onEnterFrame(event);
		updateButtons();
	}
}
}