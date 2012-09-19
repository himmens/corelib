package lib.core.data
{
import lib.core.util.ObjectUtil;

import flash.events.EventDispatcher;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

/**
 * Базовый VO для всех обектов данных в игре
 */
public class ItemVO extends EventDispatcher implements IItemVO
{
	protected var _id:String;

	public var initObj:Object;

	public function ItemVO(initObj:Object=null)
	{
		this.initObj = initObj || {};
		if(initObj)
			parse(initObj);
	}

	public function get id():String
	{
		return _id;
	}

	public function set id(value:String):void
	{
		_id = value;
	}

	public function parse(obj:Object):void
	{
		if (!obj)
			return;

		initObj = obj;

		for (var prop:String in obj)
		{
			if(this.hasOwnProperty(prop))
			{
				this[prop] = obj[prop];
			}

//			if(obj != initObj)
//				initObj[prop] = obj[prop];
		}
	}

	public function clone():ItemVO
	{
		var ThisClass:Class = getDefinitionByName(getQualifiedClassName(this)) as Class;
		return new ThisClass(ObjectUtil.copyProps({}, initObj)) as ItemVO;
	}

	public function toObject():Object
	{
		return initObj;
		
//		var obj:Object = {};
//		var propNames:Array = ObjectUtil.getPropertyList(this);
//		for each(var name:String in propNames)
//			obj[name] = this[name]
//				
//		return obj;
	}
	
	override public function toString():String
	{
		var arr:Array = [];
		for (var prop:String in initObj)
		{
			if(this.hasOwnProperty(prop))
			{
				arr.push(prop+":"+this[prop]);
			}
		}
		return super.toString() + "(" + arr.join(", ") + ")";  
	}
}
}