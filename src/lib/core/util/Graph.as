package lib.core.util
{
	
import flash.display.Graphics;
import flash.geom.Point;
	

public class Graph
{
	
	/**
	 * Прямоугольник с закругленными углами с бордером, бордер рисуется заливкой для красивого скейлинга
	 * @param graphics
	 * @param x
	 * @param y
	 * @param w
	 * @param h
	 * @param radius
	 * @param lineColor
	 * @param fillColor
	 * @param lineThickness
	 * @param lineAlpha
	 * @param fillAlpha
	 * 
	 */
	public static function drawRoundRectAsFill (graphics:Graphics, 
												x:Number, y:Number, 
												w:Number, h:Number, 
												radius:Number,
												lineColor:uint=0x000000, fillColor:uint=0xffffff,
												lineThickness:Number=1,
												lineAlpha:Number=1, fillAlpha:Number=1):void
	{
		graphics.lineStyle(0,0,0);
		graphics.beginFill(lineColor, lineAlpha);
		graphics.drawRoundRect(x, y, w, h, 2*radius, 2*radius);
		graphics.drawRoundRect(x+lineThickness, y+lineThickness, w-2*lineThickness, h-2*lineThickness, 2*radius-2*lineThickness, 2*radius-2*lineThickness);
		graphics.endFill();
		
		graphics.beginFill(fillColor,fillAlpha);
		graphics.drawRoundRect(x+lineThickness, y+lineThickness, w-2*lineThickness, h-2*lineThickness, 2*radius-2*lineThickness, 2*radius-2*lineThickness);
		graphics.endFill();
	}											
	
	/**
	 * Прямоугольник с бордером, бордер рисуется заливкой для красивого скейлинга 
	 * @param graphics
	 * @param x
	 * @param y
	 * @param w
	 * @param h
	 * @param lineColor
	 * @param fillColor
	 * @param lineThickness
	 * @param lineAlpha
	 * @param fillAlpha
	 * 
	 */
	public static function drawRectAsFill (graphics:Graphics, 
												x:Number, y:Number, 
												w:Number, h:Number, 
												lineColor:uint, fillColor:uint=0xffffff,
												lineThickness:Number=1,
												lineAlpha:Number=1, fillAlpha:Number=1):void
	{
		graphics.lineStyle(0,0,0);
		graphics.beginFill(lineColor, lineAlpha);
		graphics.drawRect(x, y, w, h);
		graphics.drawRect(x+lineThickness, y+lineThickness, w-2*lineThickness, h-2*lineThickness);
		graphics.endFill();
		
		graphics.beginFill(fillColor,fillAlpha);
		graphics.drawRect(x+lineThickness, y+lineThickness, w-2*lineThickness, h-2*lineThickness);
		graphics.endFill();
	}											
	
	/**
	 * Простой прямоугольник
	 * @param graphics
	 * @param x
	 * @param y
	 * @param w
	 * @param h
	 * @param color
	 * @param alpha
	 * @param corner
	 * 
	 */
	public static function drawFillRec(graphics:Graphics, 
												x:Number, y:Number, 
												w:Number, h:Number, 
												color:Number = 0x000000, alpha:Number=1, corner:int = 0):void
	{
		graphics.lineStyle(0,0,0);
		graphics.beginFill(color, alpha);
		corner > 0 ? graphics.drawRoundRect(x, y, w, h, 2*corner, 2*corner) : graphics.drawRect(x, y, w, h);
		graphics.endFill();
	}	
										
	/**
	 * Линия
	 * @param graphics
	 * @param x1
	 * @param y1
	 * @param x2
	 * @param y2
	 * @param thickness
	 * @param color
	 * @param alpha
	 * 
	 */
	public static function drawLine(graphics:Graphics, 
												x1:Number, y1:Number, 
												x2:Number, y2:Number, 
												thickness:Number = 0,
												color:Number = 0x000000, alpha:Number=1):void
	{
		graphics.lineStyle(thickness,color,alpha);
		graphics.moveTo(x1, y1);
		graphics.lineTo(x2, y2);
	}										
	
	/**
	 * Кривая
	 * @param graphics
	 * @param x1
	 * @param y1
	 * @param x2
	 * @param y2
	 * @param controlX
	 * @param controlY
	 * @param thickness
	 * @param color
	 * @param alpha
	 * 
	 */
	public static function drawCurve(graphics:Graphics, 
												x1:Number, y1:Number, 
												x2:Number, y2:Number, 
												controlX:Number, controlY:Number, 
												thickness:Number = 0,
												color:Number = 0x000000, alpha:Number=1):void
	{
		graphics.lineStyle(thickness,color,alpha);
		graphics.moveTo(x1, y1);
		graphics.curveTo(controlX, controlY, x2, y2);
	}									
	
	public static function drawArc(graphics:Graphics, 
								   centerX:Number, 
								   centerY:Number,
								   radius:uint, 
								   fromAngle:Number,
								   toAngle:Number,
								   fillColor:uint = 0x000000,
								   fillAlpha:Number = 1):void
	{
		var segAngle:Number;
		var angle:Number;
		var angleMid:Number;
		var numOfSegs:Number;
		var aX:Number;
		var aY:Number;
		var bx:Number;
		var by:Number;
		var cx:Number;
		var cy:Number;
		
		aX = centerX + Math.cos((fromAngle/ 180) * Math.PI) * radius;
		aY = centerY + Math.sin((fromAngle/ 180) * Math.PI) * radius;
		graphics.moveTo(aX, aY);
		graphics.beginFill(fillColor, fillAlpha);
		
		if (Math.abs(toAngle - fromAngle) > 360) 
		{
			toAngle = fromAngle + 360;
		}
		
		numOfSegs = Math.ceil(Math.abs(toAngle - fromAngle) / 45);
		segAngle = (toAngle - fromAngle) / numOfSegs;
		segAngle = (segAngle / 180) * Math.PI;
		angle = (fromAngle / 180) * Math.PI;
		
		for(var i:int=0; i<numOfSegs; i++) 
		{
			angle += segAngle;
			
			angleMid = angle - (segAngle / 2);
			
			bx = centerX + Math.cos(angle) * radius;
			by = centerY + Math.sin(angle) * radius;
			
			cx = centerX + Math.cos(angleMid) * (radius / Math.cos(segAngle / 2));
			cy = centerY + Math.sin(angleMid) * (radius / Math.cos(segAngle / 2));
			
			graphics.curveTo(cx, cy, bx, by);
		}
		
		graphics.lineTo(centerX, centerY);
		graphics.lineTo(aX, aY);
	}
}

}