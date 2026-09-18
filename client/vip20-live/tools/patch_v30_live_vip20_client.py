from pathlib import Path
import re, shutil

src_root = Path(r"C:\Gunny\_work\v30-live-decrypted\src\scripts")
stage = Path(r"C:\Gunny\_work\v30-vip20-client-patch\scripts")
if stage.parent.exists():
    shutil.rmtree(stage.parent)
for rel in [
    "vip/view/GiveYourselfOpenView.as",
    "vip/view/VipFrameHead.as",
    "vip/VipController.as",
    "ddt/manager/GameSocketOut.as",
    "ddt/view/common/VipLevelIcon.as",
]:
    dst = stage / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src_root / rel, dst)

def rep(path, old, new, label, count=1):
    s = path.read_text(encoding="utf-8")
    n = s.count(old)
    if n != count:
        raise RuntimeError(f"{label}: expected {count}, got {n}")
    path.write_text(s.replace(old, new), encoding="utf-8")
    print(f"PATCH {label}=PASS")

give = stage / "vip/view/GiveYourselfOpenView.as"
rep(give,
    '      public static var ONE_YEAR_PAY:int = ShopManager.Instance.getMoneyShopItemByTemplateID(11992).getItemPrice(2).moneyValue;',
    '      public static var THREE_MONTH_PAY:int = ShopManager.Instance.getMoneyShopItemByTemplateID(11992).getItemPrice(2).moneyValue;\n      \n      public static var ONE_YEAR_PAY:int = ShopManager.Instance.getMoneyShopItemByTemplateID(11992).getItemPrice(3).moneyValue;',
    "give price mapping")
rep(give,
    '      public static var millisecondsPerDay:int = 1000 * 60 * 60 * 24;',
    '      public static var millisecondsPerDay:int = 1000 * 60 * 60 * 24;\n      \n      private static const GOLD_PER_XU:int = 1000;\n      \n      private static const PAY_WITH_XU:int = 0;\n      \n      private static const PAY_WITH_GOLD:int = 1;',
    "give payment constants")
rep(give,
    '      protected var _money:FilterFrameText;',
    '      protected var _money:FilterFrameText;\n      \n      protected var _goldModeBtn:SelectedCheckButton;',
    "give gold button field")
rep(give,
    '      protected var payNum:int = 0;\n      \n      protected var time:String = "";',
    '      protected var payNum:int = 0;\n      \n      protected var basePayNum:int = 0;\n      \n      protected var time:String = "";\n      \n      private var _paymentMode:int = PAY_WITH_XU;',
    "give payment state")
rep(give,
    '         this._money = ComponentFactory.Instance.creat("GiveYourselfOpenView.money");',
    '         this._money = ComponentFactory.Instance.creat("GiveYourselfOpenView.money");\n         this._goldModeBtn = ComponentFactory.Instance.creatComponentByStylename("GiveYourselfOpenView.goldModeBtn");\n         this._goldModeBtn.text = "Dùng Vàng";\n         this._goldModeBtn.selected = false;',
    "give create gold button")
rep(give,
    '         addChild(this._money);',
    '         addChild(this._money);\n         addChild(this._goldModeBtn);',
    "give add gold button")
rep(give,
    '         this._showPayMoneyBG.addChild(this._showPayMoney);\n         this._money.text = PlayerManager.Instance.Self.Money + LanguageMgr.GetTranslation("money");',
    '         this._showPayMoneyBG.addChild(this._showPayMoney);\n         this.updateBalanceText();',
    "give initial balance")
rep(give,
    '         this._rewardBtn.addEventListener(MouseEvent.CLICK,this.__reward);',
    '         this._rewardBtn.addEventListener(MouseEvent.CLICK,this.__reward);\n         this._goldModeBtn.addEventListener(MouseEvent.CLICK,this.__togglePaymentMode);',
    "give add gold event")
rep(give,
    '         this._rewardBtn.removeEventListener(MouseEvent.CLICK,this.__reward);',
    '         this._rewardBtn.removeEventListener(MouseEvent.CLICK,this.__reward);\n         this._goldModeBtn.removeEventListener(MouseEvent.CLICK,this.__togglePaymentMode);',
    "give remove gold event")

s = give.read_text(encoding="utf-8")
pat = re.compile(r'      private function __propertyChange\(param1:PlayerPropertyEvent\) : void\n      \{.*?\n      \}\n      \n      private function __upPayNum', re.S)
m = pat.search(s)
if not m:
    raise RuntimeError("property block missing")
new = '''      private function __propertyChange(param1:PlayerPropertyEvent) : void
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
      
      private function __upPayNum'''
give.write_text(s[:m.start()] + new + s[m.end():], encoding="utf-8")
print("PATCH give property/toggle=PASS")

s = give.read_text(encoding="utf-8")
pat = re.compile(r'      protected function __openVip\(param1:MouseEvent\) : void\n      \{.*?\n      \}\n      \n      private function __moneyConfirmHandler', re.S)
m = pat.search(s)
if not m:
    raise RuntimeError("open vip block missing")
new = '''      protected function __openVip(param1:MouseEvent) : void
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
      
      private function __moneyConfirmHandler'''
give.write_text(s[:m.start()] + new + s[m.end():], encoding="utf-8")
print("PATCH give open vip=PASS")

rep(give,
    '         VipController.instance.sendOpenVip(PlayerManager.Instance.Self.NickName,this.days);',
    '         VipController.instance.sendOpenVip(PlayerManager.Instance.Self.NickName,this.days,false,this._paymentMode);',
    "give four-field send")

s = give.read_text(encoding="utf-8")
pat = re.compile(r'      protected function upPayMoneyText\(\) : void\n      \{.*?\n      \}\n      \n      public function dispose', re.S)
m = pat.search(s)
if not m:
    raise RuntimeError("price block missing")
new = '''      protected function upPayMoneyText() : void
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
      
      public function dispose'''
give.write_text(s[:m.start()] + new + s[m.end():], encoding="utf-8")
print("PATCH give dynamic price=PASS")

rep(give,
    '         this._money = null;\n         if(Boolean(this._monthNum))',
    '         this._money = null;\n         if(Boolean(this._goldModeBtn))\n         {\n            ObjectUtils.disposeObject(this._goldModeBtn);\n         }\n         this._goldModeBtn = null;\n         if(Boolean(this._monthNum))',
    "give dispose gold")

ctrl = stage / "vip/VipController.as"
rep(ctrl,
    '      public function sendOpenVip(param1:String, param2:int) : void\n      {\n         SocketManager.Instance.out.sendOpenVip(param1,param2);\n      }',
    '      public function sendOpenVip(param1:String, param2:int, param3:Boolean = false, param4:int = 0) : void\n      {\n         SocketManager.Instance.out.sendOpenVip(param1,param2,param3,param4);\n      }',
    "controller protocol")

sock = stage / "ddt/manager/GameSocketOut.as"
rep(sock,
    '      public function sendOpenVip(param1:String, param2:int) : void\n      {\n         var _loc3_:PackageOut = new PackageOut(ePackageType.VIP_RENEWAL);\n         _loc3_.writeUTF(param1);\n         _loc3_.writeInt(param2);\n         this.sendPackage(_loc3_);\n      }',
    '      public function sendOpenVip(param1:String, param2:int, param3:Boolean = false, param4:int = 0) : void\n      {\n         var _loc5_:PackageOut = new PackageOut(ePackageType.VIP_RENEWAL);\n         _loc5_.writeUTF(param1);\n         _loc5_.writeInt(param2);\n         _loc5_.writeBoolean(param3);\n         _loc5_.writeByte(param4);\n         this.sendPackage(_loc5_);\n      }',
    "socket protocol")

head = stage / "vip/view/VipFrameHead.as"
rep(head,
    '      private static var eachLevelEXP:Array = [0,150,350,700,1250,2050,3050,4250,5650];',
    '      private static var eachLevelEXP:Array = [0,200,400,800,2000,4000,8000,20000,40000,80000,200000,400000,800000,1200000,1800000,2600000,3600000,4800000,6200000,7800000];',
    "head vip20 floors")

s = head.read_text(encoding="utf-8")
pat = re.compile(r'      private function upView\(\) : void\n      \{.*?\n      \}\n      \n      private function grayOrLightVIP', re.S)
m = pat.search(s)
if not m:
    raise RuntimeError("VipFrameHead upView missing")
new = '''      private function upView() : void
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
      
      private function grayOrLightVIP'''
head.write_text(s[:m.start()] + new + s[m.end():], encoding="utf-8")
print("PATCH head upView=PASS")

icon = stage / "ddt/view/common/VipLevelIcon.as"
rep(icon,
    '                     if(PlayerManager.Instance.Self.VIPLevel < 9)',
    '                     if(PlayerManager.Instance.Self.VIPLevel < 20)',
    "icon vip20 tooltip")
rep(icon,
    '      private function updateIcon() : void\n      {\n         if(this._size == SIZE_SMALL)',
    '      private function updateIcon() : void\n      {\n         var displayLevel:int = Math.max(0,Math.min(9,this._level));\n         if(this._size == SIZE_SMALL)',
    "icon display clamp var")
rep(icon,
    '            this._vipIcon.setFrame(this._level + 11);',
    '            this._vipIcon.setFrame(displayLevel + 11);',
    "icon small clamp")
rep(icon,
    '            this._vipIcon.setFrame(this._level + 1);',
    '            this._vipIcon.setFrame(displayLevel + 1);',
    "icon big clamp")

print("V30_CLIENT_SOURCE_PATCH=PASS")
