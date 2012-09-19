package lib.core.ui.controls
{
import lib.core.ui.layout.ILayout;

import flash.display.DisplayObject;
import flash.utils.Dictionary;

public class SimpleListCacher extends SimpleList
{
	private static const rendererCache:Dictionary = new Dictionary(false);
	
	public function SimpleListCacher(layout:ILayout=null)
	{
		super(layout);
	}
	
	override protected function createItemRenderer(data:Object):DisplayObject
	{
		if(!itemRenderer)
			return null;
		
		var cached:Array = rendererCache[itemRenderer];
		if(cached && cached.length > 0)
			return cached.pop();
		
		return super.createItemRenderer(data);
	}
	
	override public function removeAt(index:int):DisplayObject
	{
		var renderer:DisplayObject = super.removeAt(index);
		
		var cached:Array = rendererCache[itemRenderer] || [];
		cached.push(renderer);
		//renderer["data"] = null;
		rendererCache[itemRenderer] = cached;
		
		return renderer;
	} 
}
}