package lib.core.service.protocol
{

public interface IProtocol
{
	function IProtocol();

	/**
	 * Считать пакет
	 * Считывает пакет данных от транспорта. Данные можно получить по геттеру readData
	 * @param pack пакет данных (например ByteArray от Socket или URLLoader)
	 *
	 * @return cчитанные данные, @see com.kamagames.core.service.protocol.ProtocolData
	 *
	 */
	function readObject(data:Object):ProtocolData;

	/**
	 * Формирует запрос на сервер (например ByteArray или XML)
	 * @param data данные для отправки
	 * @return объект для отправки через транспорт
	 */
	function writeObject(data:Object):Object;

}
}