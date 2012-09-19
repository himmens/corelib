package lib.core.command.loaders
{
import lib.core.util.log.Logger;

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.text.Font;
import flash.utils.ByteArray;


/**
 * Команда загрузки swf со шрифтами.
 * Список шрифтов который содержится в библиотеке должен лежать в массиве fonts
 * в главном классе (documentClass в Flash IDE) библиотеке:
 * 	Например для главного класса FontsLib.as при вшивании двух шрифтов через дерективу Embed:
 * 	public const fonts:Array =
 * 	[
 * 		"FontsLib_Arial",
 * 		"FontsLib_ArialBold",
 * 	];
 *
 * Пример вшивания шрифтов (таблица юникод диапазонов Flex SDK\frameworks\flash-unicode-table.xml):
 * Юникод даипазон: Punctuation + Basic Latin + Cyrillic
 *
 * 	[Embed(systemFont="Arial",
 * 		fontName="Arial",
 * 		mimeType="application/x-font",
 *		advancedAntiAliasing="true",
 *		unicodeRange="U+0020-U+002F,U+003A-U+0040,U+005B-U+0060,U+007B-U+007E,U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E,U+0400-U+04CE,U+2000-U+206F,U+20A0-U+20CF,U+2100-U+2183"
 *	)]
 *	public static const Arial:Class;
 *
 *	[Embed(systemFont="Arial",
 *		fontName="Arial",
 *		mimeType="application/x-font",
 *		advancedAntiAliasing="true",
 *		fontWeight="bold",
 *		unicodeRange="U+0020-U+002F,U+003A-U+0040,U+005B-U+0060,U+007B-U+007E,U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E,U+0400-U+04CE,U+2000-U+206F,U+20A0-U+20CF,U+2100-U+2183"
 *	)]
 *
 *
 */
public class LoadFontsCommand extends LoaderCommand
{
	private var source:Object;

//	private var _loader:Loader;
	private var _loader:URLLoader;
//	private var _loader:FontLoader;
//	public function get loader():Loader
//	{
//		return _loader;
//	}
	/**
	 *
	 * @param source путь к swf файлу с шрифтами
	 *
	 */
	public function LoadFontsCommand(source:Object)
	{
		this.source = source;
	}

	override protected function execInternal ():void
	{
		//грузим через URLLoader как бинарный массив, т.к. иначе возникают проблемы при регистрации шрифта из-за багов
		//в с кроссдоменной полотикой и шрифтами:
		//error.message = "Error #1508: Указано недопустимое значение для аргумента font."

		if(source is ByteArray)
		{
			processBytes(source as ByteArray);
		}else
		{
			_loader = new URLLoader();
			_loader.dataFormat = URLLoaderDataFormat.BINARY;
			//_loader = SkinsManager.instance.loadSkin(source);
			//_loader = new FontLoader();
			//_loader.load(new URLRequest(source), new LoaderContext(true, new ApplicationDomain()));
	
			//loaderDispatcher = _loader.contentLoaderInfo;
			//loaderDispatcher = _loader;
	
			Logger.debug(this, "load fonts: ", source);
	
			handleLoaderDispatcher(_loader);
			_loader.load(new URLRequest(String(source)));
		}
	}

	override protected function onComplete(event:Event):void
	{
		if(event.target is LoaderInfo)
		{
			registerFonts(event.target as LoaderInfo);
			super.onComplete(event);
		}else
		{
			var bytes:ByteArray = URLLoader(event.target).data as ByteArray;
			processBytes(bytes);
		}
	}

	protected function processBytes(bytes:ByteArray):void
	{
		var loader:Loader = new Loader();
		//			loader.loadBytes(bytes, new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain)));
		handleLoaderDispatcher(loader.contentLoaderInfo);
		var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
		
		//fp11 надо выставить этот флаг. чтобы работало в мобильной версии
		if("allowCodeImport" in context) context["allowCodeImport"] = true;
		
		loader.loadBytes(bytes, context);
	}
	
	protected function registerFonts(loader:LoaderInfo):void
	{
		var domain:ApplicationDomain = loader.applicationDomain;
		var content:Object = loader.content;

		var fontsList:Array = content && content.hasOwnProperty("fonts") ? content.fonts as Array : null;

		for each(var className:String in fontsList)
		{
			try
			{
				var fontClass:Class = domain.getDefinition(className) as Class;
				Font.registerFont(fontClass);

				var font:Font = Font(new fontClass());
				Logger.debug(this, "registerFont, ", font.fontName, font.fontStyle, font.fontType);
			}catch(error:Error)
			{
				Logger.error("LoadFontsCommand::onFontsLoaded, error: ",error.message);
			}
		}
	}
}
}