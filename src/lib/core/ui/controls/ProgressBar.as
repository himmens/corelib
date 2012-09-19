package lib.core.ui.controls
{
import com.gskinner.motion.GTween;
import com.gskinner.motion.easing.Quadratic;

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;

import lib.core.util.Graph;

public class ProgressBar extends Sprite
{
	protected var border:DisplayObject;
	protected var bar:DisplayObject;
	
	//Использовать анимацию для прогресса
	public var useTween:Boolean = true;
	
	//Не начинаем новый твин, пока анимируем предыдущий
	public var waitTween:Boolean = true;
	protected var tween:GTween;
	
	//текущая позиция прогресса
	public var viewProgress:Number;
	
	public function ProgressBar()
	{
		super();
		init();
	}
	
	protected function init():void
	{
		if (!border)
			border = createBorder();
		if (!bar)
			bar = createBar();
		
		addChild(border);
		addChild(bar);
		
		if (useTween && !tween)
		{
			tween = new GTween(this, 0.5, null, {autoPlay:false, ease:Quadratic.easeOut});
			tween.onChange = onTweenChange;
			tween.onComplete = onTweenComplete;
		}
		arrange();
		setProgress(0);
	}
	
	protected function createBorder():DisplayObject
	{
		var border:Shape = new Shape();
		Graph.drawFillRec(border.graphics, 0, 0, 10, 10);
		return border;
	}
	
	protected function createBar():DisplayObject
	{
		var bar:Shape = new Shape();
		Graph.drawFillRec(bar.graphics, 0, 0, 10, 10, 0xff0000);
		return bar;
	}
	
	public var progressMin:Number = 0;
	public var progressMax:Number = 1;
	
	/**
	 * Прогресс от 0 до 1
	 */ 
	protected var _progress:Number;
	public function get progress():Number
	{
		return _progress;
	}
	public function set progress(value:Number):void
	{
		value = Math.max(progressMin, Math.min(value, progressMax));
		if (_progress != value)
		{
			_progress = value;
			commitProgress();
		}
	}
	
	public function setProgress(value:Number, useTween:Boolean = false):void
	{
		var curUseTween:Boolean = this.useTween;
		this.useTween = useTween;
		progress = value;
		this.useTween = curUseTween;
	}
	
	protected function commitProgress():void
	{
		if (useTween && tween)
		{
			if (viewProgress != progress)
			{
				//Если ждем завершения старого твина, то новый не запускаем, пока играется старый
				if (tween.paused || !waitTween)
				{
					tween.setValues({viewProgress:progress});
					tween.paused = false;
				}
			}
		}
		else
		{
			viewProgress = progress;
			commitViewProgress();
		}
	}
	
	/**
	 * Применяем текущий прогресс к визуалке
	 */ 
	protected function commitViewProgress():void
	{
		var barWidth:Number = (width - 2*padding)*viewProgress;
		if (bar)
			bar.width = (width - 2*padding)*viewProgress;
	}
	
	protected function arrange():void
	{
		if (border)
		{
			border.width = width;
			border.height = height;
		}
		if (bar)
		{
			bar.x = padding;
			bar.y = padding;
			bar.height = height - 2*padding;
		}
	}
	
	protected var _width:Number = 100;
	override public function get width():Number 
	{
		return _width;
	}
	override public function set width(value:Number):void 
	{
		if (_width != value)
		{
			_width = value;
			arrange();
		}
	}
	
	protected var _height:Number = 10;
	override public function get height():Number 
	{
		return _height;
	}
	override public function set height(value:Number):void 
	{
		if (_height != value)
		{
			_height = value;
			arrange();
		}
	}
	
	protected var _padding:Number = 1;
	public function get padding():Number 
	{
		return _padding;
	}
	public function set padding(value:Number):void 
	{
		if (_padding != value)
		{
			_padding = value;
			arrange();
		}
	}
	
	private function onTweenChange(tween:GTween):void
	{
		commitViewProgress();
	}
	
	private function onTweenComplete(tween:GTween):void
	{
		commitProgress();
	}
}
}