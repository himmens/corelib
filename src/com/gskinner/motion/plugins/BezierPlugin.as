package com.gskinner.motion.plugins
{
	import com.gskinner.motion.GTween;
	
	import flash.geom.Point;
	
	public class BezierPlugin implements IGTweenPlugin
	{
		/** Specifies whether this plugin is enabled for all tweens by default. **/
		public static var enabled:Boolean=true;
		
		/** @private **/
		protected static var instance:BezierPlugin;
		/** @private **/
		protected static var tweenProperties:Array = ["bezierParam"];
		
		/**
		 * Installs this plugin for use with all GTween instances.
		 **/
		public static function install():void {
			if (instance) { return; }
			instance = new BezierPlugin();
			GTween.installPlugin(instance,tweenProperties);
		}
		
		/** @private **/
		public function init(tween:GTween, name:String, value:Number):Number {
			if (!((tween.pluginData.BezierEnabled == null && enabled) || tween.pluginData.BezierEnabled)) { return value; }
			
			tween.pluginData.startPoint = new Point(tween.target.x, tween.target.y);
			
			return 0;
		}
		
		/** @private **/
		public function tween(tween:GTween, name:String, value:Number, initValue:Number, rangeValue:Number, ratio:Number, end:Boolean):Number {
			// don't run if we're not enabled:
			if (!((tween.pluginData.BezierEnabled == null && enabled) || tween.pluginData.BezierEnabled)) { return value; }
			
			var negativeValue:Number = 1-value;
			var startPoint:Point = tween.pluginData.startPoint;
			var anchorPoint:Point = tween.pluginData.anchorPoint;
			var endPoint:Point = tween.pluginData.endPoint;
			
			if (startPoint && anchorPoint && endPoint)
			{
				tween.target.x = negativeValue*negativeValue*startPoint.x + 2*value*negativeValue*anchorPoint.x + value*value*endPoint.x;
				tween.target.y = negativeValue*negativeValue*startPoint.y + 2*value*negativeValue*anchorPoint.y + value*value*endPoint.y;
			}
			
			// tell GTween not to use the default assignment behaviour:
			return NaN;
		}
	}
}