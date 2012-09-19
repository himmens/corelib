package lib.core.util
{
import flash.text.Font;
	

public class FontUtil
{
	public static function hasEmbed (fontName:String, bold:Boolean):Boolean
	{
		var fonts:Array = Font.enumerateFonts();
		for each(var font:Font in fonts)
			if(font.fontName.toLowerCase() == fontName.toLowerCase())
			{
				if(bold)
				{
					if(font.fontStyle == "bold")
					{
						return true;
					}
				}else
				{
					return true;
				}
			}
		
		return false;
	}
	
	/*public static function hasSystem (fontName:String):Boolean
	{
		var fonts:Array = Font.enumerateFonts();
		for each(var font:Font in fonts)
			if(font.fontName == fontName)
				return true;
		
		return false;
	}*/
	
}

}