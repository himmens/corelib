package lib.core.ui.controls
{
import flash.events.Event;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.utils.Timer;

import flash.text.TextLineMetrics;

/**
 * Текстовое поле с "бегущими" точками в конце поля - одна точка, две точки, ...,
 * 
*/
public class RunningLabel extends TextField
{
	protected var delayTimer:Timer = new Timer(400);
	
	/**
	 * Авторазмер текстового поля под текст (с учетом бегущих точек)
	 */
	public var autoSizeField:Boolean = true;
	
	public function RunningLabel()
	{
		super();
		
		delayTimer.addEventListener(TimerEvent.TIMER, onDelayTimer);
		dotsNumber = 5;
	}
	
	protected function measure():void
	{
		if(!text)
			return;
		
		var str:String = text;
		if(running)
			str +=dotsStr;
        
        super.text = str;
	
		if(autoSizeField)
		{
			width = textWidth + 8;
			height = textHeight + 4;
		}
		
		super.text = text;
	}

	private function onDelayTimer(event:Event):void
	{
		currentTick = delayTimer.currentCount%(dotsNumber+1);
		//trace("RunningLabel::onDelayTimer, currentTick="+currentTick);
		if(currentTick == 0)
			restore();
		else
			tick();	
		
		//trace("RunningLabel::onDelayTimer, text="+text +", _text="+_text);
	}
	
	private function restore():void
	{
		super.text = _text;
		currentTick = 0;
	}
	
	private var currentTick:int;
	private function tick():void
	{
		super.text = super.text+".";
	}
	
	protected var _text:String;
	public function run():void
	{
		_text = super.text;
		
		stop();
		delayTimer.start();
	}
	
	public function stop():void
	{
		delayTimer.stop();
		delayTimer.reset();
		restore();
	}
	
	public function set delay (value:int):void
	{
		delayTimer.delay = value;
	}

	public function get delay ():int
	{
		return delayTimer.delay;
	}
	
    override public function set text(value:String):void
    {
    	value = value || "";
    		
    	super.text = value;
    	
    	_text = value;
    	currentTick = 0;
    	if(!_text)
    		stop();
			
		measure();
    }
    
    override public function get text():String
    {
    	return _text;
    }

	public function set running (value:Boolean):void
	{
		if(running != value)
		{
			if(value)
				run();
			else
				stop();
		}
		
		measure();
	}

	public function get running ():Boolean
	{
		return delayTimer.running;
	}
	
	private var dotsStr:String;
	private var _dotsNumber:int;
	public function set dotsNumber (value:int):void
	{
		if(_dotsNumber != value)
		{
			_dotsNumber = value;
			
			dotsStr = "";
			for(var i:int = 0; i<dotsNumber; i++)
				dotsStr+=".";
			
			measure();
		}
	}

	public function get dotsNumber ():int
	{
		return _dotsNumber;
	}

	
}
}