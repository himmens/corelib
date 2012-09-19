package lib.core.ui.dnd
{
import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

import lib.core.util.log.Logger;

/**
 * Универсальный таскаемый Спрайт.
 */
[Event(name="startDrag", type="lib.core.ui.dnd.DragEvent")]
[Event(name="stopDrag", type="lib.core.ui.dnd.DragEvent")]
[Event(name="move", type="lib.core.ui.dnd.DragEvent")]

public class Draggable extends Sprite
{
	protected var dragged:Boolean = false;
	private var dragAnchor:Point;
	private var firstPosition:Point = new Point();

	// задавал ли юзер границы таскания
	private var boundsInitialized:Boolean = false;

	public var checkBounds:Boolean = true;

	public var updateAfterEvent:Boolean = true;

	/**
	 * порог в пикселях который надо преодолеть чтобы началось таскание
	 * 0 означает отсутвие порога, таскание начинается сразу по mouseDown
	 *
	 * Для простоты реализации события startDrag и stopDrag кидаются по прежнему по mouseDown и
	 * mouseUp, параметр startDragThreshold действует только на событие move
	 */
	public var startDragThreshold:int = 0;
	private var checkThreshold:Boolean;

	private var _moveable:Boolean = true;
	public function set moveable (b:Boolean):void
	{
		if (dragged && !b)
		{
			dispatchEvent(new DragEvent(DragEvent.STOP_DRAG));
			endDrag();
		}
		_moveable = b;
	}
	public function get moveable ():Boolean {return _moveable;}

	private var _dragTarget:InteractiveObject;
	public function get dragTarget():InteractiveObject {return _dragTarget}
	/**
	 * За что таскаем, если не задан используется вся поверхность объекта.
	 * @param value
	 *
	 */
	public function set dragTarget(value:InteractiveObject):void
	{
		if(_dragTarget != value)
		{
			if(_dragTarget)
			{
				_dragTarget.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
			}

			_dragTarget = value || this;

			enabled = _enabled;
		}
	}

	/**
	 * можно переопределить DisplayObject у которого берем размеры для проверки на границы, по
	 * умолчанию - у себя
	 */
	public var sizeTarget:DisplayObject;
	/**
	 * если sizeTarget имеет зум
	 */
//	public var zoomTarget:Number = 1;

	private var _enabled:Boolean = true;
	public function get enabled():Boolean {return _enabled}
	public function set enabled(b:Boolean):void
	{
		_enabled = b;
		if (stage==null)
			return;
		if (b)
		{
			dragTarget.addEventListener(MouseEvent.MOUSE_DOWN, onPress, false,0,true);
//			stage.addEventListener(MouseEvent.MOUSE_UP, onRelease);
//			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
			//onStageResize();

			if(dragTarget is Sprite)
				Sprite(dragTarget).buttonMode = Sprite(dragTarget).useHandCursor = true;
		}
		else
		{
			dragTarget.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
//			stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
//			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(Event.RESIZE, onStageResize);

			if(dragTarget is Sprite)
				Sprite(dragTarget).buttonMode = Sprite(dragTarget).useHandCursor = false;
		}
	}

	public function Draggable (dragBoundsRect:Rectangle = null)
	{
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false,0,true);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false,0,true);
		_bounds = dragBoundsRect;
		_dragTarget = this;
		sizeTarget = this;
	}

	private function onAddedToStage (e:Event):void
	{
		enabled = _enabled;

		if (bounds)
		{
			boundsInitialized = true;
		}

		firstPosition = new Point(x, y);
	}

	private function onRemovedFromStage (e:Event):void
	{
		stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.removeEventListener(Event.RESIZE, onStageResize);
	}

	protected function onPress (e:MouseEvent):void
	{
		dispatchEvent(new DragEvent(DragEvent.START_DRAG, new Point(x, y), e.ctrlKey, e.shiftKey));
		beginDrag(new Point(mouseX, mouseY));
		checkThreshold = startDragThreshold > 0;
	}

	protected function onRelease (e:MouseEvent):void
	{
		dispatchEvent(new DragEvent(DragEvent.STOP_DRAG, new Point(x, y), e.ctrlKey, e.shiftKey));
		endDrag();
	}

	protected function onMouseMove (e:MouseEvent):void
	{
		if (dragged)
		{
			if(startDragThreshold > 0 && checkThreshold)
			{
				var dist:Point = dragAnchor.subtract(new Point(mouseX, mouseY));
//				Logger.debug(this, "check start drag dist, dist = ", dist.length, ", threshold = ", startDragThreshold);
				if(dist.length < startDragThreshold)
					return;
				else
					checkThreshold = false;
			}

			place(parent.mouseX - dragAnchor.x, parent.mouseY - dragAnchor.y);
			dispatchEvent(new DragEvent(DragEvent.MOVE, new Point(x, y), e.ctrlKey, e.shiftKey));
			if(updateAfterEvent)
				e.updateAfterEvent();
		}
	}

	public function beginDrag (dragPoint:Point):void
	{
		/**
		* если границ не определили в конструкторе, то граничимся сценой
		*/
		if (bounds==null && checkBounds)
		{
			var p:Point = parent.globalToLocal(new Point(0, 0));
			bounds = new Rectangle(p.x, p.y, stage.stageWidth, stage.stageHeight);
		}

		if (_moveable)
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, onRelease, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);

			dragged = true;
			dragAnchor = dragPoint;
			bringToFont();

			place(parent.mouseX - dragAnchor.x, parent.mouseY - dragAnchor.y);
		}
//		dispatchEvent(new DragEvent(DragEvent.START_DRAG));
	}

	public function endDrag ():void
	{
		if(stage)
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onRelease);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		dragged = false;
//		dispatchEvent(new DragEvent(DragEvent.STOP_DRAG));
	}

	protected function bringToFont():void
	{
		parent.setChildIndex(this, parent.numChildren-1);
//		parent.addChild(this);
	}

	private function onStageResize (e:Event = null):void
	{
		if (! boundsInitialized)
		{
			var p:Point = parent.globalToLocal(new Point(0, 0));
			bounds = new Rectangle(p.x, p.y, stage.stageWidth, stage.stageHeight);
		}
	}

	public function place (_x:int, _y:int):void
	{
		var pt:Point = correctPointForBounds(_x, _y);

		super.x = pt.x;
		super.y = pt.y;
	}

	//используем эту точку для возвращения результата функции correctPointForBounds, чтобы не создавать много временных объектов
	protected var _correctPoint:Point = new Point();
	/**
	 * Проверяет границы таскания если они заданы и возвращает точку
	 * @param _x
	 * @param _y
	 * @return
	 */
	public function correctPointForBounds (_x:int, _y:int):Point
	{
		if(checkBounds && bounds)
		{
			if (_x > bounds.right - sizeTarget.width)
				_x = bounds.right - sizeTarget.width;
			else if (_x < bounds.left)
				_x = bounds.left;
			if (_y > bounds.bottom - sizeTarget.height)
				_y = bounds.bottom - sizeTarget.height;
			else if (_y < bounds.top)
				_y = bounds.top;
		}
		_correctPoint.x = _x;
		_correctPoint.y = _y;

		return _correctPoint;
	}

	public function setDragBounds(rect:Rectangle):void
	{
		_bounds = rect;
		boundsInitialized = true;
		place(x, y);
	}

	// граница таскания
	protected var _bounds:Rectangle;
	public function get bounds():Rectangle
	{
		return _bounds;
	}
	public function set bounds(rect:Rectangle):void
	{
		setDragBounds(rect);
	}

	/**
	 * Возвращаем объект на точку, с которой взяли в последний раз
	 * @param p
	 */
	public function restorePosition (p:Point = null):void
	{
		if (p!=null)
			firstPosition = p;
		place(firstPosition.x, firstPosition.y);
	}

	override public function set x (value:Number):void
	{
		super.x = value;
		firstPosition.x = value;
	}
	override public function set y (value:Number):void
	{
		super.y = value;
		firstPosition.y = value;
	}

}

}