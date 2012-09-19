package lib.core.ui.scroll
{
import com.gskinner.motion.GTween;
import com.gskinner.motion.easing.Cubic;
import lib.core.ui.controls.ToggleButton;
import lib.core.ui.layout.Valign;
import lib.core.util.Graph;

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

/**
 * Скроллпейн с горизонтальной прокруткой
 *   (с тремя кнопками горизонтальной прокрутки - поэлементно, постранично, на всю длину)
 * 
 * TODO Убить и заменить на BaseScrollPane
 */
 
public class HorizontalScrollPaneToKill extends Sprite
{
	
	protected var background:Sprite;
	
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
	
	//клип для добавления контента
	protected var contentClip:Sprite;
	//прямоугольник маски отображения
	protected var contentScrollRect:Rectangle = new Rectangle();
	//прямоугольник маски отображения для анимации скролла
	protected var tweenScrollRect:Rectangle;
	
	//флаг на изменение вертикальной прокрутки
	protected var verticalScrollPositionChanged:Boolean;
	//флаг на изменение размеров компонента
	protected var sizeChanged:Boolean;
	
	//расстояние между кнопками и контентом
	public var hSpacing:Number = 3;
	

	protected var leftButtons:Sprite;
	protected var rightButtons:Sprite;
	
	protected var _buttonsAlignH:String = Valign.MIDDLE;
	
	//высота контента
	protected var contentWidth:Number=0;
	
	/**
	 * длительность анимации прокрутки в секундах
	 */
	public var animTime:Number = .3; 

	/**
	 * Автоматически прятать кнопки если нечего скролить
	 */
	public var autoBtnPolicy:Boolean = true; 
	
	/**
	 * Автоматически выравнивать контент по центру, если меньше размеров
	 */
	public var autoCenterContent:Boolean = false; 
	
	//флаг на изменение горизонтальной прокрутки
	protected var horizontalScrollPositionChanged:Boolean;
	
	public function HorizontalScrollPaneToKill()
	{
		super();
		
		init();
	}
	
	protected function init():void
	{
		background = new Sprite();
		addChild(background);
		Graph.drawFillRec(background.graphics, 0, 0, 1, 1, 0x000000, .0);
		
		addChild(leftButtons = new Sprite());
		addChild(rightButtons = new Sprite());
		
		//если кнопка задана в наследниках используем ее, если не задана создаем дефолтную
		rightArrowBtn 	= rightArrowBtn || new SimpleButton();
		rightArrowBtn.addEventListener(MouseEvent.CLICK, onBtnArrowDown);

		rightArrow2Btn 	= rightArrow2Btn || new SimpleButton();
		rightArrow2Btn.addEventListener(MouseEvent.CLICK, onBtnArrowRight);

		rightArrow3Btn 	= rightArrow3Btn || new SimpleButton();
		rightArrow3Btn.addEventListener(MouseEvent.CLICK, onBtnArrowRight);
		
		rightButtons.addChild(rightArrowBtn);
		rightButtons.addChild(rightArrow2Btn);
		rightButtons.addChild(rightArrow3Btn);
		
		leftArrowBtn 	= leftArrowBtn || new SimpleButton();
		leftArrowBtn.addEventListener(MouseEvent.CLICK, onBtnArrowUp);

		leftArrow2Btn 	= leftArrow2Btn || new SimpleButton();
		leftArrow2Btn.addEventListener(MouseEvent.CLICK, onBtnArrowLeft);

		leftArrow3Btn 	= leftArrow3Btn || new SimpleButton();
		leftArrow3Btn.addEventListener(MouseEvent.CLICK, onBtnArrowLeft);
		
		leftButtons.addChild(leftArrowBtn);
		leftButtons.addChild(leftArrow2Btn);
		leftButtons.addChild(leftArrow3Btn);
		
		//content
		contentClip = new Sprite();
		addChild(contentClip);
		contentClip.scrollRect = contentScrollRect;
		
		addEventListener(Event.ADDED_TO_STAGE, onStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onStage);
		
		update();
	}
	
	protected function onStage(event:Event):void
	{
		if(event.type == Event.ADDED_TO_STAGE)
		{
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onEnterFrame();
		}else
		{
			removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
	}
	
	
	//скролируемый элемент (добавляется в contentClip компонетнта)
	protected var _content:DisplayObject;
	public function set content(value:DisplayObject):void 
	{
		if(_content && contentClip && contentClip.contains(_content))
			contentClip.removeChild(_content);
		
		_content = value;
		
		if(_content && contentClip)
		{
			contentClip.addChild(_content);
			contentWidth = _content.width;
		}
	}

	protected var _horizontalScrollPosition:Number = 0;
	public function set horizontalScrollPosition(value:Number):void {	
		if(tweening && _useScrollTween)
			return;
		
		value = Math.min(Math.max(value, minHorizontalScrollPosition), maxHorizontalScrollPosition);
		if (_horizontalScrollPosition != value) {
			_horizontalScrollPosition = value;
			horizontalScrollPositionChanged = true;
			update();
		}
	}
	public function get horizontalScrollPosition():Number {	
		return _horizontalScrollPosition;
	}
	
	public function get minHorizontalScrollPosition():Number {
		return 0;
	}
	
	public function get maxHorizontalScrollPosition():Number {
		var res:Number = 0;
		var contentWidth:int = _content ? _content.width : 0;
		res = Math.max(0, contentWidth - _viewWidth);
		//res = Math.max(0, contentWidth -_width);
		return res;
	}
	
	//величина разовой прокрутки контента	
	protected var _horizontalLineScrollSize:Number = 1;
	public function get horizontalLineScrollSize():Number {
		return _horizontalLineScrollSize;
	}
	
	public function set horizontalLineScrollSize(value:Number):void {
		_horizontalLineScrollSize = value > 0 ? value : 1;
	}
	
	public function set scrollIndex(value:int):void
	{
		horizontalScrollPosition = value*horizontalLineScrollSize;
	}
	
	public function get scrollIndex():int
	{
		return Math.ceil(horizontalScrollPosition/horizontalLineScrollSize);
	}
	
	//выравнивание кнопок
//	public function get buttonsAlign():String {
//		return _buttonsAlign;
//	}
//	public function set buttonsAlign(value:String):void {
//		_buttonsAlign = value;
//		updateLayout();
//	}
	
	//расположение элементов 
	protected function updateLayout():void 
	{
		if(!contentClip)
			return;
		
		var scrollRect:Rectangle = contentClip.scrollRect;
		
		updateButtonsLayout();
		
		contentClip.x = leftButtons.x + leftButtons.width + hSpacing; 
		
		contentScrollRect = contentClip.scrollRect;
		contentScrollRect.width = _width - leftButtons.width - rightButtons.width - 2*hSpacing;
		contentClip.scrollRect = contentScrollRect;
		
		background.y = - scrollRect.y;
		background.x = contentClip.x;
		background.width = contentScrollRect.width;
	}
	
	protected function updateButtonsLayout():void
	{
		if(leftButtons && rightButtons)
		{
			leftButtons.x = 0;
			rightButtons.x = _width - rightButtons.width;
			
			leftButtons.y = - scrollRect.y;
			rightButtons.y = - scrollRect.y;
			
			leftArrowBtn.x 	= leftButtons.width/2 	- leftArrowBtn.width/2;
			leftArrow2Btn.x = leftButtons.width/2 	- leftArrow2Btn.width/2;
			leftArrow3Btn.x = leftButtons.width/2 	- leftArrow3Btn.width/2;
			
			rightArrowBtn.x  = rightButtons.width/2 - rightArrowBtn.width/2;
			rightArrow2Btn.x = rightButtons.width/2 - rightArrow2Btn.width/2;
			rightArrow3Btn.x = rightButtons.width/2 - rightArrow3Btn.width/2;
			
			leftArrowBtn.y 	= vPadding;
			leftArrow2Btn.y = height/2 - leftArrow2Btn.height/2;
			leftArrow3Btn.y = height - leftArrow3Btn.height - vPadding;
			
			rightArrowBtn.y  = vPadding;
			rightArrow2Btn.y = height/2 - rightArrow2Btn.height/2;
			rightArrow3Btn.y = height - rightArrow3Btn.height - vPadding;
		}
	}
	
	//перерисовка всех изменений 
	protected function update():void 
	{
		if (sizeChanged) {
			sizeChanged = false;
			
			contentScrollRect = contentClip.scrollRect;
			contentScrollRect.width = _width;
			contentScrollRect.height = _height;
			background.width = contentScrollRect.width;
			background.height = contentScrollRect.height;
			contentClip.scrollRect = contentScrollRect;
			
			background.width = _width;
			background.height = _height;
			
			_viewWidth = _width - rightButtons.width - leftButtons.width - 2*hSpacing;
			
			updateLayout();
		}
		
		if (horizontalScrollPositionChanged)
		{
			horizontalScrollPositionChanged = false;
			
			contentScrollRect = contentClip.scrollRect;
			
			if (_useScrollTween) {
				if(tweening)
					return;
				
				tweening = true;
				tweenScrollRect = contentScrollRect.clone();
				contentClip.cacheAsBitmap = true;
				var tween:GTween = new GTween(tweenScrollRect, animTime, {x:horizontalScrollPosition}, {ease:Cubic.easeOut});
				tween.onComplete = onTweenComplete;
				tween.onChange = onTweenUpdate;
			}
			else {
				contentScrollRect.x = horizontalScrollPosition;
				contentClip.scrollRect = contentScrollRect;
			}
		}
	}
	
	//обновление анимации перемотки
	protected function onTweenUpdate(tween:Object = null):void 
	{
		contentScrollRect.x = tweenScrollRect.x;
		contentClip.scrollRect = contentScrollRect;
	}
	
	protected var tweening:Boolean;
	//завершение анимации перемотки
	protected function onTweenComplete(tween:Object = null):void {
		contentClip.cacheAsBitmap = false;
		tweening = false;
	}
	
	protected function onBtnArrowUp(event:Event):void 
	{
		horizontalScrollPosition -= horizontalLineScrollSize;
	}
	
	protected function onBtnArrowDown(event:Event):void 
	{
		horizontalScrollPosition += horizontalLineScrollSize;
	}
	
	protected function onMouseWheel(event:MouseEvent):void 
	{
		var delta:Number = event.delta;
		horizontalScrollPosition -= (delta/Math.abs(delta))*horizontalLineScrollSize;
	}
	
	protected function onEnterFrame(event:Event = null):void 
	{
		var maxScrollPosition:Number = maxHorizontalScrollPosition;
		
		//если размеры контента меняются во времени, обновляем
		if (_content && contentWidth != _content.width) 
		{
			contentWidth = _content.width;
			//проверяем, что контент не вылез за пределы скролирования
			if (horizontalScrollPosition > maxScrollPosition)
				horizontalScrollPosition = maxScrollPosition;
		}
		
		updateButtons();
		
		if(autoCenterContent && contentWidth < width)
		{
			var centerX:int = int((width - contentWidth)/2);
			if (contentClip.x != centerX)
				contentClip.x = centerX;
		}
	}
	
	protected function updateButtons():void
	{
		var leftEnabled:Boolean = horizontalScrollPosition > 0;
		var rightEnabled:Boolean = maxHorizontalScrollPosition > horizontalScrollPosition;
		
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
	
	//ширина видимой части контента (ширина компонента минус ширина контролов)
	protected var _viewWidth:Number = 0;
	//ширина компонента
	protected var _width:Number = 0;
	override public function get width():Number {
		return _width;
	}
	override public function set width(value:Number):void {
		_width = value;
		sizeChanged = true;
		update();
	}
	
	//высота компонента
	protected var _height:Number = 0;
	override public function get height():Number {
		return _height;
	}
	override public function set height(value:Number):void {
		_height = value;
		sizeChanged = true;
		update();
	}
	
	protected var _vPadding:int;
	public function get vPadding():int 
	{
		return _vPadding;
	}
	
	/**
	 * 	//вертикальный пэддинг для крайних кнопок (как они прижимаются к центру)
	 * @param value
	 * 
	 */
	public function set vPadding(value:int):void 
	{
		_vPadding = value;
		updateLayout();
	}
	
	//использовать ли анимацию для прокрутки
	protected var _useScrollTween:Boolean = true;
	public function set useScrollTween(value:Boolean):void 
	{
		_useScrollTween = value;
	}	
	
	private function onBtnArrowRight(event:Event):void
	{
		var btn:SimpleButton = event.target as SimpleButton;
		
		if(btn == rightArrow2Btn)
			horizontalScrollPosition+=scrollPageNum*horizontalLineScrollSize;
		else if(btn == rightArrow3Btn)
			horizontalScrollPosition = maxHorizontalScrollPosition;
	}
	
	private function onBtnArrowLeft(event:Event):void
	{
		var btn:SimpleButton = event.target as SimpleButton;
		
		if(btn == leftArrow2Btn)
			horizontalScrollPosition-=scrollPageNum*horizontalLineScrollSize;
		else if(btn == leftArrow3Btn)
			horizontalScrollPosition = 0;
	}
	
	
}
}