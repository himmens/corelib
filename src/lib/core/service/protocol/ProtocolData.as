package lib.core.service.protocol
{
/**
 * Объект данных парсинга протоколом
 */
public class ProtocolData
{
	/**
	 * массив считанных объектов
	 */
	public var readData:Array = [];

	/**
	 * внутренние данные низкого уровня для передачи от протокола к
	 * транспорту (например флаг закрытия соединения, если он передается через протокол)
	 */
	public var protocolData:Object;

	/**
	 * ошибка при считывании
	 */
	public var readError:int = ProtocolError.NO_ERROR;

	/**
	 * флаг, если true - пакет считан полностью, если false остались непрочитанные данные, либо данных не хватило на считывание пакета.
	 * Ориентируясь на этот флаг можно дозапрашивать данные в транспорте немедленно, если пакет считан не полностью.
	 */
	public var readCompleted:Boolean = true;

	public function ProtocolData()
	{
	}
}
}