package lib.core.ui.controls
{
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.Timer;

import lib.core.ui.layout.Align;
import lib.core.ui.layout.ColumnLayout;
import lib.core.ui.layout.Container;
import lib.core.ui.layout.RowLayout;
import lib.core.ui.layout.Valign;
import lib.core.util.FunctionUtil;

[Event (name="change", type="flash.events.Event")] 
public class NumericStepper extends Sprite 
{
	protected var inited:Boolean;
	
	protected var container:Container;
	
    protected var border:DisplayObject;
    protected var inputField:TextField;
    protected var buttonUp:ToggleButton;
    protected var buttonDn:ToggleButton;
	
	protected var paddingLeft:uint = 1;
	protected var paddingTop:uint = 1;
	protected var padding:uint = 2;
	protected var paddingButton:uint = 0;
	
	//зажата клавиша down
	private var downPressed:Boolean;
	//зажата клавиша up
	private var upPressed:Boolean;
	
	//флаг - значение изменили вручную с клавиатуры
	private var valueChangedManually:Boolean;
	
	//таймер для задержки применения значения после ввода с клавиатуры
	private var applyChangeTimer:Timer = new Timer(1000, 1);
	
    public function NumericStepper() 
    {
    	super();
		addEventListener(Event.ADDED_TO_STAGE, handler_onStage);
		addEventListener(Event.REMOVED_FROM_STAGE, handler_onStage);
    }
    
	protected function init():void 
	{	
		if (inited)
			return;
		
		initView();

		inputField.restrict = "0-9\\-\\.\\,";
        inputField.maxChars = maxChars;
        inputField.text = String(value);
        inputField.addEventListener(KeyboardEvent.KEY_DOWN, inputField_keyDownHandler);
        inputField.addEventListener(KeyboardEvent.KEY_UP, inputField_keyUpHandler);
        inputField.addEventListener(Event.CHANGE, inputField_changeHandler);
        inputField.addEventListener(FocusEvent.FOCUS_OUT, inputField_focusHandler);
		inited = true;
		updateLayout();
		commitEnabled();
		
		applyChangeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, applyChangeTimer_completeHandler);
	}
	
	protected function initView():void
	{
		addChild(border = createBorder());
		
		addChild(container = new Container(new RowLayout(paddingLeft, paddingTop, padding, Align.LEFT, Valign.MIDDLE)));
		
		container.add(inputField = createTextField());
		
		var buttonContainer:Container = new Container(new ColumnLayout(0, 0, paddingButton));	
		
		buttonContainer.add(buttonUp = createButtonUp());
		buttonUp.addEventListener(MouseEvent.MOUSE_DOWN, handler_buttonMouseDown);
		
		buttonContainer.add(buttonDn = createButtonDn());
		buttonDn.addEventListener(MouseEvent.MOUSE_DOWN, handler_buttonMouseDown);
		
		buttonContainer.arrange();
		
		container.add(buttonContainer);
	}
	
	protected function createBorder():DisplayObject 
	{
		var border:Shape = new Shape(); 
		with (border.graphics) {
			lineStyle(0, 0, 1);
			beginFill(0xffffff, 1);
			drawRect(0, 0, 10, 10);
			endFill();
		}
		return border;
	}
	
	protected function createTextField():TextField 
	{
		var tf:TextField = new TextField();
		tf.defaultTextFormat = new TextFormat("Arial", 12, 0x000000);
		tf.type = TextFieldType.INPUT;
		tf.width = 30;
		tf.height = 20;
		return tf;
	}
	
	protected function createButtonUp():ToggleButton 
	{
		var button:ToggleButton = new ToggleButton();
		var buttonSkin:MovieClip = new MovieClip(); 
		with (buttonSkin.graphics) {
			lineStyle(0, 0, 1);
			beginFill(0xffff00, 1);
			drawRect(0, 0, 15, 10);
			endFill();
		}
		button.setClipState(buttonSkin);
		return button;
	}
	
	protected function createButtonDn():ToggleButton 
	{
		var button:ToggleButton = new ToggleButton();
		var buttonSkin:MovieClip = new MovieClip(); 
		with (buttonSkin.graphics) {
			lineStyle(0, 0, 1);
			beginFill(0xffff00, 1);
			drawRect(0, 0, 15, 10);
			endFill();
		}
		button.setClipState(buttonSkin);
		return button;
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
    
    protected function update(): void 
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
		
		if (valueChanged) {
			valueChanged = false;
			if (inputField)
				inputField.text = String(value);
		}
    } 
    
	protected function updateLayout(): void 
	{
		if (inputField)
			inputField.width = width - Math.max(buttonUp.width, buttonDn.width) - padding - 2*paddingLeft;
		if (container) {
			container.userWidth = width;
			container.userHeight = height;
			container.arrange();
		}
		if (border) {
			border.width = container.width;
			border.height = container.height;
		}
	}
	
	protected var _enabled:Boolean = true;
	public function get enabled():Boolean
	{
		return _enabled;
	}
	public function set enabled(value:Boolean):void
    {
		_enabled = value;
		commitEnabled();
    }
	
	protected function commitEnabled():void
	{
		if (inputField)
			inputField.mouseEnabled = enabled;
		if (buttonUp)
			buttonUp.enabled = buttonUp.mouseEnabled = enabled;
		if (buttonDn)
			buttonDn.enabled = buttonDn.mouseEnabled = enabled;
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
    }

    private var _minimum:Number = 0;
    public function get minimum():Number
    {
        return _minimum;
    }
    public function set minimum(value:Number):void
    {
        _minimum = value;
    }
    
    private var _stepSize:Number = 1;
    public function get stepSize():Number
    {
        return _stepSize;
    }
    public function set stepSize(value:Number):void
    {
        _stepSize = value;
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
    	
    	value = Math.max(minimum, Math.min(value, maximum));
    	value = checkValidValue(value);
    	var changed:Boolean = _value != value; 
    	_value = value;
    	valueChanged = true;
		update();
		
		if (changed)
			dispatchEvent(new Event(Event.CHANGE));	
    }
    
	/**
	 * Время задержки в мсек перед применением введенного с клавиатуры значения
	 */ 
	public function set applyChangeDelay(value:Number):void
	{
		applyChangeTimer.delay = value;
	}
	
    private function checkValidValue(value:Number):Number
    {
        if (isNaN(value))
            return this.value;

        var closest:Number = stepSize * Math.round(value / stepSize);

        // When the stepSize is very small the system tends to put it in
        // exponential format.(ex : 1E-7) The following string split logic
        // cannot work with exponential notation. Hence we add 1 to the stepSize
        // to make it get represented in the decimal format.
        // We are only interested in the number of digits towards the right
        // of the decimal place so it doesnot affect anything else.
        var parts:Array = (new String(1 + stepSize)).split(".");

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
	
	private function startAutoIncrement():void
	{
		if (downPressed || upPressed)
			addEventListener(Event.ENTER_FRAME, handler_enterFrame, false, 0, true);	
	}
	
	private function stopAutoIncrement():void
	{
		downPressed = false;
		upPressed = false;
		removeEventListener(Event.ENTER_FRAME, handler_enterFrame);	
	}
    
//-----------------------Handlers---------------------------------	
	
    protected function handler_buttonMouseDown(event:MouseEvent):void 
    {
    	var button:ToggleButton = ToggleButton(event.target);
    	if (button == buttonDn) {
	    	downPressed = true;
			upPressed = false;
	    	value -= stepSize;
	    }
    	else if (button == buttonUp) { 
    		upPressed = true;
			downPressed = false;
    		value += stepSize;
    	}
		
		FunctionUtil.callLater(startAutoIncrement, 30);
    }
    
    protected function handler_mouseUp(event:MouseEvent):void 
    {
    	stopAutoIncrement();
    }
    
	protected function handler_mouseWheel(event:MouseEvent):void 
	{
		if (!enabled)
			return;
		
		var delta:Number = event.delta;
		value += stepSize*delta/Math.abs(delta);
	}
	
    protected function inputField_keyDownHandler(event:KeyboardEvent):void
    {
        switch (event.keyCode)
        {
            case Keyboard.DOWN:
            	downPressed = true;
                value -= stepSize;
                FunctionUtil.callLater(startAutoIncrement, 30);
                break;
            case Keyboard.UP:
            	upPressed = true;
                value += stepSize;
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
    
    protected function inputField_keyUpHandler(event:KeyboardEvent):void
    {
    	stopAutoIncrement();
    }
    
    protected function inputField_changeHandler(event:Event):void 
    {
		 event.stopImmediatePropagation();
		 
		 var inputValue:Number = Number(inputField.text);
         _value = checkValidValue(inputValue);
		 valueChangedManually = true;
		 
		 //перезапускаем таймер для применения изменений
		 applyChangeTimer.reset();
		 applyChangeTimer.start();
    }
	
    protected function inputField_focusHandler(event:Event):void 
    {
		checkChange();
    }
	
    protected function applyChangeTimer_completeHandler(event:TimerEvent):void 
    {
		checkChange();
	}
    
    protected function handler_enterFrame(event:Event):void 
    {
    	if (upPressed)
			value += stepSize;
		else if (downPressed)
			value -= stepSize;	
    }
    
	protected function handler_onStage(event:Event):void
	{
		if(event.type == Event.ADDED_TO_STAGE)
		{
			addEventListener(MouseEvent.MOUSE_WHEEL, handler_mouseWheel);
			stage.addEventListener(MouseEvent.MOUSE_UP, handler_mouseUp);
			init();
		}else
		{
			removeEventListener(MouseEvent.MOUSE_WHEEL, handler_mouseWheel);
			stage.removeEventListener(MouseEvent.MOUSE_UP, handler_mouseUp);
		}
	}
}
}
