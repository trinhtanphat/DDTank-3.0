package vip
{
   import com.pickgliss.events.UIModuleEvent;
   import com.pickgliss.loader.UIModuleLoader;
   import com.pickgliss.ui.ComponentFactory;
   import ddt.data.UIModuleTypes;
   import ddt.manager.PlayerManager;
   import ddt.manager.SocketManager;
   import ddt.view.UIModuleSmallLoading;
   import flash.events.Event;
   import vip.data.VipModelInfo;
   import vip.view.VIPHelpFrame;
   import vip.view.VipFrame;
   
   public class VipController
   {
      
      private static var _instance:VipController;
      
      private static var useFirst:Boolean = true;
      
      private static var loadComplete:Boolean = false;
      
      public var info:VipModelInfo;
      
      private var _vipFrame:VipFrame;
      
      private var _isShow:Boolean;
      
      private var _helpframe:VIPHelpFrame;
      
      public function VipController()
      {
         super();
      }
      
      public static function get instance() : VipController
      {
         if(!_instance)
         {
            _instance = new VipController();
         }
         return _instance;
      }
      
      public function setup() : void
      {
      }
      
      public function show() : void
      {
         if(loadComplete)
         {
            this._vipFrame = null;
            this._helpframe = null;
            if(PlayerManager.Instance.Self.IsVIP)
            {
               this.showVipFrame();
            }
            else
            {
               this._helpframe = ComponentFactory.Instance.creatComponentByStylename("vip.viphelpFrame");
               this._helpframe.openFun = this.showVipFrame;
               this._helpframe.show();
            }
         }
         else if(useFirst)
         {
            UIModuleSmallLoading.Instance.progress = 0;
            UIModuleSmallLoading.Instance.show();
            UIModuleSmallLoading.Instance.addEventListener(Event.CLOSE,this.__onClose);
            UIModuleLoader.Instance.addEventListener(UIModuleEvent.UI_MODULE_PROGRESS,this.__progressShow);
            UIModuleLoader.Instance.addEventListener(UIModuleEvent.UI_MODULE_COMPLETE,this.__complainShow);
            UIModuleLoader.Instance.addUIModuleImp(UIModuleTypes.VIP_VIEW);
            useFirst = false;
         }
      }
      
      private function showVipFrame() : void
      {
         this._vipFrame = ComponentFactory.Instance.creatComponentByStylename("vip.VipFrame");
         this._vipFrame.show();
      }
      
      private function __complainShow(param1:UIModuleEvent) : void
      {
         if(param1.module == UIModuleTypes.VIP_VIEW)
         {
            UIModuleSmallLoading.Instance.removeEventListener(Event.CLOSE,this.__onClose);
            UIModuleLoader.Instance.removeEventListener(UIModuleEvent.UI_MODULE_PROGRESS,this.__progressShow);
            UIModuleLoader.Instance.removeEventListener(UIModuleEvent.UI_MODULE_COMPLETE,this.__complainShow);
            UIModuleSmallLoading.Instance.hide();
            loadComplete = true;
            this.show();
         }
      }
      
      private function __progressShow(param1:UIModuleEvent) : void
      {
         if(param1.module == UIModuleTypes.VIP_VIEW)
         {
            UIModuleSmallLoading.Instance.progress = param1.loader.progress * 100;
         }
      }
      
      private function __onClose(param1:Event) : void
      {
         UIModuleSmallLoading.Instance.hide();
         UIModuleSmallLoading.Instance.removeEventListener(Event.CLOSE,this.__onClose);
         UIModuleLoader.Instance.removeEventListener(UIModuleEvent.UI_MODULE_PROGRESS,this.__progressShow);
         UIModuleLoader.Instance.removeEventListener(UIModuleEvent.UI_MODULE_COMPLETE,this.__complainShow);
      }
      
      public function sendOpenVip(param1:String, param2:int, param3:Boolean = false, param4:int = 0) : void
      {
         SocketManager.Instance.out.sendOpenVip(param1,param2,param3,param4);
      }
      
      public function hide() : void
      {
         if(this._vipFrame != null)
         {
            this._vipFrame.dispose();
         }
         this._vipFrame = null;
      }
   }
}
