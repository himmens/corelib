package lib.core.service.protocol
{
public class ProtocolError
{
	//все хорошо
	public static const NO_ERROR:int = 			0;

	//ошибка при распакомке (unzip)
	public static const UNCOMPRESS_ERROR:int = 	1;

	//ошибка протокола (кривой пакет)
	public static const PROTOCOL_ERROR:int 	= 	2;

	//ошибка подпись не совпала
	public static const SING_ERROR:int 		= 	3;

	//ошибка - неверный номер пакета
	public static const SEQ_NUM_ERROR:int 	= 	4;
}
}