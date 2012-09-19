package lib.core
{

/**
 * коды ошибок/ответов внутренних игровых команд
 */
public class AppErrorCodes
{
	/**
	 * "Ok"
	 */
	public static const NO_ERROR:int 					= 0;

	/**
	 *  Превышено время ожидания ответа
	 */
	public static const TIMEOUT_EXPIRED:int 			= 501;

	/**
	 *  Ошибка загруки графики
	 */
	public static const ASSETTS_LOAD_ERROR:int 			= 502;

	/**
	 *  неверные настройки доступа API
	 */
	public static const BAD_API_SETTINGS:int 			= 503;

	/**
	 * приложение не добавлено на стену
	 */
	public static const NOT_APP_USER:int 				= 504;

	/**
	 *  ошибка загрузки настроек/конфига
	 */
	public static const SETTINGS_LOAD_ERROR:int 		= 505;

	/**
	 *  ошибка загрузки данных с вконтакта (любой соц сети)
	 */
	public static const SOCIAL_DATA_LOAD_ERROR:int 		= 506;

	/**
	 *  ошибка коннекта к серверу
	 */
	public static const SERVICE_CONNECT_ERROR:int 		= 507;

	/**
	 *  общая ошибка сети при http запросе (без уточнения тетипа ошибки)
	 */
	public static const HTTP_ERROR:int 					= 509;

	/**
	 *  общая ошибка при разборе данных (без уточнения типа ошибка)
	 */
	public static const PARSE_ERROR:int 				= 510;

	/**
	 *  игра закрыта на техническую поддержку
	 */
	public static const TECH_MAINTENANCE:int 			= 511;

	/**
	 *  невалидные параметры, либо нет необходимых параметров
	 */
	public static const INVALIDE_ARGUMENT:int 			= 512;

	/**
	 *  нет данных для чего-либо (для рекламы)
	 */
	public static const NO_DATA:int						= 513;
	
	/**
	 *  игрок забанен
	 */
	public static const BANNED:int						= 514;
	
	/**
	 *  неверный пароль
	 */
	public static const INVALIDE_PSW:int				= 515;

}
}