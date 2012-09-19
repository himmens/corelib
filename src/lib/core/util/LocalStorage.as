package lib.core.util
{
import flash.events.NetStatusEvent;
import flash.net.SharedObject;
import flash.net.SharedObjectFlushStatus;

import lib.core.util.log.Logger;
import lib.core.util.log.Logger;

/**
 * локальное хранилище объектов на базе SharedObject
 */
public class LocalStorage
{
	private var soName:String = "local_so";

	/**
	 * можно указать id юзера, которое будет добавляться ко всем именам переменных
	 */
	public var userId:String = "";

	public function LocalStorage(name:String)
	{
		soName = name;
	}

	public function writeObject(name:String, value:Object):void
	{
		if(userId)
			name = userId + name;

		var so:SharedObject = SharedObject.getLocal(soName);
		so.data[name] = value;

		var flushStatus:String = null;
		try
		{
			flushStatus = so.flush(1000);
		}catch (err:Error) {
			Logger.debug(this, err.message, err.getStackTrace());
		}

		if (flushStatus != null)
		{
			Logger.debug(this, "::writeObject flushStatus: ", flushStatus);
			if(flushStatus == SharedObjectFlushStatus.PENDING)
			{
				so.addEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
			}
		}
	}

	private function onFlushStatus(event:NetStatusEvent):void
	{
		Logger.debug(this, "onFlushStatus: ",event.info);
	}

	public function readObject(name:Object):Object
	{
		if(userId)
			name = userId + name;

		var so:SharedObject = SharedObject.getLocal(soName);
		var obj:Object;
		if(so && so.size > 0)
		{
			obj = so.data[name];
		}

		return obj;
	}

	public function clear():void
	{
		var so:SharedObject = SharedObject.getLocal(soName);
		if(so)
		{
			so.clear();
		}
	}
}
}