package lib.core.ui.layout
{
/**
 * Страндартные настройки отступов и выравнивания, необходимые для Layout
 */
public class LayoutSettings
{
	public var hPadding:Number;
	public var vPadding:Number;
	public var hSpacing:Number;
	public var vSpacing:Number;
	public var align:String;
	public var valign:String;
	
	public function LayoutSettings (hPadding:Number=0,
									vPadding:Number=0,
									hSpacing:Number=0,
									vSpacing:Number=0,
									align:String=null,
									valign:String=null)
	{
		this.hPadding = hPadding;
		this.vPadding = vPadding;
		this.hSpacing = hSpacing;
		this.vSpacing = vSpacing;
		this.align = align==null ? Align.LEFT : align;
		this.valign = valign==null ? Valign.TOP : valign;
	}
}

}