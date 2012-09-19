package lib.core.viewing
{

import flash.geom.Point;

/**
 * Параметры инизиализации модуля
 */
public class ViewParams
{
	public var data:Object;
	
	public var position:Point;
	/**
	 * 
	 * @param section раздел экрана
	 * @param data обьект данных, передается экрану
	 * 
	 */
	public function ViewParams(data:Object = null, position:Point = null)
	{
		this.data = data;
		this.position = position;
	}
	
	//для логирования
	public function toObject():Object
	{
		return {data:data, position:position}
	}
}
}