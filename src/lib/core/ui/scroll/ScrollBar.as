package lib.core.ui.scroll
{
import lib.core.ui.dnd.DragEvent;
import lib.core.ui.dnd.Draggable;

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * Базовый скроллбар.
*/
[Event (name="scrollPositionChanged", type="lib.core.ui.scroll.ScrollBar")]
public class ScrollBar extends Sprite
{
	public static var SCROLL_POSITION_CHANGED:String = "scrollPositionChanged";

	protected var btnArrowUp:InteractiveObject;
	protected var btnArrowDown:InteractiveObject;

	protected var track:DisplayObject;

	protected var thumb:Draggable;
	protected var thumbButton:InteractiveObject;
	protected var thumbIcon:DisplayObject;//иконка слайдера, не растягивается, располагается по центу (например, полосочки)

	//точка начала перетаскивания слайдера
	protected var startDragPosition:Number;

	// Нужно ли растягивать слайдер
	protected var isResizeThumbButton:Boolean = true;
	//минимальная высота слайдера
	protected var minThumbHeight:Number = 5;

	//флаг - скролим слайдером
	public var isScrolling:Boolean;
	//автоматически доскроливать до ближайшего целого при отпускании
	public var autoScrollAfterDrop:Boolean;

	// Дополнительное расстояние по высоте для линии, по которой ходит слайдер скроллинга
	protected var trackVSpacing:Number = 0;

	public function ScrollBar()
	{
		super();
		init();
		update();
	}

	protected function init():void
	{
		//track
		if (!track)
		{
			track = createTrack();
			if (track)
			{
				addChild(track);
				track.addEventListener(MouseEvent.MOUSE_DOWN, onTrackDown);
			}
		}
		//buttons
		if (!btnArrowUp)
		{
			btnArrowUp = createButtonUp();
			if (btnArrowUp) {
				if(btnArrowUp.hasOwnProperty("useHandCursor"))
				{
					btnArrowUp["useHandCursor"] = true;
				}
				if(btnArrowUp.hasOwnProperty("buttonMode"))
				{
					btnArrowUp["buttonMode"] = true;
				}
				btnArrowUp.addEventListener(MouseEvent.CLICK, onBtnUp);
				addChild(btnArrowUp);
			}
		}
		if (!btnArrowDown)
		{
			btnArrowDown = createButtonDown();
			if (btnArrowDown) {
				//btnArrowDown.useHandCursor = true;
				if(btnArrowDown.hasOwnProperty("useHandCursor"))
				{
					btnArrowDown["useHandCursor"] = true;
				}
				if(btnArrowDown.hasOwnProperty("buttonMode"))
				{
					btnArrowDown["buttonMode"] = true;
				}
				btnArrowDown.addEventListener(MouseEvent.CLICK, onBtnDown);
				addChild(btnArrowDown);
			}
		}
		//thumb
		if (!thumb)
		{
			thumb = createThumb();
			if (thumb) {
				thumb.addEventListener(DragEvent.START_DRAG, onThumbDragStart);
				thumb.addEventListener(DragEvent.STOP_DRAG, onThumbDragStop);
				thumb.addEventListener(DragEvent.MOVE, onThumbDragMove);
				addChild(thumb);
			}
		}
	}

	protected function createTrack():DisplayObject {
		var track:Sprite = new Sprite();
		with (track.graphics) {
			lineStyle(0, 0, 0);
			beginFill(0xffffff, 0.2);
			drawRect(0, 0, 10, 10);
			endFill();
		}
		return track;
	}

	protected function createButtonUp():InteractiveObject {
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

	protected function createButtonDown():InteractiveObject {
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
		thumbIcon = createThumbIcon();
		if(thumbIcon)
			thumb.addChild(thumbIcon);
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

	protected function createThumbIcon():DisplayObject
	{
		return null;
//		var sprite:Sprite = new Sprite();
//		sprite.graphics.lineStyle(2);
//		sprite.graphics.moveTo(0, 0);
//		sprite.graphics.lineTo(5, 0);
//		sprite.graphics.moveTo(0, 3);
//		sprite.graphics.lineTo(5, 3);
//		sprite.graphics.moveTo(0, 6);
//		sprite.graphics.lineTo(5, 6);
//		return sprite;
	}

	protected var sizeChanged:Boolean;

	protected var _width:Number;
	override public function get width():Number {
		return _width ? _width : (btnArrowUp && thumb) ? Math.max(btnArrowUp.width, thumb.width) : super.width;
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
	private var _scrollSize:Number = 1;
	public function get scrollSize():Number
	{
		return _scrollSize;
	}
	public function set scrollSize(value:Number):void
	{
		_scrollSize = value;
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

	private var _showThumb:Boolean = true;
	public function get showThumb():Boolean
	{
		return _showThumb;
	}
	
	public function set showThumb(value:Boolean):void
	{
		if(showThumb != value)
		{
			_showThumb = value;
			if(thumb)
			{
				thumb.visible = value;
				updateThumb();
				
				//updateThumbPosition();
			}
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
		if(scrollPosition == value || isScrolling)
			return;

		scrollPosition = value;
	}

	/**
	 *  Обновляем все изменения
	 */
	protected function update():void
	{
		if (sizeChanged) {
			sizeChanged = false;

			btnArrowDown.y = height - btnArrowDown.height;
			track.y = btnArrowUp.height - trackVSpacing;
			track.x = width/2 - track.width/2;
			track.height = height - btnArrowUp.height - btnArrowDown.height + trackVSpacing * 2;

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
			var height:Number = track.height - trackVSpacing * 2;
			
			if(isResizeThumbButton)
			{
				//var size:Number = track.height / (1 + (maxScrollPosition - minScrollPosition) / 100);
				var size:Number = height / (1 + (maxScrollPosition - minScrollPosition) / 100);
				//if(size > 600)
				//	trace(this, "too big!!!");
				thumbButton.height = Math.min(Math.max(minThumbHeight, size), height);
			}else
			{
				thumbButton.scaleX = 1;
				thumbButton.scaleY = 1;
			}
			if (thumbIcon)
			{
				thumbIcon.x = (thumbButton.width - thumbIcon.width) >> 1;
				thumbIcon.y = (thumbButton.height - thumbIcon.height) >> 1;
			}

			var x:Number = (this.width - thumb.width)/2;
			var y:Number = track.y + trackVSpacing;
			var width:Number = thumb.width;
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
			//var relY:Number = denom == 0 ? 0 : ((scrollPosition - minScrollPosition) * (track.height - thumb.height) / denom);
			var relY:Number = denom == 0 ? 0 : ((scrollPosition - minScrollPosition) * (track.height - trackVSpacing * 2 - thumb.height) / denom);
			//thumb.y = track.y + relY;
			thumb.y = track.y + trackVSpacing + relY;
		}
	}

	protected function onBtnUp(event:Event):void
	{
		setScrollPosition(Math.round(scrollPosition/scrollSize-1)*scrollSize);
	}

	protected function onBtnDown(event:Event):void
	{
		setScrollPosition(Math.round(scrollPosition/scrollSize+1)*scrollSize);
	}

	private function onThumbDragStart(event:Event):void
	{
		isScrolling = true;
		startDragPosition = mouseY - track.y + trackVSpacing - thumb.y;
	}

	private function onThumbDragStop(event:Event):void
	{
		isScrolling = false;
		if (autoScrollAfterDrop) {
			//после отпускания слайдера доскроливаем до ближайшего целого
			scrollPosition = Math.round(scrollPosition/scrollSize)*scrollSize;
		}
	}

	private function onThumbDragMove(event:Event):void
	{
		var localPoint:Point = new Point(mouseX, mouseY);
		//var position:Number = ((localPoint.y - 2*track.y - startDragPosition) * (maxScrollPosition - minScrollPosition) / (track.height - thumb.height)) + minScrollPosition;
		var position:Number = ((localPoint.y - 2 * (track.y + trackVSpacing) - startDragPosition) * (maxScrollPosition - minScrollPosition) / (track.height - trackVSpacing * 2 - thumb.height)) + minScrollPosition;

		scrollPosition = position;
	}

	protected function onTrackDown(event:Event):void
	{
		var localPoint:Point = new Point(mouseX, mouseY);
		//var position:Number = (maxScrollPosition - minScrollPosition)*(localPoint.y - track.y) / (track.height - trackVSpacing * 2);
		var position:Number = (maxScrollPosition - minScrollPosition)*(localPoint.y - track.y + trackVSpacing) / (track.height - trackVSpacing * 2);
		scrollPosition = Math.round(position/scrollSize)*scrollSize;
	}
}
}