package lib.core.data
{
import flash.events.Event;

/*
 * 
[Event(name="remove", type="com.kamagames.core.model.ItemSetEvent")]
[Event(name="add", type="com.kamagames.core.model.ItemSetEvent")]
[Event(name="update", type="com.kamagames.core.model.ItemSetEvent")]


*/
/**
 * events
 */
public class ItemSetEvent extends Event
{
	/**
	 * элемент, который добавили/удалили/изменили
	 */
	public var item:IItemVO;

	/**
	 * индекс элемента
	 */
	public var index:int;
	/**
	 * старый индекс элемента (для события update, если при апдейте изменился индекс)
	 */
	public var oldIndex:int;
	
	/**
	 * добавление элемента
	 */
	public static const ADD:String = "add";
	/**
	 * удаление элемента
	 */
	public static const REMOVE:String = "remove";
	
	/**
	 * обновление элемента:
	 * одно из двух или оба сразу:
	 *  - изменение индекса
	 *  - изменение элемента
	 */
	public static const UPDATE:String = "update";
	
	/**
	 * Коллекция полностью обновлена
	 */
	public static const REFRESH:String = "refresh";

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	/**
	 * Constructor.
	 * 
	 * @param type The type of Set event.
	 * @param bubbles Indicates whether an event will be a bubbling event.
	 * @param cancelable Indicates whether the behavior associated with the event can be prevented.
	 */
	public function ItemSetEvent (type:String, 
									 item:IItemVO = null, index:int = -1, oldIndex:int = -1,
									bubbles:Boolean = false, cancelable:Boolean = false)
	{
		super(type, bubbles, cancelable);
		this.item = item;
		this.index = index;
		this.oldIndex = oldIndex;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods: Event
	//
	//--------------------------------------------------------------------------

	/**
	 *  @private
	 */
	override public function clone():Event
	{
		var event:ItemSetEvent = new ItemSetEvent(type, item, index, oldIndex, bubbles, cancelable);
		return event;
	}
}
}