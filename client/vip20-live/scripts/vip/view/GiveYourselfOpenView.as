package vip.view
{
   import baglocked.BaglockedManager;
   import com.pickgliss.effect.EffectManager;
   import com.pickgliss.effect.EffectTypes;
   import com.pickgliss.effect.IEffect;
   import com.pickgliss.events.FrameEvent;
   import com.pickgliss.toplevel.StageReferance;
   import com.pickgliss.ui.AlertManager;
   import com.pickgliss.ui.ComponentFactory;
   import com.pickgliss.ui.LayerManager;
   import com.pickgliss.ui.controls.BaseButton;
   import com.pickgliss.ui.controls.SelectedButtonGroup;
   import com.pickgliss.ui.controls.SelectedCheckButton;
   import com.pickgliss.ui.controls.TextInput;
   import com.pickgliss.ui.controls.alert.BaseAlerFrame;
   import com.pickgliss.ui.core.Disposeable;
   import com.pickgliss.ui.image.Scale9CornerImage;
   import com.pickgliss.ui.image.ScaleBitmapImage;
   import com.pickgliss.ui.image.ScaleLeftRightImage;
   import com.pickgliss.ui.text.FilterFrameText;
   import com.pickgliss.utils.ObjectUtils;
   import ddt.events.PlayerPropertyEvent;
   import ddt.manager.ItemManager;
   import ddt.manager.LanguageMgr;
   import ddt.manager.LeavePageManager;
   import ddt.manager.MessageTipManager;
   import ddt.manager.PlayerManager;
   import ddt.manager.ShopManager;
   import ddt.manager.SocketManager;
   import ddt.manager.SoundManager;
   import ddt.view.bossbox.AwardsView;
   import flash.display.Bitmap;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import vip.VipController;
   
   public class GiveYourselfOpenView extends Sprite implements Disposeable
   {
      
      public static var ONE_MONTH_PAY:int = ShopManager.Instance.getMoneyShopItemByTemplateID(11992).getItemPrice(1).moneyValue;
      
      public static var THREE_MONTH_PAY:int = ShopManager.Instance.getMoneyShopItemByTemplateID(11992).getItemPrice(2).moneyValue;
      
      public static var ONE_YEAR_PAY:int = ShopManager.Instance.getMoneyShopItemByTemplateID(11992).getItemPrice(3).moneyValue;
      
      public static var millisecondsPerDay:int = 1000 * 60 * 60 * 24;
      
      private static const GOLD_PER_XU:int = 1000;
      
      private static const PAY_WITH_XU:int = 0;
      
      private static const PAY_WITH_GOLD:int = 1;
      
      private var _BG:Scale9CornerImage;
      
      private var _buttomBG:ScaleBitmapImage;
      
      protected var _nameImg:Bitmap;
      
      protected var _payStyleImg:Bitmap;
      
      protected var _VIPDaysImg:Bitmap;
      
      protected var _ownedMoneyImg:Bitmap;
      
      protected var _moneyIconImg:Bitmap;
      
      protected var _offerImage:Bitmap;
      
      protected var _showPayMoneyBG:ScaleLeftRightImage;
      
      private var _payBtnGroup:SelectedButtonGroup;
      
      protected var _payForMonth:SelectedCheckButton;
      
      protected var _payForYear:SelectedCheckButton;
      
      protected var _openVipBtn:BaseButton;
      
      protected var _renewalVipBtn:BaseButton;
      
      protected var _rewardBtn:BaseButton;
      
      private var _rewardEffet:IEffect;
      
      private var _secondBtnGroup:SelectedButtonGroup;
      
      protected var _oneBtn:SelectedCheckButton;
      
      protected var _twoBtn:SelectedCheckButton;
      
      protected var _threeBtn:SelectedCheckButton;
      
      protected var _otherBtn:SelectedCheckButton;
      
      protected var _otherInput:TextInput;
      
      protected var _money:FilterFrameText;
      
      protected var _goldModeBtn:SelectedCheckButton;
      
      protected var _monthNum:FilterFrameText;
      
      protected var _showPayMoney:FilterFrameText;
      
      protected var _isSelf:Boolean;
      
      private var awards:AwardsView;
      
      private var alertFrame:BaseAlerFrame;
      
      private var _confirmFrame:BaseAlerFrame;
      
      private var _moneyConfirm:BaseAlerFrame;
      
      protected var days:int = 0;
      
      protected var payNum:int = 0;
      
      protected var basePayNum:int = 0;
      
      protected var time:String = "";
      
      private var _paymentMode:int = PAY_WITH_XU;
      
      public function GiveYourselfOpenView()
      {
         super();
         this._init();
      }
      
      private function _init() : void
      {
         this.initView();
         this.initEvent();
      }
      
      private function initView() : void
      {
         this._isSelf = true;
         this.addImg();
         this.addFirstLevelBtn();
         this.addSecondLevelBtn();
         this.addTextAndBtn();
         this.changePayState(0);
         this.upPayMoneyText();
         this.showOpenOrRenewal();
         this.rewardBtnCanUse();
      }
      
      private function addImg() : void
      {
         this._BG = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.BG");
         this._buttomBG = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.buttomBG");
         this._nameImg = ComponentFactory.Instance.creatBitmap("asset.vip.name");
         this._payStyleImg = ComponentFactory.Instance.creatBitmap("asset.vip.payStyle");
         this._VIPDaysImg = ComponentFactory.Instance.creatBitmap("asset.vip.VIPDays");
         this._ownedMoneyImg = ComponentFactory.Instance.creatBitmap("asset.vip.ownedMoney");
         this._moneyIconImg = ComponentFactory.Instance.creatBitmap("asset.vip.moneyIcon");
         this._showPayMoneyBG = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.showMoney");
         this._offerImage = ComponentFactory.Instance.creatBitmap("asset.vip.Offer");
         addChild(this._BG);
         addChild(this._buttomBG);
         addChild(this._nameImg);
         addChild(this._payStyleImg);
         addChild(this._VIPDaysImg);
         addChild(this._ownedMoneyImg);
         addChild(this._moneyIconImg);
         addChild(this._showPayMoneyBG);
         addChild(this._offerImage);
         this._nameImg.visible = false;
      }
      
      private function addFirstLevelBtn() : void
      {
         this._payBtnGroup = new SelectedButtonGroup();
         this._payForMonth = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.payForMonth");
         this._payForMonth.text = "Trả theo tháng";
         addChild(this._payForMonth);
         this._payBtnGroup.addSelectItem(this._payForMonth);
         this._payForYear = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.payForYear");
         this._payForYear.text = "Trả theo năm";
         addChild(this._payForYear);
         this._payBtnGroup.addSelectItem(this._payForYear);
         this._payBtnGroup.selectIndex = 0;
      }
      
      private function addSecondLevelBtn() : void
      {
         this._secondBtnGroup = new SelectedButtonGroup(false);
         this._oneBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.one");
         addChild(this._oneBtn);
         this._secondBtnGroup.addSelectItem(this._oneBtn);
         this._twoBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.two");
         addChild(this._twoBtn);
         this._secondBtnGroup.addSelectItem(this._twoBtn);
         this._threeBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.three");
         addChild(this._threeBtn);
         this._secondBtnGroup.addSelectItem(this._threeBtn);
         this._otherBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.other");
         this._otherBtn.text = LanguageMgr.GetTranslation("ddt.vip.vipView.other");
         addChild(this._otherBtn);
         this._secondBtnGroup.addSelectItem(this._otherBtn);
         this._secondBtnGroup.selectIndex = 1;
      }
      
      private function addTextAndBtn() : void
      {
         this._money = ComponentFactory.Instance.creat("GiveYourselfOpenView.money");
         this._goldModeBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.goldModeBtn");
         this._goldModeBtn.text = "Dùng Vàng";
         this._goldModeBtn.selected = false;
         this._otherInput = ComponentFactory.Instance.creat("GiveYourselfOpenView.otherText");
         this._monthNum = ComponentFactory.Instance.creat("GiveYourselfOpenView.monthNum");
         this._showPayMoney = ComponentFactory.Instance.creat("GiveYourselfOpenView.showPayMoneyTxt");
         this._openVipBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.openVipBtn");
         this._renewalVipBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.renewalVipBtn");
         this._rewardBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.rewardBtn");
         this._rewardEffet = EffectManager.Instance.creatEffect(EffectTypes.ALPHA_SHINER_ANIMATION,this._rewardBtn);
         addChild(this._otherInput);
         addChild(this._money);
         addChild(this._goldModeBtn);
         addChild(this._monthNum);
         addChild(this._openVipBtn);
         addChild(this._renewalVipBtn);
         addChild(this._rewardBtn);
         this._showPayMoneyBG.addChild(this._showPayMoney);
         this.updateBalanceText();
         this._otherInput.textField.restrict = "0-9";
         this._otherInput.maxChars = 2;
         this._monthNum.text = LanguageMgr.GetTranslation("ddt.vip.vipView.months");
      }
      
      protected function showOpenOrRenewal() : void
      {
         if(this._isSelf)
         {
            if(PlayerManager.Instance.Self.VIPExp <= 0 && !PlayerManager.Instance.Self.IsVIP)
            {
               this._openVipBtn.visible = true;
               this._renewalVipBtn.visible = false;
            }
            else
            {
               this._openVipBtn.visible = false;
               this._renewalVipBtn.visible = true;
            }
         }
         else
         {
            this._openVipBtn.visible = true;
            this._renewalVipBtn.visible = false;
            this._openVipBtn.x = 148;
         }
      }
      
      private function rewardBtnCanUse() : void
      {
         if(PlayerManager.Instance.Self.IsVIP)
         {
            this._rewardBtn.enable = true;
            if(PlayerManager.Instance.Self.canTakeVipReward)
            {
               this._rewardEffet.play();
            }
            else
            {
               this._rewardEffet.stop();
            }
         }
         else
         {
            this._rewardBtn.enable = false;
            this._rewardEffet.stop();
         }
      }
      
      private function initEvent() : void
      {
         this._payBtnGroup.addEventListener(Event.CHANGE,this.__payBtnClickHandler);
         this._secondBtnGroup.addEventListener(Event.CHANGE,this.__upPayNum);
         this._otherBtn.addEventListener(MouseEvent.CLICK,this.__focusOtherInput);
         this._otherInput.addEventListener(MouseEvent.CLICK,this.__selectOtherBtn);
         this._otherInput.addEventListener(Event.CHANGE,this.__confirmInput);
         this._openVipBtn.addEventListener(MouseEvent.CLICK,this.__openVip);
         this._renewalVipBtn.addEventListener(MouseEvent.CLICK,this.__openVip);
         this._rewardBtn.addEventListener(MouseEvent.CLICK,this.__reward);
         this._goldModeBtn.addEventListener(MouseEvent.CLICK,this.__togglePaymentMode);
         PlayerManager.Instance.Self.addEventListener(PlayerPropertyEvent.PROPERTY_CHANGE,this.__propertyChange);
      }
      
      private function removeEvent() : void
      {
         this._payBtnGroup.removeEventListener(Event.CHANGE,this.__payBtnClickHandler);
         this._secondBtnGroup.removeEventListener(Event.CHANGE,this.__upPayNum);
         this._otherBtn.removeEventListener(MouseEvent.CLICK,this.__focusOtherInput);
         this._otherInput.removeEventListener(MouseEvent.CLICK,this.__selectOtherBtn);
         this._otherInput.removeEventListener(Event.CHANGE,this.__confirmInput);
         this._openVipBtn.removeEventListener(MouseEvent.CLICK,this.__openVip);
         this._renewalVipBtn.removeEventListener(MouseEvent.CLICK,this.__openVip);
         this._rewardBtn.removeEventListener(MouseEvent.CLICK,this.__reward);
         this._goldModeBtn.removeEventListener(MouseEvent.CLICK,this.__togglePaymentMode);
         PlayerManager.Instance.Self.removeEventListener(PlayerPropertyEvent.PROPERTY_CHANGE,this.__propertyChange);
      }
      
      private function __reward(param1:MouseEvent) : void
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         var _loc4_:Date = null;
         var _loc5_:Date = null;
         SoundManager.instance.play("008");
         if(PlayerManager.Instance.Self.canTakeVipReward)
         {
            this.awards = ComponentFactory.Instance.creat("vip.awardFrame");
            this.awards.escEnable = true;
            this.awards.boxType = 2;
            _loc2_ = [ItemManager.Instance.getTemplateById(11998),ItemManager.Instance.getTemplateById(11997)];
            this.awards.vipAwardGoodsList = _loc2_;
            this.awards.addEventListener(AwardsView.HAVEBTNCLICK,this.__sendReward);
            this.awards.addEventListener(FrameEvent.RESPONSE,this.__responseHandler);
            LayerManager.Instance.addToLayer(this.awards,LayerManager.GAME_DYNAMIC_LAYER,true,LayerManager.BLCAK_BLOCKGOUND);
         }
         else
         {
            _loc3_ = 0;
            _loc4_ = PlayerManager.Instance.Self.systemDate as Date;
            if(_loc4_.day == 0)
            {
               _loc3_ = 1;
            }
            else
            {
               _loc3_ = 8 - _loc4_.day;
            }
            _loc5_ = new Date(_loc4_.getTime() + _loc3_ * millisecondsPerDay);
            this.alertFrame = AlertManager.Instance.simpleAlert(LanguageMgr.GetTranslation("AlertDialog.Info"),LanguageMgr.GetTranslation("ddt.vip.vipView.cueDateScript",_loc5_.month + 1,_loc5_.date),LanguageMgr.GetTranslation("ok"),"",false,false,false,LayerManager.ALPHA_BLOCKGOUND);
            this.alertFrame.moveEnable = false;
            this.alertFrame.addEventListener(FrameEvent.RESPONSE,this.__alertHandler);
         }
      }
      
      private function __alertHandler(param1:FrameEvent) : void
      {
         SoundManager.instance.play("008");
         this.alertFrame.removeEventListener(FrameEvent.RESPONSE,this.__alertHandler);
         if(Boolean(this.alertFrame) && Boolean(this.alertFrame.parent))
         {
            this.alertFrame.parent.removeChild(this.alertFrame);
         }
         if(Boolean(this.alertFrame))
         {
            this.alertFrame.dispose();
         }
         this.alertFrame = null;
      }
      
      private function __responseHandler(param1:FrameEvent) : void
      {
         SoundManager.instance.play("008");
         this.awards.removeEventListener(FrameEvent.RESPONSE,this.__responseHandler);
         switch(param1.responseCode)
         {
            case FrameEvent.CLOSE_CLICK:
            case FrameEvent.ESC_CLICK:
               this.awards.dispose();
               this.awards = null;
         }
      }
      
      private function __sendReward(param1:Event) : void
      {
         SoundManager.instance.play("008");
         SocketManager.Instance.out.sendDailyAward(3);
         this.awards.removeEventListener(AwardsView.HAVEBTNCLICK,this.__sendReward);
         this.awards.dispose();
         PlayerManager.Instance.Self.canTakeVipReward = false;
         this.rewardBtnCanUse();
      }
      
      private function __propertyChange(param1:PlayerPropertyEvent) : void
      {
         if(Boolean(param1.changedProperties["Money"]) || Boolean(param1.changedProperties["Gold"]))
         {
            this.updateBalanceText();
         }
         if(Boolean(param1.changedProperties["isVip"]) || Boolean(param1.changedProperties["canTakeVipReward"]))
         {
            this.showOpenOrRenewal();
            this.rewardBtnCanUse();
         }
      }
      
      private function updateBalanceText() : void
      {
         this._money.text = "Xu: " + PlayerManager.Instance.Self.Money + " | Vàng: " + PlayerManager.Instance.Self.Gold;
      }
      
      private function __togglePaymentMode(param1:MouseEvent) : void
      {
         SoundManager.instance.play("008");
         this._paymentMode = this._goldModeBtn.selected ? PAY_WITH_GOLD : PAY_WITH_XU;
         this._goldModeBtn.text = this._goldModeBtn.selected ? "Đang dùng Vàng" : "Dùng Vàng";
         this.upPayMoneyText();
      }
      
      private function __upPayNum(param1:Event) : void
      {
         SoundManager.instance.play("008");
         this.upPayMoneyText();
         if(this._secondBtnGroup.selectIndex == 3)
         {
            this._otherInput.visible = true;
            this._monthNum.visible = true;
         }
         else
         {
            this._otherInput.visible = false;
            this._monthNum.visible = false;
         }
         this._otherInput.text = "";
      }
      
      private function __confirmInput(param1:Event) : void
      {
         if(parseInt(this._otherInput.text) > 24)
         {
            MessageTipManager.getInstance().show(LanguageMgr.GetTranslation("ddt.vip.vipView.checkOtherInput24"));
            this._otherInput.text = "";
         }
         if(this._otherInput.text == "0")
         {
            MessageTipManager.getInstance().show(LanguageMgr.GetTranslation("ddt.vip.vipView.checkOtherInput0"));
            this._otherInput.text = "";
         }
         this.upPayMoneyText();
      }
      
      protected function __openVip(param1:MouseEvent) : void
      {
         SoundManager.instance.play("008");
         if(PlayerManager.Instance.Self.bagLocked)
         {
            BaglockedManager.Instance.show();
            return;
         }
         if(this._paymentMode == PAY_WITH_GOLD)
         {
            if(PlayerManager.Instance.Self.Gold < this.payNum)
            {
               MessageTipManager.getInstance().show("Không đủ Vàng.");
               return;
            }
         }
         else if(PlayerManager.Instance.Self.Money < this.payNum)
         {
            this._moneyConfirm = AlertManager.Instance.simpleAlert(LanguageMgr.GetTranslation("AlertDialog.Info"),LanguageMgr.GetTranslation("tank.view.comon.lack"),LanguageMgr.GetTranslation("ok"),LanguageMgr.GetTranslation("cancel"),false,false,false,LayerManager.ALPHA_BLOCKGOUND);
            this._moneyConfirm.moveEnable = false;
            this._moneyConfirm.addEventListener(FrameEvent.RESPONSE,this.__moneyConfirmHandler);
            return;
         }
         if(this._otherBtn.selected && this._otherInput.text == "")
         {
            MessageTipManager.getInstance().show(LanguageMgr.GetTranslation("ddt.vip.vipView.checkOtherInput"));
            return;
         }
         var _loc2_:String = "Gia hạn VIP " + this.time + " với " + this.payNum + (this._paymentMode == PAY_WITH_GOLD ? " Vàng" : " Xu") + "?";
         this._confirmFrame = AlertManager.Instance.simpleAlert(LanguageMgr.GetTranslation("ddt.vip.vipFrame.ConfirmTitle"),_loc2_,LanguageMgr.GetTranslation("ok"),LanguageMgr.GetTranslation("cancel"),false,true,true,LayerManager.BLCAK_BLOCKGOUND);
         this._confirmFrame.moveEnable = false;
         this._confirmFrame.addEventListener(FrameEvent.RESPONSE,this.__confirm);
      }
      
      private function __moneyConfirmHandler(param1:FrameEvent) : void
      {
         this._moneyConfirm.removeEventListener(FrameEvent.RESPONSE,this.__moneyConfirmHandler);
         switch(param1.responseCode)
         {
            case FrameEvent.ENTER_CLICK:
            case FrameEvent.SUBMIT_CLICK:
               LeavePageManager.leaveToFillPath();
         }
         this._moneyConfirm.dispose();
         if(Boolean(this._moneyConfirm.parent))
         {
            this._moneyConfirm.parent.removeChild(this._moneyConfirm);
         }
         this._moneyConfirm = null;
      }
      
      private function __confirm(param1:FrameEvent) : void
      {
         SoundManager.instance.play("008");
         this._confirmFrame.removeEventListener(FrameEvent.RESPONSE,this.__confirm);
         switch(param1.responseCode)
         {
            case FrameEvent.SUBMIT_CLICK:
            case FrameEvent.ENTER_CLICK:
               this.sendVip();
               this._otherInput.text = "";
               this.upPayMoneyText();
         }
         this._confirmFrame.dispose();
         if(Boolean(this._confirmFrame.parent))
         {
            this._confirmFrame.parent.removeChild(this._confirmFrame);
         }
      }
      
      protected function sendVip() : void
      {
         this.days = 0;
         if(this._payBtnGroup.selectIndex == 0)
         {
            switch(this._secondBtnGroup.selectIndex)
            {
               case 0:
                  this.days = 31;
                  break;
               case 1:
                  this.days = 31 * 3;
                  break;
               case 2:
                  this.days = 31 * 6;
                  break;
               case 3:
                  this.days = parseInt(this._otherInput.text) * 31;
            }
         }
         else
         {
            switch(this._secondBtnGroup.selectIndex)
            {
               case 0:
                  this.days = 365;
                  break;
               case 1:
                  this.days = 365 * 2;
            }
         }
         this.send();
      }
      
      protected function send() : void
      {
         VipController.instance.sendOpenVip(PlayerManager.Instance.Self.NickName,this.days,false,this._paymentMode);
      }
      
      private function __focusOtherInput(param1:MouseEvent) : void
      {
         StageReferance.stage.focus = this._otherInput.textField;
      }
      
      private function __selectOtherBtn(param1:MouseEvent) : void
      {
         this._secondBtnGroup.selectIndex = 3;
      }
      
      private function __payBtnClickHandler(param1:Event) : void
      {
         SoundManager.instance.play("008");
         this.changePayState(this._payBtnGroup.selectIndex);
         this._secondBtnGroup.selectIndex = 0;
         this.upPayMoneyText();
         this._otherInput.text = "";
      }
      
      private function changePayState(param1:int) : void
      {
         if(param1 == 0)
         {
            this._oneBtn.text = LanguageMgr.GetTranslation("ddt.vip.vipView.oneMonth");
            this._twoBtn.text = LanguageMgr.GetTranslation("ddt.vip.vipView.threeMonth");
            this._threeBtn.text = LanguageMgr.GetTranslation("ddt.vip.vipView.sixMonth");
            this._threeBtn.visible = true;
            this._otherBtn.visible = true;
            this._otherInput.visible = false;
            this._monthNum.visible = false;
            this._offerImage.visible = false;
            this._twoBtn.x = 214;
         }
         else
         {
            this._oneBtn.text = LanguageMgr.GetTranslation("ddt.vip.vipView.oneYear");
            this._twoBtn.text = LanguageMgr.GetTranslation("ddt.vip.vipView.twoYear");
            this._threeBtn.visible = false;
            this._otherBtn.visible = false;
            this._otherInput.visible = false;
            this._monthNum.visible = false;
            this._offerImage.visible = true;
            this._twoBtn.x = this._payForYear.x;
         }
      }
      
      protected function upPayMoneyText() : void
      {
         this.basePayNum = 0;
         this.payNum = 0;
         this.time = "";
         switch(this._payBtnGroup.selectIndex)
         {
            case 0:
               switch(this._secondBtnGroup.selectIndex)
               {
                  case 0:
                     this.basePayNum = ONE_MONTH_PAY;
                     this.time = "1 tháng";
                     break;
                  case 1:
                     this.basePayNum = THREE_MONTH_PAY;
                     this.time = "3 tháng";
                     break;
                  case 2:
                     this.basePayNum = ONE_MONTH_PAY * 6;
                     this.time = "6 tháng";
                     break;
                  case 3:
                     this.basePayNum = ONE_MONTH_PAY * parseInt(this._otherInput.text);
                     this.time = this._otherInput.text + " tháng";
               }
               break;
            case 1:
               switch(this._secondBtnGroup.selectIndex)
               {
                  case 0:
                     this.basePayNum = ONE_YEAR_PAY;
                     this.time = "1 năm";
                     break;
                  case 1:
                     this.basePayNum = ONE_YEAR_PAY * 2;
                     this.time = "2 năm";
               }
         }
         this.payNum = this._paymentMode == PAY_WITH_GOLD ? this.basePayNum * GOLD_PER_XU : this.basePayNum;
         this._showPayMoney.htmlText = (this._paymentMode == PAY_WITH_GOLD ? "Vàng: " : "Xu: ") + this.payNum;
      }
      
      public function dispose() : void
      {
         this.removeEvent();
         EffectManager.Instance.removeEffect(this._rewardEffet);
         if(Boolean(this._payBtnGroup))
         {
            this._payBtnGroup.dispose();
         }
         this._payBtnGroup = null;
         if(Boolean(this._payForMonth))
         {
            ObjectUtils.disposeObject(this._payForMonth);
         }
         this._payForMonth = null;
         if(Boolean(this._payForYear))
         {
            ObjectUtils.disposeObject(this._payForYear);
         }
         this._payForYear = null;
         if(Boolean(this._secondBtnGroup))
         {
            this._secondBtnGroup.dispose();
         }
         this._secondBtnGroup = null;
         if(Boolean(this._oneBtn))
         {
            ObjectUtils.disposeObject(this._oneBtn);
         }
         this._oneBtn = null;
         if(Boolean(this._twoBtn))
         {
            ObjectUtils.disposeObject(this._twoBtn);
         }
         this._twoBtn = null;
         if(Boolean(this._threeBtn))
         {
            ObjectUtils.disposeObject(this._threeBtn);
         }
         this._threeBtn = null;
         if(Boolean(this._otherBtn))
         {
            ObjectUtils.disposeObject(this._otherBtn);
         }
         this._otherBtn = null;
         if(Boolean(this._otherInput))
         {
            ObjectUtils.disposeObject(this._otherInput);
         }
         this._otherInput = null;
         if(Boolean(this._openVipBtn))
         {
            ObjectUtils.disposeObject(this._openVipBtn);
         }
         this._openVipBtn = null;
         if(Boolean(this._BG))
         {
            ObjectUtils.disposeObject(this._BG);
         }
         this._BG = null;
         if(Boolean(this._buttomBG))
         {
            ObjectUtils.disposeObject(this._buttomBG);
         }
         this._buttomBG = null;
         if(Boolean(this._nameImg))
         {
            ObjectUtils.disposeObject(this._nameImg);
         }
         this._nameImg = null;
         if(Boolean(this._payStyleImg))
         {
            ObjectUtils.disposeObject(this._payStyleImg);
         }
         this._payStyleImg = null;
         if(Boolean(this._VIPDaysImg))
         {
            ObjectUtils.disposeObject(this._VIPDaysImg);
         }
         this._VIPDaysImg = null;
         if(Boolean(this._ownedMoneyImg))
         {
            ObjectUtils.disposeObject(this._ownedMoneyImg);
         }
         this._ownedMoneyImg = null;
         if(Boolean(this._moneyIconImg))
         {
            ObjectUtils.disposeObject(this._moneyIconImg);
         }
         this._moneyIconImg = null;
         if(Boolean(this._money))
         {
            ObjectUtils.disposeObject(this._money);
         }
         this._money = null;
         if(Boolean(this._goldModeBtn))
         {
            ObjectUtils.disposeObject(this._goldModeBtn);
         }
         this._goldModeBtn = null;
         if(Boolean(this._monthNum))
         {
            ObjectUtils.disposeObject(this._monthNum);
         }
         this._monthNum = null;
         if(Boolean(this._showPayMoneyBG))
         {
            ObjectUtils.disposeObject(this._showPayMoneyBG);
         }
         this._showPayMoneyBG = null;
         if(Boolean(this._showPayMoney))
         {
            ObjectUtils.disposeObject(this._showPayMoney);
         }
         this._showPayMoney = null;
         if(Boolean(this._confirmFrame))
         {
            this._confirmFrame.dispose();
         }
         this._confirmFrame = null;
         if(Boolean(this._moneyConfirm))
         {
            this._moneyConfirm.dispose();
         }
         this._moneyConfirm = null;
         if(Boolean(this._renewalVipBtn))
         {
            ObjectUtils.disposeObject(this._renewalVipBtn);
         }
         this._renewalVipBtn = null;
         if(Boolean(this._rewardBtn))
         {
            ObjectUtils.disposeObject(this._rewardBtn);
         }
         this._rewardBtn = null;
         if(Boolean(this._offerImage))
         {
            ObjectUtils.disposeObject(this._offerImage);
         }
         this._offerImage = null;
         if(Boolean(this.alertFrame))
         {
            this.alertFrame.dispose();
         }
         this.alertFrame = null;
         if(Boolean(parent))
         {
            parent.removeChild(this);
         }
      }
   }
}

