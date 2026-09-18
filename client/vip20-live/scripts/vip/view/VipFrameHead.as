package vip.view
{
   import bagAndInfo.info.LevelProgress;
   import com.pickgliss.ui.ComponentFactory;
   import com.pickgliss.ui.controls.BaseButton;
   import com.pickgliss.ui.core.Disposeable;
   import com.pickgliss.ui.image.Scale9CornerImage;
   import com.pickgliss.ui.text.FilterFrameText;
   import com.pickgliss.ui.text.GradientText;
   import com.pickgliss.utils.ObjectUtils;
   import ddt.events.PlayerPropertyEvent;
   import ddt.manager.LanguageMgr;
   import ddt.manager.PlayerManager;
   import ddt.manager.SoundManager;
   import ddt.view.PlayerPortraitView;
   import ddt.view.common.VipLevelIcon;
   import ddt.view.tips.OneLineTip;
   import flash.display.Bitmap;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   
   public class VipFrameHead extends Sprite implements Disposeable
   {
      
      private static var eachLevelEXP:Array = [0,200,400,800,2000,4000,8000,20000,40000,80000,200000,400000,800000,1200000,1800000,2600000,3600000,4800000,6200000,7800000];
      
      private var _topBG:Scale9CornerImage;
      
      private var _selfName:FilterFrameText;
      
      private var _vipName:GradientText;
      
      private var _vipIcon:VipLevelIcon;
      
      private var _ClockImg:Bitmap;
      
      private var _dueTime:FilterFrameText;
      
      private var _vipLevelProgress:LevelProgress;
      
      private var _vipHelpBtn:BaseButton;
      
      private var _selfLevel:FilterFrameText;
      
      private var _nextLevel:FilterFrameText;
      
      private var _dueDataWord:Bitmap;
      
      private var _dueData:FilterFrameText;
      
      private var _DueTipSprite:Sprite;
      
      private var _DueTip:OneLineTip;
      
      private var _portrait:PlayerPortraitView;
      
      private var _helpFrame:VIPHelpFrame;
      
      public function VipFrameHead()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._topBG = ComponentFactory.Instance.creatComponentByStylename("VIPFrame.topBG");
         this._selfName = ComponentFactory.Instance.creat("VipStatusView.name");
         this._vipName = PlayerManager.Instance.Self.getVipNameTxt(263);
         this._vipIcon = ComponentFactory.Instance.creatCustomObject("VipStatusView.vipIcon");
         this._ClockImg = ComponentFactory.Instance.creatBitmap("asset.vip.timeBitmap");
         this._dueTime = ComponentFactory.Instance.creat("VIPFrame.dueTime");
         this._vipLevelProgress = ComponentFactory.Instance.creat("VIPFrame.vipLevelProgress");
         this._vipHelpBtn = ComponentFactory.Instance.creatComponentByStylename("VipStatusView.vipHelp");
         this._selfLevel = ComponentFactory.Instance.creat("VipStatusView.selfLevel");
         this._nextLevel = ComponentFactory.Instance.creat("VipStatusView.nextLevel");
         this._dueDataWord = ComponentFactory.Instance.creatBitmap("asset.vip.dueDate");
         this._dueData = ComponentFactory.Instance.creat("VipStatusView.dueDate");
         this._portrait = ComponentFactory.Instance.creatCustomObject("vip.PortraitView",["right"]);
         this._portrait.info = PlayerManager.Instance.Self;
         addChild(this._topBG);
         addChild(this._portrait);
         addChild(this._selfName);
         addChild(this._vipName);
         addChild(this._vipIcon);
         addChild(this._ClockImg);
         addChild(this._dueTime);
         addChild(this._vipLevelProgress);
         addChild(this._vipHelpBtn);
         addChild(this._selfLevel);
         addChild(this._nextLevel);
         addChild(this._dueDataWord);
         addChild(this._dueData);
         this.addTipSprite();
         this.upView();
         this.addEvent();
         this._vipName.x = this._selfName.x;
         this._vipName.y = this._selfName.y;
      }
      
      private function addTipSprite() : void
      {
         this._DueTipSprite = new Sprite();
         this._DueTipSprite.graphics.beginFill(0,0);
         this._DueTipSprite.graphics.drawRect(0,0,75,35);
         this._DueTipSprite.graphics.endFill();
         var _loc1_:Point = ComponentFactory.Instance.creatCustomObject("Vip.DueTipSpritePos");
         this._DueTipSprite.x = _loc1_.x;
         this._DueTipSprite.y = _loc1_.y;
         addChild(this._DueTipSprite);
         this._DueTip = new OneLineTip();
         addChild(this._DueTip);
         this._DueTip.x = this._ClockImg.x;
         this._DueTip.y = this._ClockImg.y + 25;
         this._DueTip.visible = false;
      }
      
      private function addEvent() : void
      {
         PlayerManager.Instance.Self.addEventListener(PlayerPropertyEvent.PROPERTY_CHANGE,this.__propertyChange);
         this._vipHelpBtn.addEventListener(MouseEvent.CLICK,this.__showHelpFrame);
         this._DueTipSprite.addEventListener(MouseEvent.MOUSE_OVER,this.__showDueTip);
         this._DueTipSprite.addEventListener(MouseEvent.MOUSE_OUT,this.__hideDueTip);
      }
      
      private function removeEvent() : void
      {
         PlayerManager.Instance.Self.removeEventListener(PlayerPropertyEvent.PROPERTY_CHANGE,this.__propertyChange);
         if(Boolean(this._vipHelpBtn))
         {
            this._vipHelpBtn.removeEventListener(MouseEvent.CLICK,this.__showHelpFrame);
         }
         if(Boolean(this._DueTipSprite))
         {
            this._DueTipSprite.removeEventListener(MouseEvent.MOUSE_OVER,this.__showDueTip);
            this._DueTipSprite.removeEventListener(MouseEvent.MOUSE_OUT,this.__hideDueTip);
         }
      }
      
      private function __showDueTip(param1:MouseEvent) : void
      {
         this._DueTip.visible = true;
      }
      
      private function __hideDueTip(param1:MouseEvent) : void
      {
         this._DueTip.visible = false;
      }
      
      private function __showHelpFrame(param1:MouseEvent) : void
      {
         SoundManager.instance.play("008");
         this._helpFrame = ComponentFactory.Instance.creatComponentByStylename("vip.viphelpFrame");
         this._helpFrame.show();
      }
      
      private function __propertyChange(param1:PlayerPropertyEvent) : void
      {
         if(Boolean(param1.changedProperties["isVip"]) || Boolean(param1.changedProperties["VipExpireDay"]))
         {
            this.upView();
         }
      }
      
      private function upView() : void
      {
         var level:int = Math.max(1,Math.min(20,PlayerManager.Instance.Self.VIPLevel));
         var isMax:Boolean = level >= 20;
         if(!isMax)
         {
            this._DueTip.tipData = LanguageMgr.GetTranslation("ddt.vip.dueTime.tip",Math.max(0,PlayerManager.Instance.Self.VIPNextLevelDaysNeeded),level + 1);
         }
         else
         {
            this._DueTip.tipData = LanguageMgr.GetTranslation("ddt.vip.vipIcon.upGradFull");
         }
         if(!PlayerManager.Instance.Self.IsVIP && PlayerManager.Instance.Self.VIPExp <= 0)
         {
            this._DueTip.tipData = LanguageMgr.GetTranslation("ddt.vip.vipFrame.youarenovip");
         }
         this._selfName.text = PlayerManager.Instance.Self.NickName;
         if(PlayerManager.Instance.Self.IsVIP)
         {
            this._vipName.text = this._selfName.text;
            this._vipName.visible = true;
            this._selfName.visible = false;
         }
         else
         {
            this._vipName.visible = false;
            this._selfName.visible = true;
         }
         this._vipIcon.setInfo(PlayerManager.Instance.Self,true,true);
         this._vipIcon.x = this._selfName.x + this._selfName.textWidth + 15;
         this._selfLevel.text = "LV" + level;
         this._nextLevel.text = isMax ? "" : "LV" + (level + 1);
         var expireDate:Date = PlayerManager.Instance.Self.VIPExpireDay as Date;
         this._dueData.text = expireDate == null ? "" : expireDate.fullYear + "-" + (expireDate.month + 1) + "-" + expireDate.date;
         if(!PlayerManager.Instance.Self.IsVIP)
         {
            this._dueData.text = "";
         }
         if(!PlayerManager.Instance.Self.IsVIP && PlayerManager.Instance.Self.VIPExp <= 0)
         {
            this._dueTime.text = 0 + LanguageMgr.GetTranslation("shop.ShopIIShoppingCarItem.day");
         }
         else
         {
            this._dueTime.text = Math.max(0,PlayerManager.Instance.Self.VIPNextLevelDaysNeeded) + LanguageMgr.GetTranslation("shop.ShopIIShoppingCarItem.day");
         }
         var progress:int = 0;
         var required:int = 1;
         if(isMax)
         {
            progress = required = 1;
            this._vipLevelProgress.labelText = "MAX";
         }
         else
         {
            var floorExp:int = eachLevelEXP[level - 1];
            var nextFloor:int = eachLevelEXP[level];
            required = Math.max(1,nextFloor - floorExp);
            progress = Math.max(0,Math.min(required,PlayerManager.Instance.Self.VIPExp - floorExp));
            this._vipLevelProgress.labelText = progress + "/" + required;
         }
         this._vipLevelProgress.setProgress(progress,required);
         this.grayOrLightVIP();
      }
      
      private function grayOrLightVIP() : void
      {
         if(!PlayerManager.Instance.Self.IsVIP)
         {
            this._vipIcon.filters = ComponentFactory.Instance.creatFilters("grayFilter");
            this._vipLevelProgress.filters = ComponentFactory.Instance.creatFilters("grayFilter");
         }
         else
         {
            this._vipIcon.filters = null;
            this._vipLevelProgress.filters = null;
         }
      }
      
      public function dispose() : void
      {
         this.removeEvent();
         if(Boolean(this._topBG))
         {
            ObjectUtils.disposeObject(this._topBG);
         }
         this._topBG = null;
         if(Boolean(this._vipIcon))
         {
            ObjectUtils.disposeObject(this._vipIcon);
         }
         this._vipIcon = null;
         if(Boolean(this._ClockImg))
         {
            ObjectUtils.disposeObject(this._ClockImg);
         }
         this._ClockImg = null;
         if(Boolean(this._dueTime))
         {
            ObjectUtils.disposeObject(this._dueTime);
         }
         this._dueTime = null;
         if(Boolean(this._vipLevelProgress))
         {
            ObjectUtils.disposeObject(this._vipLevelProgress);
         }
         this._vipLevelProgress = null;
         if(Boolean(this._vipHelpBtn))
         {
            ObjectUtils.disposeObject(this._vipHelpBtn);
         }
         this._vipHelpBtn = null;
         if(Boolean(this._selfLevel))
         {
            ObjectUtils.disposeObject(this._selfLevel);
         }
         this._selfLevel = null;
         if(Boolean(this._nextLevel))
         {
            ObjectUtils.disposeObject(this._nextLevel);
         }
         this._nextLevel = null;
         if(Boolean(this._vipName))
         {
            ObjectUtils.disposeObject(this._vipName);
         }
         this._vipName = null;
         if(Boolean(this._DueTipSprite))
         {
            ObjectUtils.disposeObject(this._DueTipSprite);
         }
         this._DueTipSprite = null;
         if(Boolean(this._DueTip))
         {
            ObjectUtils.disposeObject(this._DueTip);
         }
         this._DueTip = null;
         if(Boolean(this._dueDataWord))
         {
            ObjectUtils.disposeObject(this._dueDataWord);
         }
         this._dueDataWord = null;
         if(Boolean(this._dueData))
         {
            ObjectUtils.disposeObject(this._dueData);
         }
         this._dueData = null;
         if(Boolean(this._helpFrame))
         {
            this._helpFrame.dispose();
         }
         this._helpFrame = null;
         if(Boolean(parent))
         {
            this.parent.removeChild(this);
         }
      }
   }
}

