package lib.core.util.log
{

import flash.text.TextField;

public class TextFieldTarget extends AbstractLoggerTarget implements ILoggerTarget
{
	public var tf:Object;
	
    public var autoScroll:Boolean = true;
	
	public var errorColor:String = "#FF0000";
	public var warningColor:String = "#FF9900";

	public function TextFieldTarget(tf:Object = null)
	{
		this.tf  = tf;
	}

	override public function internalLog(message:String, level:int):void
	{
		if(active && tf)
		{
			if("htmlText" in tf)
			{
				var html:String	= tf.htmlText || "" ;
				
				message = message.split("<").join("&lt;");
				message = message.split(">").join("&gt;");
				
				if(level == Logger.ERRORS)
					html	+= "<font color='"+errorColor+"'>"+message+"</font>";
				else if(level == Logger.WARNINGS)
					html	+= "<font color='"+warningColor+"'>"+message+"</font>";
				else
					html	+= message;
					
				//html+= "<br/>" ;
				
				tf.htmlText     = html ;
				
			}else
			{
	            var txt:String	= tf.text || "" ;
	            txt	+= message + "\r" ;
	            tf.text     = txt ;
			}	
			
			
            if ( autoScroll && ("scrollV" in tf))
            {
                tf.scrollV  = tf.maxScrollV ;
            }
  		}
	}
	
}
}