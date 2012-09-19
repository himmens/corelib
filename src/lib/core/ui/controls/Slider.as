package lib.core.ui.controls 
{
	import lib.core.ui.dnd.DragEvent;
	import lib.core.ui.dnd.Draggable;
	import lib.core.ui.layout.RowLayout;
	import lib.core.util.log.Logger;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	
	/**
	 * Слайдер с таскаемым элементом для изменения величины в интервале от 0 до 1
	 */
	[Event (name="change", type="flash.events.Event")] 
	public class Slider extends Sprite
	{
		protected var track:Sprite;
		protected var thumbDrag:Draggable;
		
		protected var _position:Number;
		protected var _target:Object;
		
		protected var trackWidth:int = 190;
		protected var _trackWidthChange:Boolean = true;
		
		protected var thumb:DisplayObject;
		
		public function Slider() 
		{
			super();
			init();
		}
		
		public function get target():Object {
			return _target;
		}
		
		public function set target(value:Object):void {
			_target = value;
		}
		
		public function set position(value:Number):void {
			value = Math.max(0, Math.min(value, 1));
			if (_position != value) {
				_position = step ? Math.round(value/step)*step : value;
				updatePosition();
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		public function get position():Number {
			return _position;
		}
		
		/**
		 * шаг для смещения бегунка (0 - без шага, плавно) в процентах (от 0 до 1)
		 */
		public var step:Number = 0;
		
		protected function updatePosition():void {
			var dragX:Number = trackWidth * _position;
			thumbDrag.x = dragX;
		}	
		
		protected function init():void 
		{
			track = createTrack();
			if (track) {
				addChild(track);
				trackWidth = track.width;
				track.addEventListener(MouseEvent.CLICK, onTrackClick);
			}
			
			thumb = createThumb();
			if (thumb) {
				thumbDrag = new Draggable();
				thumbDrag.addChild(thumb);
				addChild(thumbDrag);
				thumbDrag.y = (track.height-thumb.height)/2;
				thumbDrag.addEventListener(DragEvent.MOVE, onDragMove);
			}
			commitWidth();
		}
		
		protected function createTrack():Sprite 
		{
			var sprite:Sprite = new Sprite();
			with (sprite.graphics) {
				lineStyle(0, 0, 1);
				beginFill(0xffffff, 1);
				drawRect(0, 0, 100, 10);
				endFill();
			}
			return sprite;
		}
		
		protected function createThumb():DisplayObject 
		{
			var shape:Shape = new Shape();
			with (shape.graphics) {
				lineStyle(0, 0, 1);
				beginFill(0xff0000, 1);
				drawRect(0, 0, 15, 15);
				endFill();
			}
			return shape;
		}
		
		override public function set width(value:Number):void 
		{
			trackWidth = value;
			_trackWidthChange = true;
			commitWidth();
		}
		
		override public function get width():Number
		{
			return trackWidth;
		}
		
		protected function commitWidth():void
		{
			if (track && _trackWidthChange)
			{
				track.width = trackWidth;
			}
			if (thumb && thumbDrag)
			{
				thumbDrag.setDragBounds(new Rectangle(0, thumbDrag.y, trackWidth + thumbDrag.width, thumb.height));
			}
			
			_trackWidthChange = false;
			updatePosition();
			
		}
		
		protected function onTrackClick(event:MouseEvent):void 
		{
			var pos:Number = event.localX / (trackWidth);
			position = pos;
		}
		
		protected function onDragMove(event:DragEvent):void 
		{
			var pos:Number = thumbDrag.x / (trackWidth);
			if(drapPosChecker != null)
				pos = drapPosChecker(pos);
			position = pos;
			updatePosition();
		}
		
		//проверка позиции при таскании бегунка (для реализации механизма прилипания)
		internal var drapPosChecker:Function;
	}
}
