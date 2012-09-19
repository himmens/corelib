package lib.core.ui.scroll
{
	import com.gskinner.motion.GTween;
	import com.gskinner.motion.easing.Cubic;
	import lib.core.util.FunctionUtil;
	import lib.core.util.Graph;
	import lib.core.util.log.Logger;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/**
	 * Базовый скроллпейн.
	 * Возможность анимационной прокрутки контента.
	 *
	 */
	
	/**
	 * начало анимации скрлирования
	 */
	[Event (name="tweenStart", type="flash.events.Event")]
	/**
	 * окончание анимации скролирования
	 */
	[Event (name="tweenEnd", type="flash.events.Event")]
	
	public class ScrollPane extends Sprite
	{
		public static const TWEEN_START:String = "tweenStart";
		public static const TWEEN_END:String = "tweenEnd";
		
		public static const DIRECTION_VERTICAL:String = "directionVertical";
		public static const DIRECTION_HORIZONTAL:String = "directionHorizontal";
		
		protected var background:Sprite;
		
		protected var scrollBar:ScrollBar;
		public var autoHideScrollBar:Boolean = true;
		public function get scrollBarSize():int{return isVertical ? scrollBar.width : scrollBar.height}
		public function get scrollBarVisible():Boolean{return scrollBar.visible}
		
		//клип для добавления контента
		protected var contentClip:Sprite;
		//прямоугольник маски отображения
		protected var contentScrollRect:Rectangle = new Rectangle();
		
		//размер контента
		protected var contentSize:Number = 0;
		//твин для анимации прокрутки
		protected var tween:GTween;
		
		//Автоматически выравнивать контент по центру, если меньше размеров
		public var autoCenterContent:Boolean = false;
		
		//Слушать Event.ENTER_FRAME для валидации размеров контента
		public var useEnterFrame:Boolean = true;
		
		/**
		 * Автоматически проверяем размеры контента на случай изменения
		 */
		public var autoCheckSize:Boolean = true;
		
		/**
		 * длительность анимации прокрутки в секундах
		 */
		private var _animTime:Number = 0.3;
		public function set animTime (value:Number):void
		{
			_animTime = value;
			if (tween)
				tween.duration = value;
		}
		
		public function get animTime ():Number
		{
			return _animTime;
		}
		
		/**
		 * Функция проигрывания анимации скролирования
		 */
		private var _animEase:Function = Cubic.easeOut;
		public function set animEase (value:Function):void
		{
			_animEase = value;
			if (tween)
				tween.ease = animEase;
		}
		
		public function get animEase ():Function
		{
			return _animEase;
		}
		
		public function ScrollPane(direction:String = DIRECTION_VERTICAL)
		{
			super();
			this.direction = direction;
			
			addEventListener(Event.ADDED_TO_STAGE, onStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onStage);
			
			tween = new GTween(this, animTime, null, {autoPlay:false, ease:animEase});
			tween.onComplete = onTweenComplete;
			tween.onChange = onTweenUpdate;
			
			init();
			FunctionUtil.callLater(update);
		}
		
		protected function init():void
		{
			addChild(background = new Sprite());
			Graph.drawFillRec(background.graphics, 0, 0, 1, 1, 0x000000, 0);
			
			//content
			addChild(contentClip = new Sprite());
			contentClip.scrollRect = contentScrollRect;
			
			if (useScrollBar) {
				scrollBar = createScrollBar();
				if (scrollBar) {
					scrollBar.addEventListener(ScrollBarToKill.SCROLL_POSITION_CHANGED, onScrollBarPositionChanged, false, 0, true);
					addChild(scrollBar);
					scrollBar.visible = false;
				}
			}
		}
		
		protected function createScrollBar():ScrollBar {
			return new ScrollBar();
		}
		
		protected function onStage(event:Event):void
		{
			if(event.type == Event.ADDED_TO_STAGE)
			{
				addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				if (useEnterFrame)
				{
					addEventListener(Event.ENTER_FRAME, onEnterFrame);
					onEnterFrame();
				}
			}else
			{
				removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				if (useEnterFrame)
					removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		//скролируемый элемент (добавляется в contentClip компонента)
		protected var _content:DisplayObject;
		public function get content():DisplayObject {
			return _content;
		}
		public function set content(value:DisplayObject):void {
			if(_content && contentClip && contentClip.contains(_content))
				contentClip.removeChild(_content);
			
			_content = value;
			
			if(_content && contentClip)
			{
				contentClip.addChild(_content);
				updateContent();
				
				_content.addEventListener(Event.RESIZE, onContentResize, false, 0, true);
			}
		}
		
		protected var directionChanged:Boolean;
		protected var _direction:String = DIRECTION_VERTICAL;
		public function get direction():String {
			return _direction;
		}
		public function set direction(value:String):void {
			if (_direction == value)
				return;
			_direction = value;
			directionChanged = true;
			FunctionUtil.callLater(update);
		}
		
		public function get isHorizontal():Boolean {
			return direction == DIRECTION_HORIZONTAL;
		}
		
		public function get isVertical():Boolean {
			return direction == DIRECTION_VERTICAL;
		}
		
		//конечная позиция анимации (в случае завершения)
		protected var tempEndScrollPosition:Number = 0;
		//текущая позиция анимации
		public var tempScrollPosition:Number = 0;
		protected var scrollPositionChanged:Boolean;
		protected var _scrollPosition:Number = 0;
		public function set scrollPosition(value:Number):void
		{
			if (!enabled)
			{
				Logger.debug(this, "Scrolling is disabled");
				return;
			}
			
			value = Math.min(Math.max(value, minScrollPosition), maxScrollPosition);
			if (scrollPosition == value)
				return;
			if (useScrollTween)
				startTweenScrollPosition(value);
			else
				applyScrollPosition(value);
		}
		public function get scrollPosition():Number {
			return _scrollPosition;
		}
		
		/**
		 * Запускаем анимацию прокрутки
		 */
		protected function startTweenScrollPosition(value:Number):void
		{
			tempEndScrollPosition = Math.round(value/scrollSize)*scrollSize;
			tween.paused = true;
			
			//Анимируем только если нужно проскролить на величину больше единичной прокрутки
			//if (Math.abs(scrollPosition - value) >= scrollSize)
			//{
			tempScrollPosition = scrollPosition;
			contentClip.cacheAsBitmap = true;
			tween.setValues({tempScrollPosition:value});
			tween.paused = false;
			
			if(hasEventListener(TWEEN_START))
				dispatchEvent(new Event(TWEEN_START));
			//}
			//else
			//	applyScrollPosition(value);
		}
		
		/**
		 * Применяем позицию прокрутки
		 */
		protected function applyScrollPosition(value:Number):void
		{
			tempEndScrollPosition = Math.round(value/scrollSize)*scrollSize;
			_scrollPosition = value;
			updateScrollRect();
			
			if (scrollBar && !scrollBar.isScrolling)
			{
				scrollBar.scrollPosition = value;
				dispatchEvent(new Event(ScrollBar.SCROLL_POSITION_CHANGED));
			}
		}
		
		public function get minScrollPosition():Number {
			return 0;
		}
		
		public function get maxScrollPosition():Number {
			return Math.max(0, contentSize - size);
		}
		
		//можно ли скролить список
		protected var _enabled:Boolean = true;
		[Bindable]
		public function get enabled ():Boolean
		{
			return _enabled;
		}
		public function set enabled (value:Boolean):void
		{
			if(_enabled != value)
			{
				_enabled = value;
				commitEnabled();
			}
		}
		
		protected function commitEnabled ():void
		{
		}
		
		//Разрешена ли прокрутка списка колесом мыши
		public var mouseWheelEnabled:Boolean = true;
		
		//величина разовой прокрутки контента
		protected var scrollSizeChanged:Boolean;
		protected var _scrollSize:Number = 1;
		public function get scrollSize():Number {
			return _scrollSize;
		}
		public function set scrollSize(value:Number):void {
			value = Math.max(value, 1);
			if (_scrollSize == value)
				return;
			_scrollSize = value;
			scrollSizeChanged = true;
			FunctionUtil.callLater(update);
		}
		
		//флаг на изменение размеров компонента
		protected var sizeChanged:Boolean;
		//ширина компонента
		protected var _width:Number = 100;
		override public function get width():Number {
			return _width;
		}
		override public function set width(value:Number):void {
			if (_width == value)
				return;
			_width = value;
			sizeChanged = true;
			FunctionUtil.callLater(update);
		}
		
		//высота компонента
		protected var _height:Number = 100;
		override public function get height():Number {
			return _height;
		}
		override public function set height(value:Number):void {
			if (_height == value)
				return;
			_height = value;
			sizeChanged = true;
			FunctionUtil.callLater(update);
		}
		
		public function get size():Number {
			return isHorizontal ? width : height;
		}
		
		//использовать ли анимацию для прокрутки
		protected var _useScrollTween:Boolean = true;
		public function get useScrollTween():Boolean {
			return _useScrollTween;
		}
		public function set useScrollTween(value:Boolean):void {
			_useScrollTween = value;
		}
		
		//использовать ли скроллбар для прокрутки
		protected var _useScrollBar:Boolean = true;
		public function get useScrollBar():Boolean {
			return _useScrollBar;
		}
		public function set useScrollBar(value:Boolean):void {
			_useScrollBar = value;
		}
		
		//расположение элементов
		protected function updateLayout():void
		{
			if (background) {
				background.width = width;
				background.height = height;
			}
			
			contentScrollRect.width = width;
			contentScrollRect.height = height;
			if (contentClip)
				contentClip.scrollRect = contentScrollRect;
			
			if (scrollBar) {
				scrollBar.rotation = isVertical ? 0 : -90;
				scrollBar.x = isVertical ? width - scrollBar.width : 0;
				scrollBar.y = isVertical ? 0 : height;
				scrollBar.height = isVertical ? height : width;
			}
		}
		
		//перерисовка всех изменений
		protected function update():void
		{
			if (sizeChanged) {
				sizeChanged = false;
				if (scrollBar)
					updateScrollBar();
				updateLayout();
			}
			
			if (scrollSizeChanged) {
				scrollSizeChanged = false;
				
				commitScrollSize();
			}
			
			if (directionChanged) {
				directionChanged = false;
				
				updateLayout();
				updateContent();
				updateScrollRect();
			}
		}
		
		protected function commitScrollSize():void
		{
			if (scrollBar)
				scrollBar.scrollSize = scrollSize;
		}
		
		protected function updateContent():void
		{
			if (content)
				contentSize = isHorizontal ? content.width : content.height;
			if (scrollBar)
				updateScrollBar();
		}
		
		protected function updateScrollBar():void
		{
			if (scrollBar) {
				var size:Number = this.size;
				scrollBar.maxScrollPosition = contentSize - size;
				scrollBar.visible = autoHideScrollBar ? contentSize > size : true;
				scrollBar.showThumb = contentSize > size;
			}
		}
		
		protected function updateScrollRect():void
		{
			if (isHorizontal)
				contentScrollRect.x = scrollPosition;
			else
				contentScrollRect.y = scrollPosition;
			if (contentClip)
				contentClip.scrollRect = contentScrollRect;
		}
		
		public function checkContentSize():void
		{
			if (!content)
				return;
			var newContentSize:Number = isHorizontal ? content.width : content.height;
			//если размеры контента меняются во времени, обновляем
			if (contentSize != newContentSize) {
				updateContent();
			}
		}
		
		protected function checkAutoCenterContent():void
		{
			if (!content)
				return;
			
			if (autoCenterContent)
			{
				if(contentSize < size)
				{
					contentClip.x = int((width - content.width)/2);
					contentClip.y = int((height - content.height)/2);
				}
				else
				{
					contentClip.x = 0;
					contentClip.y = 0;
				}
			}
		}
		
		public function reset():void
		{
			applyScrollPosition(0);
			tempScrollPosition = 0;
			tempEndScrollPosition = 0;
		}
		
		//-------------------------------Event Handlers-------------------------------------
		
		protected function onScrollBarPositionChanged(event:Event):void
		{
			tempScrollPosition = scrollBar.scrollPosition;
			tempEndScrollPosition = Math.round(tempScrollPosition/scrollSize)*scrollSize;
			if (scrollBar.isScrolling) {
				tween.paused = true;
				applyScrollPosition(tempScrollPosition);
			}
			else {
				scrollPosition = tempScrollPosition;
			}
		}
		
		//обновление анимации перемотки
		protected function onTweenUpdate(tween:Object = null):void
		{
			applyScrollPosition(tempScrollPosition);
		}
		
		//завершение анимации перемотки
		protected function onTweenComplete(tween:Object = null):void {
			contentClip.cacheAsBitmap = false;
			
			if(hasEventListener(TWEEN_END))
				dispatchEvent(new Event(TWEEN_END));
		}
		
		protected function onMouseWheel(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			
			if (!mouseWheelEnabled)
				return;
			
			var delta:Number = event.delta;
			stepScrollPosition(-scrollSize*delta/Math.abs(delta));
			
			//event.updateAfterEvent();
		}
		
		protected function stepScrollPosition(value:int):void
		{
			var startScrollposition:int = useScrollTween ? tempEndScrollPosition : scrollPosition;
			scrollPosition = startScrollposition + value;
		}
		
		private function validateContentSize():void
		{
			if (autoCheckSize)
				checkContentSize();
			
			var curMaxScrollPosition:Number = maxScrollPosition;
			//проверяем, что контент не вылез за пределы скролирования
			if (scrollPosition > curMaxScrollPosition)
				applyScrollPosition(curMaxScrollPosition);
			
			if (autoCenterContent)
				checkAutoCenterContent();
		}
		
		protected function onEnterFrame(event:Event = null):void
		{
			validateContentSize();
		}
		
		private function onContentResize(event:Event = null):void
		{
			validateContentSize();
		}
	}
}