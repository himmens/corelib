package lib.core.ui
{
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.system.ApplicationDomain;

import lib.core.command.QueueCommand;
import lib.core.command.loaders.LoadRslCommand;
import lib.core.command.loaders.LoaderCommand;
import lib.core.command.loaders.LoaderQueueCommand;
import lib.core.ui.skins.SkinsManager;
import lib.core.util.FunctionUtil;
import lib.core.util.log.Logger;

/**
 * загрузчик с возможностью загрузки runtime shared library swf
 */
public class RslPreloader extends Preloader
{
	protected var skinsManager:SkinsManager;

	protected var rslLibs:Array = [];
	protected var rslLoader:LoaderQueueCommand;

	protected var rslLoaded:Boolean;

	protected var _rslError:int = 0;
	public function get rslError():Boolean{return _rslError > 0}

	public function RslPreloader(mainAppClassName:String)
	{
		super(mainAppClassName);
	}

	override protected function init():void
	{
		super.init();

		skinsManager = new SkinsManager();
	}

	override protected function onMainLoaded():void
	{
		super.onMainLoaded();

		var domain:ApplicationDomain = ApplicationDomain.currentDomain;

		loadRsl();
	}

	protected function loadRsl():void
	{
		var params:Object = getParams(this) || {};

		if("rsl" in params)
		{
			rslLibs = String(params["rsl"]).split(",");
		}

		if(rslLibs.length > 0)
		{
			rslLoader = new LoaderQueueCommand();
			for each(var url:String in rslLibs)
			{
				rslLoader.addLoader(new LoadRslCommand(url));
			}

			rslLoader.addEventListener(ProgressEvent.PROGRESS, onRslProgress);
			rslLoader.addEventListener(Event.COMPLETE, onRslComplete);
			rslLoader.addEventListener(QueueCommand.COMMAND_COMPLETE, onRslCommand);
			rslLoader.execute();
		}else
		{
			onRslComplete();
		}
	}

	protected function onRslCommand(event:Event):void
	{
		var cmd:LoaderCommand = rslLoader.completedCommand as LoaderCommand;
		if(cmd && !cmd.success)
			_rslError = cmd.errorCode;

		//если была ошибка при загрузке необходимой либы прерываемся
		if(rslError && isLibRequired(cmd.url))
		{
			Logger.error(this, "RSL lib load error: url = ", cmd.url);
			rslLoader.terminate();
			rslLoaded = true;
			checkAllLoaded();
		}
	}

	protected function isLibRequired(url:String):Boolean
	{
		return true;
	}

	private function onRslProgress(event:Event):void
	{
		setRslProgress(rslLoader.progress);
	}

	protected function setRslProgress(value:Number):void
	{

	}

	private function onRslComplete(event:Event = null):void
	{
		setRslProgress(1);

		rslLoaded = true;
		checkAllLoaded();
	}

	override protected function checkAllLoaded():void
	{
		if(mainLoaded && rslLoaded)
		{
			onAllLoaded();
		}
	}
}
}