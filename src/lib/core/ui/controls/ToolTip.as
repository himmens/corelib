package lib.core.ui.controls
{
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.InteractiveObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Dictionary;
import flash.utils.Timer;

import lib.core.util.log.Logger;

/**
* ToolTop для любого интерактивного объекта.
*/
public class ToolTip extends Sprite
{
	//------------------------------------------------------------------------------
	//
	// Static
	//
	//------------------------------------------------------------------------------
	public static var stage:Stage;

	private static var tooltipMap:Dictionary = new Dictionary(true);
	private static var tooltip:ToolTip;
	private static var currentTarget:InteractiveObject;

	private static var showTimer:Timer = new Timer(200, 1);
	public static function set showDelay(value:int):void{showTimer.delay = value;}

	public static var defaultFormat:TextFormat =  new TextFormat("Arial", 12, 0x5F3813 );
	public static var defaultBorderColor:uint =  0x5F3813;
	public static var defaultBorderThickness:uint =  1;
	public static var defaultBorderAlpha:Number =  1;
	public static var defaultBackgroundColor:uint =  0xF2E9D5;
	public static var defaultCornerRadius:uint =  2;
	public static var defaultEmbedFonts:Boolean =  false;
	public static var padding:Point = new Point(10, 10);

	/**
	 * Добавляет тултип к любому интерактивному объекту.
	 *
	 * @param target
	 * @param text
	 * @param multiline
	 * @param width
	 * @param relativePoint относительная точка выравнивания тултипа,
	 * координата x используется для выравнивания по вертикали,
	 * координата y для выравнивания по горизонтали,
	 * при этом положительные значения выравнивают правее/ниже на заданное значение,
	 * отрицательные - левее/выше, если значение равно 0, то выравнивание идет по центру относительно ширины/высоты объекта
	 * Например, new Point(0, -10) - установит тултип выше объекта по y на 10 пикселей и отцентрует по x
	 * @param shift смещение тултипа относительно рассчитанного положения.
	 * @return
	 *
	 */
	public static function addToolTip(target:InteractiveObject, text:String, multiline:Boolean = false, width:Number = 100, relativePoint:Point = null, shift:Point = null):ToolTip
	{
		if(!target || !stage)
			return null;

		if(!text)
			return null;

		if(tooltipMap[target] != null && tooltipMap[target].text == text)
			return null;

		if(!shift)
		{
			shift = new Point(0, 0);
		}

		var obj:Object = {text:text, multiline:multiline, width:width, relativePoint:relativePoint, shift: shift};
		return addTarget(target, obj);
	}

	/**
	 * Добавляет произвольный контент в тултип
	 * @param target
	 * @param object
	 * @param relativePoint относительная точка выравнивания тултипа,
	 * координата x используется для выравнивания по вертикали,
	 * координата y для выравнивания по горизонтали,
	 * при этом положительные значения выравнивают правее/ниже на заданное значение,
	 * отрицательные - левее/выше, если значение равно 0, то выравнивание идет по центру относительно ширины/высоты объекта
	 * Например, new Point(0, -10) - установит тултип выше объекта по y на 10 пикселей и отцентрует по x
	 * @param data будет передана в объект тултипа при наведении в поле data
	 * @return
	 *
	 */
	public static function addToolTipObject(target:InteractiveObject, object:DisplayObject, relativePoint:Point = null, data:Object = null):ToolTip
	{
		if(!target || !stage || !object)
			return null;

		if(tooltipMap[target] != null && (tooltipMap[target].object == object) && (tooltipMap[target].data == data))
			return null;

		if(object is Sprite)
			Sprite(object).mouseChildren = Sprite(object).mouseEnabled = false;

		return addTarget(target, {object:object, relativePoint:relativePoint, data:data});
	}

	private static function addTarget(target:InteractiveObject, obj:Object):ToolTip
	{
		tooltipMap[target] = obj;
		target.addEventListener(MouseEvent.ROLL_OVER, onTargetMouse, false, 0, true);
		target.addEventListener(MouseEvent.ROLL_OUT, onTargetMouse, false, 0, true);

		if(!tooltip)
		{
			if (!tooltipRenderer)
				tooltipRenderer = ToolTip;

			tooltip = new tooltipRenderer(defaultBorderColor, defaultBackgroundColor, defaultFormat, defaultCornerRadius, defaultBorderAlpha, defaultBorderThickness, defaultEmbedFonts);

			tooltip.visible = false;
			stage.addChild(tooltip);
		}

		if(tooltip.visible && currentTarget == target)
		{
			onShowTimer();
		}else
			showTimer.addEventListener(TimerEvent.TIMER, onShowTimer);

		return tooltip;
	}

	public static function removeToolTip(target:InteractiveObject):void
	{
		tooltipMap[target] = null;

		target.removeEventListener(MouseEvent.ROLL_OVER, onTargetMouse);
		target.removeEventListener(MouseEvent.ROLL_OUT, onTargetMouse);
		target.removeEventListener(MouseEvent.MOUSE_MOVE, onTargetMouse);
		//delete tooltipMap[target];

		if (currentTarget && currentTarget == target)
			tooltip.visible = false;
	}

	private static function onTargetMouse(event:MouseEvent):void
	{
		if(event.type == MouseEvent.ROLL_OVER)
		{
			currentTarget = event.target as InteractiveObject;
			showTimer.start();
		}else if(event.type == MouseEvent.ROLL_OUT)
		{
			showTimer.stop();
			tooltip.visible = false;
			if(currentTarget)
			{
				currentTarget.removeEventListener(MouseEvent.MOUSE_MOVE, onTargetMouse, false);
				currentTarget.removeEventListener(Event.REMOVED_FROM_STAGE, onTargetRemoved, false);
			}

			currentTarget = null;
		}else if(event.type == MouseEvent.MOUSE_MOVE)
		{
			if(tooltip.visible)
			{
				var currentData:Object = tooltipMap[currentTarget];
				arrangeTooltip(event.stageX, event.stageY, currentData.shift);
			}

			event.updateAfterEvent();
		}
	}

	private static function onTargetRemoved(event:Event):void
	{
		//при удалении таргета делаем ROLL_OUT
		onTargetMouse(new MouseEvent(MouseEvent.ROLL_OUT));
	}

	protected static function relativeArrangeTooltip(relativePoint:Point, shift:Point):void
	{
		if(!stage)
			return;

		var rx:Number = relativePoint.x;
		var ry:Number = relativePoint.y;
		//var pad:Number = 10;

		var p:Point = currentTarget.localToGlobal(currentTarget.getBounds(currentTarget).topLeft);
		var x:Number = p.x;
		var y:Number = p.y;
		var w:Number = currentTarget.width;
		var h:Number = currentTarget.height;

		tooltip.arrange();
//		trace("Tootlip: ", x, y, w, h, tooltip.width, tooltip.height);

		if (rx < 0)
		{
			x -= (tooltip.width - rx);
		}
		else if (rx > 0)
		{
			x += (w + rx);
		}
		else
		{
			x += ((w - tooltip.width)>>1)
		}

		if (ry < 0)
		{
			y -= (tooltip.height - ry);
		}
		else if (ry > 0)
		{
			y += (h + ry);
		}
		else
		{
			y += ((h - tooltip.height)>>1);
		}

		if (shift)
		{
			x += shift.x;
			y += shift.y;
		}

		if(x+tooltip.width+padding.x > stage.stageWidth)
			x = stage.stageWidth - (tooltip.width+padding.x);
		if (x < padding.x)
			x = padding.x;

		if(y < padding.y)
			y = padding.y;
		if(y+tooltip.height+padding.y > stage.stageHeight)
			y = stage.stageHeight - (tooltip.height+padding.y);

		tooltip.x = int(x);
		tooltip.y = int(y);

		//поднимаем тултип наверх
		stage.addChild(tooltip);
	}

	protected static function arrangeTooltip(stageX:Number, stageY:Number, shift:Point):void
	{
		if(!stage)
			return;

		var x:Number = stageX;
		var y:Number = stageY;
		/*var pad:Number = 10;

		var padX:Number = pad + shift.x;
		var padY:Number = pad + shift.y;*/


		tooltip.arrange();

		if(x+tooltip.width+padding.x > stage.stageWidth)
		{
			x-=(tooltip.width+padding.x);
		}
		if(y-tooltip.height-padding.y < 0)
		{
			y+=(tooltip.height+padding.y);
		}

		if (shift)
		{
			x += shift.x;
			y += shift.y;
		}

		tooltip.x = int(x + padding.x/2);
		tooltip.y = int(y - tooltip.height - padding.y/2);

		//поднимаем тултип наверх
		stage.addChild(tooltip);
	}

	private static function onShowTimer(event:Event = null):void
	{
		if(tooltip && stage && currentTarget)
		{
			currentTarget.addEventListener(MouseEvent.MOUSE_MOVE, onTargetMouse, false, 0, true);
			currentTarget.addEventListener(Event.REMOVED_FROM_STAGE, onTargetRemoved, false, 0, true);

			var currentData:Object = tooltipMap[currentTarget];
			if (currentData)
			{
				tooltip.multiline = currentData.multiline;
				tooltip.width = int(currentData.width);

				if(currentData.text)
					tooltip.text = String(currentData.text);
				else if(currentData.object)
				{
					if(currentData.object.hasOwnProperty("tooltipTarget")) currentData.object.tooltipTarget = currentTarget;
					if(currentData.data && currentData.object.hasOwnProperty("data")) currentData.object.data = currentData.data;
					tooltip.object = currentData.object;
				}

				if (currentData.relativePoint)
				{
					currentTarget.removeEventListener(MouseEvent.MOUSE_MOVE, onTargetMouse);
					relativeArrangeTooltip(currentData.relativePoint, currentData.shift);
				}
				else
					arrangeTooltip(stage.mouseX, stage.mouseY, currentData.shift);

				tooltip.visible = true;

			}
		}
	}


	//------------------------------------------------------------------------------
	//
	// Tooltip body
	//
	//------------------------------------------------------------------------------
	protected var border:Sprite;
	protected var _borderColor:uint;
	protected var _borderThickness:uint;
	protected var _backgroundColor:uint;
	protected var _cornerRadius:uint;
	protected var _borderAlpha:Number;

	protected var textField:TextField;
	protected var _format:TextFormat;
	protected var _text:String;
	protected var _embedFonts:Boolean;

	protected var _object:DisplayObject;

	/**
	 * рендерер текстового поля, которое будет создаватся в тултипе.
	 * можно задать наследника TextField , который например может всталвять
	 * в себя иконки
	 */
	public static var textFieldRenderer:Class = TextField;

	public static var tooltipRenderer:Class;

	//TODO
	private var _skin:Sprite; //Sprite с полями textField, border
	public function ToolTip(borderColor:uint, backgroundColor:uint, format:TextFormat, cornerRadius:uint = 2, borderAlpha:Number = .9, borderThickness:Number = 1, embedFonts:Boolean = false)
	{
		_borderColor = borderColor;
		_backgroundColor = backgroundColor;
		_format = format;
		_cornerRadius = cornerRadius;
		_borderAlpha = borderAlpha;
		_borderThickness = borderThickness;
		_embedFonts = embedFonts;

		init();
	}

	protected function init():void
	{
		mouseEnabled = mouseChildren = false;

		createBorder();
		createTextField();
		commitTextProperties();

		arrange();
	}

	public function set object(value:DisplayObject):void
	{
		if(_object != value)
		{
			if(_object)
				removeObject();

			_object = value;
			commitObject();
		}
	}

	public function get object():DisplayObject
	{
		return _object;
	}

	protected function createBorder():void
	{
		addChild(border = new Sprite());

		//border.filters = [new DropShadowFilter(3, 45, 0x000000, .5, 5, 5, 1, BitmapFilterQuality.HIGH)];
	}

	protected function createTextField():void
	{
		addChild(textField = new textFieldRenderer());

		textField.selectable = false;
		textField.multiline = false;
		textField.wordWrap = false;
		textField.autoSize = TextFieldAutoSize.LEFT;

		commitFormat();
	}

	protected var _width:int;
	protected var _height:int;

	protected function arrange():void
	{
		_width = 0;
		_height = 0;

		if(text)
		{
			_width = Math.max(20, textField.textWidth)+10;
			_height = Math.max(10, textField.textHeight)+5;
			textField.x = 3;
			textField.y = 1;
			textField.visible = true;
		}else if(_object)
		{
			_width = object.width;
			_height = object.height;
		}

		drawBorder(_width, _height);
	}

	protected function drawBorder(width:Number, height:Number):void
	{
		var gr:Graphics = border.graphics;
		gr.clear();

		//в случае скина просто выставляем размеры скину бордера
		if(_skin)
		{
			border.width = width;
			border.height = height;

			return;
		}

		if(object)
		{
			return;
		}

		//border
		gr.beginFill(borderColor, borderAlpha);
		gr.drawRoundRect(0, 0, width, height, 2*cornerRadius, 2*cornerRadius);
		gr.endFill();

		//background
		gr.beginFill(backgroundColor, borderAlpha);
		gr.drawRoundRect(borderThickness, borderThickness, width-2*borderThickness, height-2*borderThickness, 2*cornerRadius, 2*cornerRadius);
		gr.endFill();
	}

	protected function commitFormat():void
	{
		if(format)
		{
			textField.defaultTextFormat = format;
			textField.setTextFormat(format);

			arrange();
		}
	}

	protected function removeObject():void
	{
		if(_object && _object.parent && contains(_object))
			removeChild(_object);
	}

	protected function commitObject():void
	{
		//Logger.debug(this, "commitObject: ",_object);
		textField.visible = false;
		_text = "";

		if(_object)
			addChild(_object);

		arrange();
	}

	protected function commitText():void
	{
		//Logger.debug(this, "commitText: ",text);
		removeObject();
		_object = null;

		textField.htmlText = text;
		arrange();
	}

	protected function commitTextProperties():void
	{
		textField.embedFonts = embedFonts;
		textField.multiline = multiline;
		textField.wordWrap = multiline;
		arrange();
	}

	public function set format(value:TextFormat):void
	{
		_format = value;
		commitFormat();
	}

	public function get format():TextFormat
	{
		return _format;
	}

	public function set text(value:String):void
	{
		if(_text != value)
		{
			_text = value;
			commitText();
		}
	}

	public function get text():String
	{
		return _text;
	}

	public function set embedFonts(value:Boolean):void
	{
		if(_embedFonts != value)
		{
			_embedFonts = value;
			commitTextProperties();
		}
	}

	public function get embedFonts():Boolean
	{
		return _embedFonts;
	}

	public function set borderColor(value:uint):void
	{
		if(_borderColor != value)
		{
			_borderColor = value;
			arrange();
		}
	}

	public function get borderColor():uint
	{
		return _borderColor;
	}

	public function set backgroundColor(value:uint):void
	{
		if(_backgroundColor != value)
		{
			_backgroundColor = value;
			arrange();
		}
	}

	public function get backgroundColor():uint
	{
		return _backgroundColor;
	}

	public function set cornerRadius(value:uint):void
	{
		if(_cornerRadius != value)
		{
			_cornerRadius = value;
			arrange();
		}
	}

	public function get cornerRadius():uint
	{
		return _cornerRadius;
	}

	public function set borderAlpha(value:Number):void
	{
		if(_borderAlpha != value)
		{
			_borderAlpha = value;
			arrange();
		}
	}

	public function get borderAlpha():Number
	{
		return _borderAlpha;
	}

	public function set borderThickness(value:Number):void
	{
		if(_borderThickness != value)
		{
			_borderThickness = value;
			arrange();
		}
	}

	public function get borderThickness():Number
	{
		return _borderThickness;
	}

	private var _multiline:Boolean = false;
	public function set multiline (value:Boolean):void
	{
		if(_multiline != value)
		{
			_multiline = value;
			commitTextProperties();
		}
	}

	public function get multiline ():Boolean
	{
		return _multiline;
	}

	override public function set width (value:Number):void
	{
		if(textField.width != value)
		{
			textField.width = value;
			arrange();
		}
	}
	override public function get width ():Number
	{
//		return Math.max(20, textField.textWidth)+10;
		return _width;
	}
	override public function get height ():Number
	{
		return _height;
	}

}
}