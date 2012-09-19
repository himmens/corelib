package lib.core.util.vectorcacher
{

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.PixelSnapping;
import flash.display.Scene;
import flash.events.Event;
import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;
import flash.utils.getTimer;

import lib.core.util.log.Logger;

/**
 * кеширование завершено
 */
[Event (name="cacheComplete", type="flash.events.Event")]
[Event (name="animComplete", type="flash.events.Event")]

public class MovieClipCacher extends MovieClip
{
	public static const CACHE_COMPLETE:String = "cacheComplete";
	public static const ANIM_COMPLETE:String = "animComplete";

	protected var _currentFrame:int = 1;

	//текущий отрисованный кадр
	protected var _drawFrame:int = 0;
	protected var _totalFrames:int = 1;
	protected var _plaing:Boolean = false;

	protected var _clip:MovieClip;
	protected var _frame:Bitmap;
	//карта номеров ключевых кадров
	protected var _keyFrames:Object;

	protected var _keyFrameName:String;

	//массив объектов типа {x:int, y:int, bd:BitmapData}
	protected var _cache:Array;
	public function get cache():Array{return _cache};
	public function set cache(value:Array):void
	{
		_cache = value;
		_cachingComplete = isAllCached(value);
		_totalFrames = cache.length;
		_bitmapCounter = 0;
	};

	/**
	 *  имя клипа в кадре - индикатора, что кадр ключевой. (оптимизация). Если его задать. будет
	 * 		делаться скриншот только тех кадров, в которых есть клип с таким именем.
	 */
	public var keyFrameMarkerName:String;

	/**
	 * Запустить play автоматически при создании
	 */
	public var autoPlay:Boolean = true;
	/**
	 * Запустить stop автоматически в конце таймлайна
	 */
	public var autoStop:Boolean = false;

	/**
	 * добавится к логу после завершения кеширования
	 */
	public var debugStr:String = "";
	public var debugLog:Boolean = false;

	public var drawColorTransform:Boolean = false;

	//идет кеширование
	protected var _cachingComplete:Boolean;
	/**
	 * Кеширование векторного клипа завершено
	 * @return
	 */
	public function get cachingComplete():Boolean{return _cachingComplete};

	//отладочный счетчик уникальных битмапов
	protected var _bitmapCounter:int;

	public function MovieClipCacher()
	{
		super();

		init();
	}

	protected function init():void
	{
		_frame = new Bitmap(null, PixelSnapping.AUTO, true);
		addChild(_frame);
	}

	protected function onEnterFrame(event:Event = null):void
	{
		if(_plaing)
		{
			_currentFrame = _currentFrame < _totalFrames ? _currentFrame+1 : 1;

			showFrame(_currentFrame);
		}
	}

	/**
	 *
	 * @param clip анимация для рендеринг
	 * @param keyFrameMarkerName
	 *
	 */
	public function set source(clip:MovieClip):void
	{
		_keyFrames = null;
		_cachingComplete = isAllCached(cache) && clip;
		_clip = clip;
		_totalFrames = 1;
		_totalFrames = clip ? clip.totalFrames : 0;
		frameScripts = {};

		if(autoPlay) addEventListener(Event.ENTER_FRAME, onAutoPlayEnterFrame);
	}

	protected function isAllCached(arr:Array):Boolean
	{
		if(!arr) return false;
		for(var i:int = 1; i<=arr.length; i++)
			if(!arr[i]) return false;
		return true;
	}

	public function get source():MovieClip
	{
		return _clip;
	}

	protected function onAutoPlayEnterFrame(event:Event):void
	{
		removeEventListener(Event.ENTER_FRAME, onAutoPlayEnterFrame);
		if(autoPlay)
		{
			play();
		}
	}

	protected var dict:Dictionary = new Dictionary(true);
	protected function drawFrame (frame:int):void
	{
		if(_drawFrame == frame)
			return;

		_drawFrame = frame;
		var bd:Object = _cache[frame];

		if(!bd)
		{
			if(!_clip)
				return;

//			_clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameReady);
			_clip.gotoAndStop(frame);

			var prevbd:Object = _cache[frame-1];
			var needshot:Boolean = true;

			var keyFrameMarker:DisplayObject;
			if(keyFrameMarkerName)
			{
				if(!_keyFrames)
				{
					_keyFrames = parseKeyFrames(_clip);
					_clip.gotoAndStop(frame);
				}

				keyFrameMarker = _clip.getChildByName(keyFrameMarkerName);
				//удаляем клип, чтобы не мешал делать скриншот
				if(keyFrameMarker && keyFrameMarker.parent)
					_clip.removeChild(keyFrameMarker);

//				if(!keyFrameMarker)
				if(!_keyFrames[frame])
				{
					if(prevbd)
					{
						bd = _cache[frame] = prevbd;
						needshot = false;
					}
				}
			}

			if(needshot)
			{
				bd = VectorCacher.makeSnapshot(_clip, null, 0x00FFFFFF, drawColorTransform);
				_bitmapCounter++;
				_cache[frame] = bd;
			}
		}

		if(bd)
			drawBd(bd);

		if(!_cachingComplete && _bitmapCounter > 0 && _currentFrame == _totalFrames)
		{
			_cachingComplete = true;
			if(hasEventListener(CACHE_COMPLETE))
				dispatchEvent(new Event(CACHE_COMPLETE));

			var name:String = getQualifiedClassName(_clip);
			if(debugLog)
				Logger.debug(this, "caching compelte, key_frames cached = ", _bitmapCounter, ", total_frames = ", _totalFrames, name, debugStr);
			//удаляем ссылку на исходник, чтобы он мог удалиться сборщиком мусора, если надо. Кешеру он больше не нужен
//			_clip = null;
		}
	}

	protected function parseKeyFrames(clip:MovieClip):Object
	{
		var t:int = getTimer();
		var map:Object = {};
		for(var i:int = 1; i<=clip.totalFrames; i++)
		{
			clip.gotoAndStop(i);
			map[i] = _clip.getChildByName(keyFrameMarkerName) != null;
		}
		Logger.debug(this, "parseKeyFrames, time = " + (getTimer() - t) + " ms");

		return map;
	}

	protected function drawBd(bd:Object):void
	{
		_frame.bitmapData = bd.bd;
		_frame.x = bd.x;
		_frame.y = bd.y;
	}

	protected function showFrame(frame:int):void
	{
		drawFrame(frame);

		if(currentFrame == totalFrames)
		{
			if(autoStop)
				stop();

			if(hasEventListener(ANIM_COMPLETE))
				dispatchEvent(new Event(ANIM_COMPLETE));
		}
		if(frameScripts[currentFrame] is Function)
			frameScripts[currentFrame]();
	}

	/*
	 *
	 	MovieClip methods
	 */

	override public function play():void
	{
		_plaing = true;
		showFrame(_currentFrame);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	override public function gotoAndPlay(frame:Object, scene:String = null):void
	{
		_plaing = true;
		_currentFrame = int(frame);
		showFrame(_currentFrame);

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	override public function stop():void
	{
		_plaing = false;
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	override public function gotoAndStop(frame:Object, scene:String = null):void
	{
		_plaing = false;

		_currentFrame = int(frame);
		showFrame(_currentFrame);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	override public function get currentFrame():int
	{
		return _currentFrame;
	}

	override public function get totalFrames():int
	{
		return _totalFrames;
	}

	protected var _scaleX:Number = 1;
	override public function set scaleX(value:Number):void
	{
		_scaleX = value;
		super.scaleX = 1;
	}
	override public function get scaleX():Number{return _scaleX}

	protected var _scaleY:Number = 1;
	override public function set scaleY(value:Number):void
	{
		_scaleY = value;
		super.scaleY = 1;
	}
	override public function get scaleY():Number{return _scaleY}

	override public function get currentLabels():Array{ return source ? source.currentLabels : null}

	protected var frameScripts:Object = {};
	override public function addFrameScript(...parameters):void
	{
		frameScripts[parameters[0]] = parameters[1];
	}
}
}