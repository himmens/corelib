package lib.core.ui.scroll
{
import com.gskinner.motion.GTween;
import com.gskinner.motion.easing.Cubic;

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

import lib.core.ui.controls.ToggleButton;
import lib.core.ui.dnd.DragEvent;
import lib.core.ui.dnd.Draggable;

/**
 * Базовый скроллбар.
 * 
* Возможность анимированной прокрутки.
*/
[Event (name="scrollPositionChanged", type="com.kamagames.core.ui.controls.scroll.ScrollBar")] 
public class ScrollBarToKill extends Sprite
{
	public static var SCROLL_POSITION_CHANGED:String = "scrollPositionChanged";
	
	protected var inited:Boolean;
	
	protected var btnArrowUp:SimpleButton;
	protected var btnArrowDown:SimpleButton;
	
	protected var track:DisplayObject;
	protected var thumb:Draggable;
	protected var thumbButton:InteractiveObject;
	
	//точка начала перетаскивания слайдера
	protected var startDragPosition:Number;
	
	//минимальная высота слайдера
	protected var minThumbHeight:Number = 5;
	
	/**
	 * длительность анимации прокрутки в секундах
	 */
	public var animTime:Number = .3;
	
	//флаг - идет анимация
	protected var tweening:Boolean;
	
	//флаг - скролим слайдером
	public var isScrolling:Boolean;
	
	public function ScrollBarToKill()
	{
		super();
		init();
		inited = true;
		update();
	}
	
	protected function init():void
	{
		//track
		track = createTrack();
		if (track)
			addChild(track);
		
		//buttons
		btnArrowUp = createButtonUp();
		if (btnArrowUp) {
			btnArrowUp.useHandCursor = true;
			btnArrowUp.addEventListener(MouseEvent.CLICK, onBtnUp);
			addChild(btnArrowUp);
		}
		
		btnArrowDown = createButtonDown();
		if (btnArrowDown) {
			btnArrowDown.useHandCursor = true;
			btnArrowDown.addEventListener(MouseEvent.CLICK, onBtnDown);
			addChild(btnArrowDown);
		}
		
		//thumb
		thumb = createThumb();
		if (thumb) {
			thumb.addEventListener(DragEvent.START_DRAG, onThumbDragStart);
			thumb.addEventListener(DragEvent.STOP_DRAG, onThumbDragStop);
			thumb.addEventListener(DragEvent.MOVE, onThumbDragMove);
			addChild(thumb);
		}
	}
	
	protected function createTrack():DisplayObject {
		var track:Shape = new Shape();
		with (track.graphics) {
			lineStyle(0, 0, 0);
			beginFill(0, 0);
			drawRect(0, 0, 10, 10);
			endFill();
		}
		return track;
	}
	
	protected function createButtonUp():SimpleButton {
		var button:SimpleButton = new SimpleButton();
		var upState:Shape = new Shape();
		with (upState.graphics) {
			lineStyle(0, 0x0000ff, 1);
			beginFill(0xffff00, 1);
			moveTo(5, 0);
			lineTo(0, 10);
			lineTo(10, 10);
			lineTo(5, 0);
			endFill();
		}
		button.upState = upState;
		button.overState = upState;
		button.downState = upState;
		button.hitTestState = upState;
		return button;
	}
	
	protected function createButtonDown():SimpleButton {
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
	
	protected function createThumb():Draggable {
		var thumb:Draggable = new Draggable();
		thumbButton = createThumbButton();
		thumb.addChild(thumbButton);
		return thumb;
	}
	
	protected function createThumbButton():InteractiveObject {
		var button:Sprite = new Sprite();
		with (button.graphics) {
			lineStyle(0, 0, 1);
			beginFill(0x00ff00, 1);
			drawRect(0, 0, 10, 10);
			endFill();
		}
		return button;
	}
	
	protected var sizeChanged:Boolean;
	
	protected var _width:Number;
	override public function get width():Number {
		return _width ? _width : super.width;
	}
	override public function set width(value:Number):void {
		_width = value;
		sizeChanged = true;
		update();
	}
	
	protected var _height:Number;
	override public function get height():Number {
		return _height ? _height : super.height;
	}
	override public function set height(value:Number):void {
		_height = value;
		sizeChanged = true;
		update();
	}
	
	/**
	 *  Величина разовой прокрутки
	 */
	private var _lineScrollSize:Number = 1;
	public function get lineScrollSize():Number
	{
		return _lineScrollSize;
	}
	public function set lineScrollSize(value:Number):void
	{
		_lineScrollSize = value;
	}
	
	/**
	 *  Минимальный скролл
	 */
	private var _minScrollPosition:Number = 0;
	public function get minScrollPosition():Number
	{
		return _minScrollPosition;
	}
	public function set minScrollPosition(value:Number):void
	{
		_minScrollPosition = value;
	}
	
	/**
	 *  Максимальный скролл
	 */
	private var _maxScrollPosition:Number = 0;
	private var maxScrollPositionChanged:Boolean;
	public function get maxScrollPosition():Number
	{
		return _maxScrollPosition;
	}
	public function set maxScrollPosition(value:Number):void
	{
		if (_maxScrollPosition != value) {
			_maxScrollPosition = value;
			maxScrollPositionChanged = true;
			update();
		}
	}
	
	/**
	 *  Позиция скролла
	 */
	private var _scrollPosition:Number = 0;
	private var scrollPositionChanged:Boolean;
	public function get scrollPosition():Number
	{
		return _scrollPosition;
	}
	public function set scrollPosition(value:Number):void
	{
		value = Math.max(Math.min(value, maxScrollPosition), minScrollPosition);
		if (_scrollPosition != value) {
			
			_scrollPosition = value;
			scrollPositionChanged = true;
			dispatchEvent(new Event(SCROLL_POSITION_CHANGED));
			update();
		}
	}
	
	/**
	 *  Назначаем скролл с возможной анимацией
	 */
	public  function setScrollPosition(value:Number):void {
		value = Math.max(Math.min(value, maxScrollPosition), minScrollPosition);
		if(scrollPosition == value || tweening || isScrolling)
			return;
		
		if (useScrollTween) {
			var tween:GTween = new GTween(this, animTime, {scrollPosition:value}, {ease:Cubic.easeOut});
			tween.onComplete = onTweenComplete;
			tweening = true;
		}
		else {
			scrollPosition = value;
		}
	}
	
	/**
	 *  Флаг для использования анимации прокрутки
	 */
	protected var _useScrollTween:Boolean = true;
	public function set useScrollTween(value:Boolean):void 
	{
		_useScrollTween = value;
	}
	public function get useScrollTween():Boolean 
	{
		return _useScrollTween;
	}
	
	/**
	 *  Обновляем все изменения 
	 */
	protected function update():void
	{
		if (!inited)
			return;
		
		if (sizeChanged) {
			sizeChanged = false;
			
			btnArrowDown.y = height - btnArrowDown.height;
			track.y = btnArrowUp.height;
			track.x = width/2 - track.width/2;
			track.height = height - btnArrowUp.height - btnArrowDown.height;
			
			thumb.x = width/2 - thumb.width/2;
			thumb.y = track.y;
			
			updateThumb();
		}
		
		if (maxScrollPositionChanged) {
			maxScrollPositionChanged = false;
			
			if (scrollPosition > maxScrollPosition)
				scrollPosition = maxScrollPosition;
			
			updateThumb();
		}
		
		if (scrollPositionChanged) {
			scrollPositionChanged = false;
			
			updateThumbPosition();
		}
	}
	
	/**
	 *  Обновляем параметры слайдера
	 */
	protected function updateThumb():void
	{
		if (!thumb || !track)
			return;
		
		if (thumb.visible) {
			var size:Number = track.height / (1 + (maxScrollPosition - minScrollPosition) / 100);
			thumbButton.height = Math.max(minThumbHeight, size);
			
			var x:Number = (width - thumb.width)/2;
			var y:Number = track.y;
			var width:Number = thumb.width;
			var height:Number = track.height;
			thumb.setDragBounds(new Rectangle(x, y, width, height));
			
			updateThumbPosition();
		}
	}
	
	/**
	 *  Обновляем позицию слайдера
	 */
	protected function updateThumbPosition():void
	{
		if (!thumb || !track)
			return;
		
		if (!isScrolling && thumb.visible) {
			var denom:Number = maxScrollPosition - minScrollPosition;
			var relY:Number = denom == 0 ? 0 : ((scrollPosition - minScrollPosition) * (track.height - thumb.height) / denom);
			thumb.y = track.y + relY;
		}
	}
	
	protected function onBtnUp(event:Event):void 
	{
		setScrollPosition(scrollPosition - lineScrollSize);
	}
	
	protected function onBtnDown(event:Event):void 
	{
		setScrollPosition(scrollPosition + lineScrollSize);
	}
	
	private function onThumbDragStart(event:Event):void 
	{
		isScrolling = true;
		startDragPosition = mouseY - track.y - thumb.y;
	}
	
	private function onThumbDragStop(event:Event):void 
	{
		isScrolling = false;
		//после отпускания слайдера доскроливаем до ближайшего целого
		setScrollPosition(Math.round(scrollPosition/lineScrollSize)*lineScrollSize);
	}
	
	private function onThumbDragMove(event:Event):void 
	{
		var localPoint:Point = new Point(mouseX, mouseY);
		var position:Number = ((localPoint.y - 2*track.y - startDragPosition) * 
			(maxScrollPosition - minScrollPosition) / (track.height - thumb.height)) + minScrollPosition;
		scrollPosition = position;
	}
	
	/**
	 *  Завершение анимации перемотки
	 */
	protected function onTweenComplete(tween:GTween):void {
		tweening = false;
	}
}
}