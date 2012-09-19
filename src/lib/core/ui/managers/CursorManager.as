package lib.core.ui.managers
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Mouse;
import flash.text.TextField;
import flash.utils.Dictionary;
import flash.display.InteractiveObject;

	/**
	 * Cursor manager. Contains functionality for controlling cursors.
	 */
	public class CursorManager
	{
		/**
		 * Indicates no cursor.
		 */
		public static const NO_CURSOR:int = -1;

		private static var parent:DisplayObjectContainer;
		private static var stage:Stage;
		private static var cursors:Array;

		//current entry.
		private static var current:CursorEntry;
		private static var inited:Boolean = false;

		/**
		 * Inits the cursor manager. Must be invoked to initialize manager propertly.
		 *
		 * @param parentObject Specifies a parent object for cursors.
		 * Usually  stage is used.
		 */
		public static function init(stageObject:Stage, parentObject:DisplayObjectContainer = null):void {
			if(!inited)
			{
				stage = stageObject;
				parent = parentObject ? parentObject : stage;
				stage.addEventListener(Event.MOUSE_LEAVE, stageHandler, false, 0, true);
				stage.addEventListener(MouseEvent.MOUSE_OVER, stageHandler, false, 0, true);
				stage.addEventListener(Event.ACTIVATE, stageHandler, false, 0, true);
				stage.addEventListener(Event.DEACTIVATE, stageHandler, false, 0, true);
				cursors = new Array();
				inited = true;
			}
		}

		private static function stageHandler(event:Event):void
		{
			if(current)
			{
				if(event.type == Event.MOUSE_LEAVE || event.type == Event.DEACTIVATE)
					current.cursor.visible = false;
				else if(event.type == MouseEvent.MOUSE_OVER || event.type == Event.ACTIVATE)
					current.cursor.visible = true;
			}
		}

		/**
		 * Sets the cursor.
		 *
 		 * @param cursor Specifies a cursor class. Should be subclass of
 		 * 					flash.display.DisplayObject
		 * @param priority Specifies a cursor priority.
		 * @param xOffset Specifies an x offset.
		 * @param yOffset Specifies an y offset.
		 * @return cursor ID.
		 */
		public static function setCursor(cursor:Class, hideMouse:Boolean = true, xOffset:int = 0, yOffset:int = 0, priority:int = 2):int {
			if(!cursor)
				return NO_CURSOR;

			if(!parent)
			{
				trace('CursorManager not inited...');
				return NO_CURSOR;
			}
			var entry:CursorEntry = new CursorEntry(cursor, priority, xOffset, yOffset, hideMouse);
			setCursorEntry(entry);
			return entry.id;
		}

		private static function setCursorEntry(entry:CursorEntry):void
		{
			if (cursors.indexOf(entry) == -1)
				cursors.push(entry);
			cursors.sort(CursorEntry.compare, Array.DESCENDING);
			showCursor();
		}

		//shows cursor.
		private static function showCursor():void {
			if (current) {
				parent.removeChild(current.cursor);
				parent.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			}
			if (cursors.length == 0) {
				Mouse.show();
				current = null;
			} else {
				current = CursorEntry(cursors[0]);
				if(current.hideMouse)
					Mouse.hide();
				else
					Mouse.show();
				setupCursor();
			}
		}

		//setups cursor.
		private static function setupCursor():void {
			parent.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
			parent.addChild(current.cursor);
			setCursorPosition();
		}

		//mouse move handler.
		private static function onMouseMove(event:MouseEvent):void {
			setCursorPosition();
			event.updateAfterEvent();

			var isSelectableField:Boolean = event.target is TextField && TextField(event.target).selectable;
			if(current)
			{
				current.cursor.visible = !isSelectableField;
			}
			//trace("CurcorManager: target = "+event.target);
		}

		//cursor position to current mouse coords.
		private static function setCursorPosition():void {
			if(!current)
				return;
			current.cursor.x = parent.mouseX + current.offsetX;
			current.cursor.y = parent.mouseY + current.offsetY;
		}

		/**
		 * Removes the cursor using given ID.
		 *
		 * @param cursorId Specifies a cursor id.
		 */
		public static function removeCursor(cursorId:int):int {
			if(cursorId < 0)
				return NO_CURSOR;
			for (var i:Object in cursors) {
				var item:CursorEntry = cursors[i];
				if (item.id == cursorId) {
					cursors.splice(i, 1);
	            	showCursor();
           			break;
				}
			}
			return NO_CURSOR;
		}

		/**
		 * Activates cursor manager.
		 */
		public static function activate():void {
			if (current) {
				current.cursor.visible = true;
			}
		}

		/**
		 * Deactivates cursor manager.
		 */
		public static function deactivate():void
		{
			if (current)
			{
				current.cursor.visible = false;
			}
		}

		private static var cursorMap:Dictionary = new Dictionary(true);
		public static function addCursor(target:InteractiveObject, cursor:Class, hideMouse:Boolean = true, xOffset:int = 0, yOffset:int = 0, priority:int = 2):int
		{
			if(!target)
				return NO_CURSOR;

			var entity:CursorEntry = new CursorEntry(cursor, priority, xOffset, yOffset, hideMouse);
			cursorMap[target] = entity;

			target.addEventListener(MouseEvent.ROLL_OVER, onTarget, false, 0, true);
			target.addEventListener(MouseEvent.ROLL_OUT, onTarget, false, 0, true);

			return entity.id;
		}
		
		public static function removeTargetCursor(target:InteractiveObject):int
		{
			if(target)
			{
				target.removeEventListener(MouseEvent.ROLL_OVER, onTarget);
				target.removeEventListener(MouseEvent.ROLL_OUT, onTarget);
				
				var entity:CursorEntry = cursorMap[target];
				if (entity)
					removeCursor(entity.id);
			}
			return NO_CURSOR;
		}

		private static function onTarget(event:Event):void
		{
			var target:InteractiveObject = getTargetFromEvent(event);
			var entry:CursorEntry = cursorMap[target];
			if(entry)
			{
				if(event.type == MouseEvent.ROLL_OVER)
					setCursorEntry(entry);
				else
					removeCursor(entry.id);
			}
		}

		private static function getTargetFromEvent(event:Event):InteractiveObject
		{
			var target:InteractiveObject = InteractiveObject(event.target);
			if(cursorMap[target])
				return target;

			if(target is DisplayObject)
			{
				var parent:DisplayObjectContainer = DisplayObject(target).parent;
				while(parent!=null)
				{
					if(cursorMap[parent])
						return parent;

					parent = parent.parent;
				}
			}

			if(!parent)
			{
				//Logger.debug('LinkManager: target not found.');
			}

			return null;
		}
	}
}

import flash.display.DisplayObjectContainer;
import flash.display.DisplayObject;
import flash.display.InteractiveObject;


/**
 * Cursor entry. Used to store cursor parameters.
 */
class CursorEntry
{
	private var _cursorClass:Class;
	private var _cursor:DisplayObject;
	private var _priority:int;
	private var _id:int;
	private var _x:int;
	private var _y:int;
	private var _hideMouse:Boolean;

	/**
	 * Creates a new cursor entry. Generates a unique id.
	 *
	 * @param cursorClass Specifies a cursor class.
	 * @param priority Specifies a priority.
	 */
	public function CursorEntry(cursorClass:Class, priority:int = 2, x:int = 0, y:int = 0, hideMouse:Boolean = true):void {
		_id = Math.random() * 100000;
		_cursorClass = cursorClass;
		_cursor = DisplayObject(new cursorClass());
		if(_cursor is InteractiveObject)
			InteractiveObject(_cursor).mouseEnabled = false;
		_priority = priority;
		_x = x;
		_y = y;
		_hideMouse = hideMouse;
	}

	/**
	 * Specifies the priority.
	 */
	public function get priority():int {
		return _priority;
	}

	/**
	 * Specifies the cursor.
	 */
	public function get cursor():DisplayObject {
		return _cursor;
	}

	/**
	 * Specifies the id.
	 */
	public function get id():int {
		return _id;
	}

	/**
	 * Specifies the x offset.
	 */
	public function get offsetX():int {
		return _x;
	}

	/**
	 * Specifies the y offset.
	 */
	public function get offsetY():int {
		return _y;
	}

	/**
	 * Specifies the y offset.
	 */
	public function get hideMouse():Boolean {
		return _hideMouse;
	}

	/**
	 * Specifies the cursorClass.
	 */
	public function get cursorClass():Class
	{
		return _cursorClass;
	}

	/**
	 * Compares two cursor entries.
	 * Return -1 if the first entry is less than second, 0 if equivalent, 1 otherwise.
	 *
	 * @param entry1 Specifies a first entry.
	 * @param entry2 Specifies a second entry.
	 */
	public static function compare(entry1:CursorEntry, entry2:CursorEntry):int {
		return entry1.priority == entry2.priority ? 0 : (entry1.priority > entry2.priority ? 1 : -1);
	}


}
