package lib.core.ui.scroll
{
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

/**
 * Базовый ScrollPane (вертикальный скролл бар).
 */
public class ScrollPaneToKill extends Sprite
{
	//флаг на инициализацию всех элементов
	protected var inited:Boolean;
	
	protected var background:Sprite;
	
	protected var verticalScrollBar:ScrollBarToKill;
	
	//клип для добавления контента
	protected var contentClip:Sprite;
	//прямоугольник маски отображения
	protected var contentScrollRect:Rectangle = new Rectangle();
	
	/**
	 * Автоматически выравнивать контент по центру, если меньше размеров
	 */
	public var autoCenterContent:Boolean = false; 
	
	//высота контента
	protected var contentHeight:Number=0;
	
	public function ScrollPaneToKill()
	{
		super();
		
		init();
		inited = true;
		update();
	}
	
	protected function init():void
	{
		background = new Sprite();
		with (background.graphics) {
			lineStyle(0, 0, 0);
			beginFill(0, 0);
			drawRect(0, 0, 1, 1);
		}
		addChild(background);
		
		//content
		contentClip = new Sprite();
		addChild(contentClip);
		contentClip.scrollRect = contentScrollRect;
		if (_content) {
			contentClip.addChild(_content);
			contentChanged = true;
		}
		
		//scrollBar
		verticalScrollBar = createVerticalScrollBar();
		if (verticalScrollBar) {
			verticalScrollBar.addEventListener(ScrollBarToKill.SCROLL_POSITION_CHANGED, onScrollPositionChanged);
			addChild(verticalScrollBar);
		}
		
		addEventListener(Event.ADDED_TO_STAGE, onStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onStage);
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

	protected function createVerticalScrollBar():ScrollBarToKill {
		var scrollBar:ScrollBarToKill = new ScrollBarToKill();
		return scrollBar;
	}
	
	//скролируемый элемент (добавляется в contentClip компонетнта)
	protected var _content:DisplayObject;
	protected var contentChanged:Boolean;
	public function set content(value:DisplayObject):void 
	{
		if(_content && contentClip && contentClip.contains(_content))
			contentClip.removeChild(_content);
		
		_content = value;
		
		if(_content && contentClip)
		{
			contentClip.addChild(_content);
			contentChanged = true;
			update();
		}
	}
	public function get content():DisplayObject {	
		return _content;
	}
	
	//флаг на изменение вертикальной прокрутки
	protected var verticalScrollPositionChanged:Boolean;
	protected var _verticalScrollPosition:Number = 0;
	public function set verticalScrollPosition(value:Number):void 
	{	
		value = Math.min(Math.max(value, minVerticalScrollPosition), maxVerticalScrollPosition);
		if (_verticalScrollPosition != value) {
			_verticalScrollPosition = value;
			verticalScrollPositionChanged = true;
			update();
		}
	}
	public function get verticalScrollPosition():Number {	
		return _verticalScrollPosition;
	}
	
	public function get minVerticalScrollPosition():Number {
		return 0;
	}
	
	public function get maxVerticalScrollPosition():Number {
		return Math.max(0, contentHeight-_height);
	}
	
	//величина разовой прокрутки контента	
	protected var verticalLineScrollSizeChanged:Boolean;
	protected var _verticalLineScrollSize:Number = 1;
	public function get verticalLineScrollSize():Number {
		return _verticalLineScrollSize;
	}		
	public function set verticalLineScrollSize(value:Number):void 
	{
		value = Math.max(value, 1);
		if (_verticalLineScrollSize != value) {
			_verticalLineScrollSize = value;
			verticalLineScrollSizeChanged = true;
			update();
		}
	}
	
	//флаг на изменение размеров компонента
	protected var sizeChanged:Boolean;
	
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
	
	//расположение элементов 
	protected function updateLayout():void 
	{
		if (!inited)
			return;
		
		if (verticalScrollBar)
			verticalScrollBar.x = width - verticalScrollBar.width;
	}
	
	//перерисовка всех изменений 
	protected function update():void 
	{
		if (!inited)
			return;
			
		if (sizeChanged) {
			sizeChanged = false;
			
			background.width = width;
			background.height = height;
			
			if (verticalScrollBar)
				verticalScrollBar.height = height;
			
			contentScrollRect = contentClip.scrollRect;
			contentScrollRect.width = width;
			contentScrollRect.height = height;
			contentClip.scrollRect = contentScrollRect;
			
			updateLayout();
			updateContent();
		}
		
		if (contentChanged) {
			contentChanged = false;
			
			updateContent();
		}
		
		if (verticalLineScrollSizeChanged) {
			verticalLineScrollSizeChanged = false;
			
			if (verticalScrollBar)
				verticalScrollBar.lineScrollSize = verticalLineScrollSize;
		}
		
		if (verticalScrollPositionChanged) {
			verticalScrollPositionChanged = false;
			
			content.cacheAsBitmap = true;
			updateScrollRect();
			content.cacheAsBitmap = false;
			if (verticalScrollBar)
				verticalScrollBar.scrollPosition = verticalScrollPosition;
		}
	}
	
	protected function updateScrollRect():void 
	{
		contentScrollRect = contentClip.scrollRect;
		contentScrollRect.y = verticalScrollPosition;
		contentClip.scrollRect = contentScrollRect;
	}
	
	protected function updateContent():void 
	{
		if(content)
			contentHeight = content.height;
		
		if (verticalScrollBar) {	
			verticalScrollBar.maxScrollPosition = contentHeight - height;
			verticalScrollBar.visible = contentHeight > height;
		}
	}
	
	protected function onMouseWheel(event:MouseEvent):void 
	{
		var delta:Number = event.delta;
		if (verticalScrollBar) {
			var position:Number = verticalScrollBar.scrollPosition - (delta/Math.abs(delta))*verticalLineScrollSize;
			verticalScrollBar.setScrollPosition(position);
		}
	}
	
	protected function onEnterFrame(event:Event = null):void 
	{
		//если размеры контента меняются во времени, обновляем
		if (_content && contentHeight != _content.height) {
			updateContent();
		}
		
		if(autoCenterContent && contentHeight < height)
		{
			var centerY:int = int((height - contentHeight)/2);
			if (contentClip.y != centerY)
				contentClip.y = centerY;
		}
	}
	
	protected function onScrollPositionChanged(event:Event):void 
	{
		if (verticalScrollBar)
			verticalScrollPosition = verticalScrollBar.scrollPosition;
	}
}
}