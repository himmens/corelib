package lib.core.ui.controls
{
import lib.core.ui.layout.RowLayout;
import lib.core.util.FunctionUtil;
import lib.core.util.Graph;
import lib.core.util.log.Logger;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.Timer;

[Event (name="change", type="flash.events.Event")] 
public class NumericSlider extends Sprite
{
	protected var inputField:TextField;
	protected var slider:Slider;
	protected var spacing:int = 10;
	protected var inited:Boolean;
	//флаг - значение изменили вручную с клавиатуры
	private var valueChangedManually:Boolean;
	
	public var autoLayout:Boolean = true;
	
	//таймер для задержки применения значения после ввода с клавиатуры
	private var applyChangeTimer:Timer = new Timer(500, 1);

	protected var ticks:SimpleList;
	protected var ticksRenderer:Class;
	
	public function NumericSlider()
	{
		super();
		
		init();
	}
	
	protected function init():void
	{
		addChild(inputField = createTextField());
		addChild(slider = createSlider());
		
		inputField.restrict = "0-9\\-\\.\\,";
		inputField.maxChars = maxChars;
		inputField.text = String(value);
		inputField.addEventListener(Event.CHANGE, onInputFieldChange);
		inputField.addEventListener(FocusEvent.FOCUS_OUT, onInputFieldFocus);
	
		addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		
		slider.addEventListener(Event.CHANGE, onSliderChange);
		slider.drapPosChecker = dragPosChecher;
		applyChangeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onApplayChangesTimer);
	
		ticks = new SimpleList();
		ticks.itemRenderer = ticksRenderer || Tick;
		addChild(ticks);
		
		inited = true;
		updateLayout();
	}
	protected function createTextField():TextField 
	{
		var tf:TextField = new TextField();
		tf.defaultTextFormat = new TextFormat("Arial", 12, 0x000000);
		tf.type = TextFieldType.INPUT;
		tf.width = inputWidth;
		tf.height = 20;
		tf.border = true;
		tf.backgroundColor = 0xFFFFFF;
		tf.background = true;
		return tf;
	}
	
	protected function createSlider():Slider
	{
		var slider:Slider = new Slider();
		return slider;
	}
	
	protected function updateLater(): void
	{
		FunctionUtil.callLater(update);
	}
	
	public function update(): void 
	{
		if (!inited)
			return;
		
		if (sizeChanged) {
			sizeChanged = false;
			updateLayout();
		}
		
		if (maxCharsChanged) {
			maxCharsChanged = false;
			if (inputField)
				inputField.maxChars = maxChars;
		}
		
		if (valueChanged) 
		{
			valueChanged = false;
			setTextValue();
			setSliderValue();
		}
		
		if(_stepChange)
		{
			_stepChange = false;
			
			//нельзя, чтобы максимум оказался меньеш минимума, сломается отрисовка тиков
			_maximum = Math.max(maximum, minimum);
			slider.step = step/(maximum - minimum);
			if(autoTickStep)
			{
				var delta:Number = (maximum - minimum);
				_tickStep = Math.round(delta/20);
			}
			
			if(tickStep)
			{
				var sliderWidth:Number = slider.width;
				var scale:Number = sliderWidth/(maximum - minimum);
				var tickSize:Number = (new ticks.itemRenderer()).width;
				var spacing:Number = scale*tickStep - tickSize;
				var closerTick:Number = Math.ceil(minimum/tickStep)*tickStep; //ближайщий тик к минимуму справа
				var tickStartX:int = scale*(closerTick-minimum);
				var tickCnt:int = Math.floor((maximum-minimum)/tickStep);
				ticks.layout = new RowLayout(tickStartX, 0, spacing);
				ticks.dataProvider = new Array(tickCnt);
			}
			
		}
	}
	
	/**
	 * функция прилипания с палочкам тиков
	 * @param pos
	 * @return 
	 */
	protected function dragPosChecher(pos:Number):Number
	{
		if(stickToTickStep && tickStep && step)
		{
			var scale:Number = (maximum - minimum);	//коэфф. перевода позиции pos (диапазон 0-1) в единицы измерения
			var numPos:Number = minimum + scale*pos//позиция бегунка в абсолютных единицах относительно нуля
			var closerTick:Number = Math.round(numPos/tickStep)*tickStep; //ближайщий тик к текущей позиции (слева или справа)
			var stepsDelta:Number = Math.abs(closerTick - numPos);	//расстояние от позиции бегунка до ближайшего тика
			if(stepsDelta < stickToTickStep*step)
				pos = (closerTick - minimum)/scale;
			
//			Logger.debug(this, "closerTick = ", closerTick, "numPos", numPos, "stepsDelta = ", stepsDelta);
//			scale = slider.width/(maximum - minimum);
//			slider.graphics.clear();
//			Graph.drawLine(slider.graphics, (closerTick - minimum)*scale, 0, (closerTick - minimum)*scale, -20, 1, 0xFF0000, 1);
		}
		
		return pos;
	}
	
	protected function setTextValue():void
	{
		if (inputField)
			inputField.text = String(value);
	}
	
	protected function setSliderValue():void
	{
		if(slider)
		{
			skipSliderEvent = true;
			slider.position = (value - minimum)/(maximum - minimum);
			skipSliderEvent = false;
		}
	} 
	
	private function checkValidValue(value:Number):Number
	{
		if (isNaN(value))
			return this.value;
		
		var closest:Number = value;
		if(step)
		{
			closest = step * Math.round(closest / step);
		}
		
		// When the stepSize is very small the system tends to put it in
		// exponential format.(ex : 1E-7) The following string split logic
		// cannot work with exponential notation. Hence we add 1 to the stepSize
		// to make it get represented in the decimal format.
		// We are only interested in the number of digits towards the right
		// of the decimal place so it doesnot affect anything else.
		var parts:Array = (new String(1 + step)).split(".");
		
		// we need to do the round of (to remove the floating point error)
		// if the stepSize had a fractional value
		if (parts.length == 2)
		{
			var scale:Number = Math.pow(10, parts[1].length);
			closest = Math.round(closest * scale) / scale;
		}
		
		return Math.max(minimum, Math.min(maximum, closest));	
	}
	
	private function checkChange():void 
	{
		if(valueChangedManually)
		{
			valueChangedManually = false;
			valueChanged = true;
			update();
			
			dispatchEvent(new Event(Event.CHANGE));	
		}
	}
	
	protected function onApplayChangesTimer(event:TimerEvent):void 
	{
		checkChange();
	}
	
	protected var skipSliderEvent:Boolean;
	protected function onSliderChange(event:Event):void 
	{
		if(skipSliderEvent)
			return;
		
		event.stopImmediatePropagation();
		
		//Logger.debug(this, "onSliderChange: pos = ", slider.position);
		var pos:Number = slider.position;
		var newValue:Number = checkValidValue(minimum + (maximum - minimum)*pos);
		if(value != newValue)
		{
			_value = newValue;
			setTextValue();
			dispatchEvent(new Event(Event.CHANGE));	
		}
	}
	
	protected function onInputFieldChange(event:Event):void 
	{
		event.stopImmediatePropagation();
		
		var inputValue:Number = Number(inputField.text);
		_value = checkValidValue(inputValue);
		valueChangedManually = true;
	
		//перезапускаем таймер для применения изменений
		applyChangeTimer.reset();
		applyChangeTimer.start();
	}
	
	protected function onInputFieldFocus(event:Event):void 
	{
		checkChange();
	}
	
	private var leftPressed:Boolean;
	private var rightPressed:Boolean;
	
	protected function onKeyDown(event:KeyboardEvent):void
	{
		switch (event.keyCode)
		{
			case Keyboard.RIGHT:
				rightPressed = true;
				value += step;
				FunctionUtil.callLater(startAutoIncrement, 30);
				break;
			case Keyboard.LEFT:
				leftPressed = true;
				value -= step;
				FunctionUtil.callLater(startAutoIncrement, 30);
				break;
			case Keyboard.HOME:
				value = minimum;
				break;
			case Keyboard.END:
				value = maximum;
				break;
			case Keyboard.ENTER:
			case Keyboard.TAB:
				var inputValue:Number = Number(inputField.text);
				value = inputValue;
				break;
		}
	}
	
	protected function onKeyUp(event:KeyboardEvent):void
	{
		stopAutoIncrement();
	}
	
	private function startAutoIncrement():void
	{
		if (leftPressed || rightPressed)
			addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);	
	}
	
	private function stopAutoIncrement():void
	{
		leftPressed = false;
		rightPressed = false;
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);	
	}
	
	protected function onEnterFrame(event:Event):void 
	{
		if (rightPressed)
			value += step;
		else if (leftPressed)
			value -= step;	
	}
	
	protected var _maxChars:int = 0;
	protected var maxCharsChanged:Boolean = false;
	public function get maxChars():int
	{
		return _maxChars;
	}
	
	public function set maxChars(value:int):void
	{
		if (value == _maxChars)
			return;
		
		_maxChars = value;
		maxCharsChanged = true;
		update();
	}
	
	/**
	 * число шагов за которые надо прилипать к отсетке, 0 - не прилипать
	 */
	public var stickToTickStep:Number = 1.5;
	
	private var _tickStep:Number = 0;
	private var _stepChange:Boolean;
	
	public var autoTickStep:Boolean = true;
	/**
	 * шаг отрисовки тиков
	 * @param value
	 * 
	 */
	public function set tickStep(value:Number):void 
	{
		autoTickStep = false;
		
		if(tickStep != value)
		{
			_tickStep = Math.max(value, 0);
			_stepChange = true;
			update();
		}
	}
	public function get tickStep():Number 
	{
		return _tickStep;
	}
	
	private var _step:Number = 1;
	public function get step():Number
	{
		return _step;
	}
	public function set step(value:Number):void
	{
		if(step != value)
		{
			_step = value;
			_stepChange = true;
			updateLater();
		}
	}
	
	private var _minimum:Number = 0;
	public function get minimum():Number
	{
		return _minimum;
	}
	public function set minimum(value:Number):void
	{
		_minimum = value;
		if (_value < _minimum)
			this.value = _minimum;
		_stepChange = true;
		updateLater();
	}
	
	private var _maximum:Number = 10;
	public function get maximum():Number
	{
		return _maximum;
	}
	public function set maximum(value:Number):void
	{
		_maximum = value;
		// Если текущее значение больше нового максимального, уменьшаем его до
		// максимального
		if (_value > _maximum)
			this.value = _maximum;
		_stepChange = true;
		updateLater();
	}
	
	
	private var _value:Number = 0;
	private var valueChanged:Boolean;
	public function get value():Number
	{
		return _value;
	}
	public function set value(value:Number):void
	{
		if (_value == value)
			return;	
		
		//value = Math.max(minimum, Math.min(value, maximum));
		value = checkValidValue(value);
		var changed:Boolean = _value != value; 
		_value = value;
		valueChanged = true;
		updateLater();
		
		if (changed)
			dispatchEvent(new Event(Event.CHANGE));	
	}
	
	protected function updateLayout():void
	{
		
		if(autoLayout)
		{
			inputField.width = inputWidth;
			
			slider.x = inputField.width + spacing;
			slider.y = (inputField.height - slider.height) >> 1;
			//slider.x = 0;
			//slider.y = 40;
			ticks.x = slider.x;
			
			ticks.y = slider.y;
			
			slider.width = width - inputField.width;
			//slider.width = width;
		}
	}
	
	protected var sizeChanged:Boolean;
	
	protected var _width:Number = 40;
	override public function get width():Number 
	{
		return _width;
	}
	override public function set width(value:Number):void 
	{
		_width = value;
		sizeChanged = true;
		FunctionUtil.callLater(update);
	}
	
	protected var _height:Number = 20;
	override public function get height():Number 
	{
		return _height;
	}
	override public function set height(value:Number):void 
	{
		_height = value;
		sizeChanged = true;
		FunctionUtil.callLater(update);
	}
	
	protected var _inputWidth:Number = 40;
	public function get inputWidth():Number 
	{
		return _inputWidth;
	}
	public function set inputWidth(value:Number):void 
	{
		_inputWidth = value;
		sizeChanged = true;
		FunctionUtil.callLater(update);
	}
}
}


import flash.display.Sprite;

internal class Tick extends Sprite
{
	public function Tick()
	{
		graphics.lineStyle(2, 0x666666);
		graphics.moveTo(0, -3);
		graphics.lineTo(0, 0);
	}
}
