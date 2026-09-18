package ddt.manager
{
   import cardSystem.model.CardModel;
   import ddt.Version;
   import ddt.data.AccountInfo;
   import ddt.data.socket.AcademyPackageType;
   import ddt.data.socket.ChurchPackageType;
   import ddt.data.socket.CrazyTankPackageType;
   import ddt.data.socket.HotSpringPackageType;
   import ddt.data.socket.ePackageType;
   import ddt.utils.CrytoUtils;
   import email.manager.MailManager;
   import flash.utils.ByteArray;
   import road7th.comm.ByteSocket;
   import road7th.comm.PackageOut;
   import road7th.math.randRange;
   
   public class GameSocketOut
   {
      
      private var _socket:ByteSocket;
      
      public function GameSocketOut(param1:ByteSocket)
      {
         super();
         this._socket = param1;
      }
      
      public function sendLogin(param1:AccountInfo) : void
      {
         this._socket.resetKey();
         var _loc2_:Date = new Date();
         var _loc3_:ByteArray = new ByteArray();
         var _loc4_:int = randRange(100,10000);
         _loc3_.writeShort(_loc2_.fullYearUTC);
         _loc3_.writeByte(_loc2_.monthUTC + 1);
         _loc3_.writeByte(_loc2_.dateUTC);
         _loc3_.writeByte(_loc2_.hoursUTC);
         _loc3_.writeByte(_loc2_.minutesUTC);
         _loc3_.writeByte(_loc2_.secondsUTC);
         var _loc5_:Array = [Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255),Math.ceil(Math.random() * 255)];
         var _loc6_:int = 0;
         while(_loc6_ < _loc5_.length)
         {
            _loc3_.writeByte(_loc5_[_loc6_]);
            _loc6_++;
         }
         _loc3_.writeUTFBytes(param1.Account + "," + param1.Password);
         _loc3_ = CrytoUtils.rsaEncry5(param1.Key,_loc3_);
         _loc3_.position = 0;
         var _loc7_:PackageOut = new PackageOut(ePackageType.LOGIN);
         _loc7_.writeInt(Version.Build);
         _loc7_.writeInt(DesktopManager.Instance.desktopType);
         _loc7_.writeBytes(_loc3_);
         this.sendPackage(_loc7_);
         this._socket.setKey(_loc5_);
      }
      
      public function sendWeeklyClick() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.WEEKLY_CLICK_CNT);
         this.sendPackage(_loc1_);
      }
      
      public function sendGameLogin(param1:int, param2:int, param3:int = -1, param4:String = "", param5:Boolean = false) : void
      {
         var _loc6_:PackageOut = new PackageOut(ePackageType.GAME_ROOM_LOGIN);
         _loc6_.writeBoolean(param5);
         _loc6_.writeInt(param1);
         _loc6_.writeInt(param2);
         if(param2 == -1)
         {
            _loc6_.writeInt(param3);
            _loc6_.writeUTF(param4);
         }
         this.sendPackage(_loc6_);
      }
      
      public function sendSceneLogin(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.SCENE_LOGIN);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendGameStyle(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GAME_PICKUP_STYLE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendDailyAward(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.DAILY_AWARD);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendBuyGoods(param1:Array, param2:Array, param3:Array, param4:Array, param5:Array, param6:Array = null, param7:int = 0) : void
      {
         if(param1.length > 50)
         {
            this.sendBuyGoods(param1.splice(0,50),param2.splice(0,50),param3.splice(0,50),param4.splice(0,50),param5.splice(0,50),param6.splice(0,50),param7);
            this.sendBuyGoods(param1,param2,param3,param4,param5,param6,param7);
            return;
         }
         var _loc8_:PackageOut = new PackageOut(ePackageType.BUY_GOODS);
         var _loc9_:int = int(param1.length);
         _loc8_.writeInt(_loc9_);
         var _loc10_:uint = 0;
         while(_loc10_ < _loc9_)
         {
            _loc8_.writeInt(param1[_loc10_]);
            _loc8_.writeInt(param2[_loc10_]);
            _loc8_.writeUTF(param3[_loc10_]);
            _loc8_.writeBoolean(param5[_loc10_]);
            if(param6 == null)
            {
               _loc8_.writeUTF("");
            }
            else
            {
               _loc8_.writeUTF(param6[_loc10_]);
            }
            _loc8_.writeInt(param4[_loc10_]);
            _loc10_++;
         }
         _loc8_.writeInt(param7);
         this.sendPackage(_loc8_);
      }
      
      public function sendBuyProp(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.PROP_BUY);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendSellProp(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.PROP_SELL);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendQuickBuyGoldBox(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.BUY_QUICK_GOLDBOX);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendBuyGiftBag(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.BUY_GIFTBAG);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendPresentGoods(param1:Array, param2:Array, param3:Array, param4:String, param5:String, param6:Array = null) : void
      {
         var _loc7_:PackageOut = new PackageOut(ePackageType.GOODS_PRESENT);
         var _loc8_:int = int(param1.length);
         _loc7_.writeUTF(param4);
         _loc7_.writeUTF(param5);
         _loc7_.writeInt(_loc8_);
         var _loc9_:uint = 0;
         while(_loc9_ < _loc8_)
         {
            _loc7_.writeInt(param1[_loc9_]);
            _loc7_.writeInt(param2[_loc9_]);
            _loc7_.writeUTF(param3[_loc9_]);
            if(param6 == null)
            {
               _loc7_.writeUTF("");
            }
            else
            {
               _loc7_.writeUTF(param6[_loc9_]);
            }
            _loc9_++;
         }
         this.sendPackage(_loc7_);
      }
      
      public function sendGoodsContinue(param1:Array) : void
      {
         var _loc2_:int = int(param1.length);
         var _loc3_:PackageOut = new PackageOut(ePackageType.ITEM_CONTINUE);
         _loc3_.writeInt(_loc2_);
         var _loc4_:uint = 0;
         while(_loc4_ < _loc2_)
         {
            _loc3_.writeByte(param1[_loc4_][0]);
            _loc3_.writeInt(param1[_loc4_][1]);
            _loc3_.writeInt(param1[_loc4_][2]);
            _loc3_.writeByte(param1[_loc4_][3]);
            _loc3_.writeBoolean(param1[_loc4_][4]);
            _loc4_++;
         }
         this.sendPackage(_loc3_);
      }
      
      public function sendSellGoods(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.SEll_GOODS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendUpdateGoodsCount(param1:int = -1) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GOODS_COUNT);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendEmail(param1:Object) : void
      {
         var _loc3_:uint = 0;
         var _loc2_:PackageOut = new PackageOut(ePackageType.SEND_MAIL);
         _loc2_.writeUTF(param1.NickName);
         _loc2_.writeUTF(param1.Title);
         _loc2_.writeUTF(param1.Content);
         _loc2_.writeBoolean(param1.isPay);
         _loc2_.writeInt(param1.hours);
         _loc2_.writeInt(param1.SendedMoney);
         while(_loc3_ < MailManager.Instance.NUM_OF_WRITING_DIAMONDS)
         {
            if(Boolean(param1["Annex" + _loc3_]))
            {
               _loc2_.writeByte(param1["Annex" + _loc3_].split(",")[0]);
               _loc2_.writeInt(param1["Annex" + _loc3_].split(",")[1]);
            }
            else
            {
               _loc2_.writeByte(0);
               _loc2_.writeInt(-1);
            }
            _loc3_++;
         }
         this.sendPackage(_loc2_);
      }
      
      public function sendUpdateMail(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.UPDATE_MAIL);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendDeleteMail(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.DELETE_MAIL);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function untreadEmail(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MAIL_CANCEL);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendGetMail(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.GET_MAIL_ATTACHMENT);
         _loc3_.writeInt(param1);
         _loc3_.writeByte(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendPint() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.PING);
         this.sendPackage(_loc1_);
      }
      
      public function sendSuicide(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc2_.writeByte(CrazyTankPackageType.SUICIDE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendKillSelf(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc2_.writeByte(CrazyTankPackageType.KILLSELF);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendItemCompose(param1:Boolean) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.ITEM_COMPOSE);
         _loc2_.writeBoolean(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendItemTransfer(param1:Boolean = true, param2:Boolean = true) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ITEM_TRANSFER);
         _loc3_.writeBoolean(param1);
         _loc3_.writeBoolean(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendItemStrength(param1:Boolean) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.ITEM_STRENGTHEN);
         _loc2_.writeBoolean(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendItemLianhua(param1:int, param2:int, param3:Array, param4:int, param5:int, param6:int, param7:int) : void
      {
         var _loc8_:PackageOut = new PackageOut(ePackageType.ITEM_REFINERY);
         _loc8_.writeInt(param1);
         _loc8_.writeInt(param2);
         var _loc9_:int = 0;
         while(_loc9_ < param3.length)
         {
            _loc8_.writeInt(param3[_loc9_]);
            _loc9_++;
         }
         _loc8_.writeInt(param4);
         _loc8_.writeInt(param5);
         _loc8_.writeInt(param6);
         _loc8_.writeInt(param7);
         this.sendPackage(_loc8_);
      }
      
      public function sendItemEmbed(param1:int, param2:int, param3:int, param4:int, param5:int) : void
      {
         var _loc6_:PackageOut = new PackageOut(ePackageType.ITEM_INLAY);
         _loc6_.writeInt(param1);
         _loc6_.writeInt(param2);
         _loc6_.writeInt(param3);
         _loc6_.writeInt(param4);
         _loc6_.writeInt(param5);
         this.sendPackage(_loc6_);
      }
      
      public function sendItemEmbedBackout(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ITEM_EMBED_BACKOUT);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendItemOpenFiveSixHole(param1:int, param2:int, param3:int) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.OPEN_FIVE_SIX_HOLE);
         _loc4_.writeInt(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendItemTrend(param1:int, param2:int, param3:int, param4:int, param5:int) : void
      {
         var _loc6_:PackageOut = new PackageOut(ePackageType.ITEM_TREND);
         _loc6_.writeInt(param1);
         _loc6_.writeInt(param2);
         _loc6_.writeInt(param3);
         _loc6_.writeInt(param4);
         _loc6_.writeInt(param5);
         this.sendPackage(_loc6_);
      }
      
      public function sendClearStoreBag() : void
      {
         PlayerManager.Instance.Self.StoreBag.items.clear();
         var _loc1_:PackageOut = new PackageOut(ePackageType.CLEAR_STORE_BAG);
         this.sendPackage(_loc1_);
      }
      
      public function sendCheckCode(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CHECK_CODE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendEquipRetrieve() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.EQUIP_RECYCLE_ITEM);
         this.sendPackage(_loc1_);
      }
      
      public function sendItemFusion(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.ITEM_FUSION);
         _loc2_.writeByte(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendSBugle(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.S_BUGLE);
         _loc2_.writeInt(PlayerManager.Instance.Self.ID);
         _loc2_.writeUTF(PlayerManager.Instance.Self.NickName);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendBBugle(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.B_BUGLE);
         _loc2_.writeInt(PlayerManager.Instance.Self.ID);
         _loc2_.writeUTF(PlayerManager.Instance.Self.NickName);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendCBugle(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.C_BUGLE);
         _loc2_.writeInt(PlayerManager.Instance.Self.ID);
         _loc2_.writeUTF(PlayerManager.Instance.Self.NickName);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendDefyAffiche(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.DEFY_AFFICHE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendGameMode(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GAME_PICKUP_STYLE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendAddFriend(param1:String, param2:int, param3:Boolean = false) : void
      {
         if(param1 == "")
         {
            return;
         }
         var _loc4_:PackageOut = new PackageOut(ePackageType.FRIEND_ADD);
         _loc4_.writeUTF(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeBoolean(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendDelFriend(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.FRIEND_REMOVE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendFriendState(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.FRIEND_STATE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendBagLocked(param1:String, param2:int, param3:String = "", param4:String = "", param5:String = "", param6:String = "", param7:String = "") : void
      {
         var _loc8_:PackageOut = new PackageOut(ePackageType.BAG_LOCKED);
         _loc8_.writeUTF(param1);
         _loc8_.writeUTF(param3);
         _loc8_.writeInt(param2);
         _loc8_.writeUTF(param4);
         _loc8_.writeUTF(param5);
         _loc8_.writeUTF(param6);
         _loc8_.writeUTF(param7);
         this.sendPackage(_loc8_);
      }
      
      public function sendBagLockedII(param1:String, param2:String, param3:String, param4:String, param5:String) : void
      {
      }
      
      public function sendConsortiaEquipConstrol(param1:Array) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_EQUIP_CONTROL);
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc2_.writeInt(param1[_loc3_]);
            _loc3_++;
         }
         this.sendPackage(_loc2_);
      }
      
      public function sendErrorMsg(param1:String) : void
      {
         var _loc2_:PackageOut = null;
         if(param1.length < 1000)
         {
            _loc2_ = new PackageOut(ePackageType.CLIENT_LOG);
            _loc2_.writeUTF(param1);
            this.sendPackage(_loc2_);
         }
      }
      
      public function sendItemOverDue(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ITEM_OVERDUE);
         _loc3_.writeByte(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendHideLayer(param1:int, param2:Boolean) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ITEM_HIDE);
         _loc3_.writeBoolean(param2);
         _loc3_.writeInt(param1);
         this.sendPackage(_loc3_);
      }
      
      public function sendQuestAdd(param1:Array) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.QUEST_ADD);
         _loc2_.writeInt(param1.length);
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc2_.writeInt(param1[_loc3_]);
            _loc3_++;
         }
         this.sendPackage(_loc2_);
      }
      
      public function sendQuestRemove(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.QUEST_REMOVE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendQuestFinish(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.QUEST_FINISH);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendQuestCheck(param1:int, param2:int, param3:int = 1) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.QUEST_CHECK);
         _loc4_.writeInt(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendItemOpenUp(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ITEM_OPENUP);
         _loc3_.writeByte(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendItemEquip(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.ITEM_EQUIP);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendMateTime(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MATE_ONLINE_TIME);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendPlayerGift(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.USER_GET_GIFTS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendActivePullDown(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ACTIVE_PULLDOWN);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function auctionGood(param1:int, param2:int, param3:int, param4:int, param5:int, param6:int, param7:int) : void
      {
         var _loc8_:PackageOut = new PackageOut(ePackageType.AUCTION_ADD);
         _loc8_.writeByte(param1);
         _loc8_.writeInt(param2);
         _loc8_.writeByte(param3);
         _loc8_.writeInt(param4);
         _loc8_.writeInt(param5);
         _loc8_.writeInt(param6);
         _loc8_.writeInt(param7);
         this.sendPackage(_loc8_);
      }
      
      public function auctionCancelSell(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.AUCTION_DELETE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function auctionBid(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.AUCTION_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function syncStep(param1:int, param2:Boolean = true) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.USER_ANSWER);
         _loc3_.writeByte(1);
         _loc3_.writeInt(param1);
         _loc3_.writeBoolean(param2);
         this.sendPackage(_loc3_);
      }
      
      public function syncWeakStep(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.USER_ANSWER);
         _loc2_.writeByte(2);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendCreateConsortia(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_CREATE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaTryIn(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_TRYIN);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaCancelTryIn() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CONSORTIA_TRYIN);
         _loc1_.writeInt(0);
         this.sendPackage(_loc1_);
      }
      
      public function sendConsortiaInvate(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_INVITE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaInvatePass(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_INVITE_PASS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaInvateDelete(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_INVITE_DELETE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaUpdateDescription(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_DESCRIPTION_UPDATE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaUpdatePlacard(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_PLACARD_UPDATE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaUpdateDuty(param1:int, param2:String, param3:int) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.CONSORTIA_DUTY_UPDATE);
         _loc4_.writeInt(param1);
         _loc4_.writeByte(param1 == -1 ? 1 : 2);
         _loc4_.writeUTF(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendConsortiaUpgradeDuty(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_DUTY_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeByte(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendConsoritaApplyStatusOut(param1:Boolean) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_APPLY_STATE);
         _loc2_.writeBoolean(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaOut(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_RENEGADE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaMemberGrade(param1:int, param2:Boolean) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_USER_GRADE_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeBoolean(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendConsortiaUserRemarkUpdate(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_USER_REMARK_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendConsortiaDutyDelete(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_DUTY_DELETE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaTryinPass(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_TRYIN_PASS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaTryinDelete(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_TRYIN_DEL);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaAddApplyAlly(param1:int, param2:Boolean) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_ALLY_APPLY_ADD);
         _loc3_.writeInt(param1);
         _loc3_.writeBoolean(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendConsortiaRemoveApplyAlly(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_ALLY_APPLY_DELETE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaAddAlly(param1:int, param2:Boolean) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_ALLY_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeBoolean(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendForbidSpeak(param1:int, param2:Boolean) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_BANCHAT_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeBoolean(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendConsortiaDismiss() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CONSORTIA_DISBAND);
         this.sendPackage(_loc1_);
      }
      
      public function sendConsortiaChangeChairman(param1:String = "") : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_CHAIRMAN_CHAHGE);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaAllyApplyUpdate(param1:uint) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_ALLY_APPLY_UPDATE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaRichOffer(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CONSORTIA_RICHES_OFFER);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendConsortiaLevelUp(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CONSORTIA_LEVEL_UP);
         _loc3_.writeByte(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendConsortiaBankLevelUp() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CONSORTIA_STORE_UPGRADE);
         this.sendPackage(_loc1_);
      }
      
      public function sendConsortiaShopLevelUp() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CONSORTIA_SHOP_UPGRADE);
         this.sendPackage(_loc1_);
      }
      
      public function sendConsortiaSmithUp() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CONSORTIA_SMITH_UPGRADE);
         this.sendPackage(_loc1_);
      }
      
      public function sendAirPlane() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc1_.writeByte(CrazyTankPackageType.AIRPLANE);
         this.sendPackage(_loc1_);
      }
      
      public function useDeputyWeapon() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc1_.writeByte(CrazyTankPackageType.USE_DEPUTY_WEAPON);
         this.sendPackage(_loc1_);
      }
      
      public function sendGamePick(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc2_.writeByte(CrazyTankPackageType.PICK);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendPackage(param1:PackageOut) : void
      {
         this._socket.send(param1);
      }
      
      public function sendMoveGoods(param1:int, param2:int, param3:int, param4:int, param5:int = 1, param6:Boolean = false) : void
      {
         var _loc7_:PackageOut = new PackageOut(ePackageType.CHANGE_PLACE_GOODS);
         _loc7_.writeByte(param1);
         _loc7_.writeInt(param2);
         _loc7_.writeByte(param3);
         _loc7_.writeInt(param4);
         _loc7_.writeInt(param5);
         _loc7_.writeBoolean(param6);
         this.sendPackage(_loc7_);
      }
      
      public function reclaimGoods(param1:int, param2:int, param3:int = 1) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.REClAIM_GOODS);
         _loc4_.writeByte(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendMoveGoodsAll(param1:int, param2:Array, param3:int, param4:Boolean = false) : void
      {
         if(param2.length <= 0)
         {
            return;
         }
         var _loc5_:int = int(param2.length);
         var _loc6_:PackageOut = new PackageOut(ePackageType.CHANGE_PLACE_GOODS_ALL);
         _loc6_.writeBoolean(param4);
         _loc6_.writeInt(_loc5_);
         _loc6_.writeInt(param1);
         var _loc7_:int = 0;
         while(_loc7_ < _loc5_)
         {
            _loc6_.writeInt(param2[_loc7_].Place);
            _loc6_.writeInt(_loc7_ + param3);
            _loc7_++;
         }
         this.sendPackage(_loc6_);
      }
      
      public function sendForSwitch() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.ENTHRALL_SWITCH);
         this.sendPackage(_loc1_);
      }
      
      public function sendCIDCheck() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CID_CHECK);
         this.sendPackage(_loc1_);
      }
      
      public function sendCIDInfo(param1:String, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CID_CHECK);
         _loc3_.writeBoolean(false);
         _loc3_.writeUTF(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendChangeColor(param1:int, param2:int, param3:int, param4:int, param5:String, param6:String, param7:int) : void
      {
         var _loc8_:PackageOut = new PackageOut(ePackageType.USE_COLOR_CARD);
         _loc8_.writeInt(param1);
         _loc8_.writeInt(param2);
         _loc8_.writeInt(param3);
         _loc8_.writeInt(param4);
         _loc8_.writeUTF(param5);
         _loc8_.writeUTF(param6);
         _loc8_.writeInt(param7);
         this.sendPackage(_loc8_);
      }
      
      public function sendUseCard(param1:int, param2:int, param3:int, param4:int, param5:Boolean = false) : void
      {
         var _loc6_:PackageOut = new PackageOut(ePackageType.CARD_USE);
         _loc6_.writeInt(param1);
         _loc6_.writeInt(param2);
         _loc6_.writeInt(param3);
         _loc6_.writeInt(param4);
         _loc6_.writeBoolean(param5);
         this.sendPackage(_loc6_);
      }
      
      public function sendUseChangeColorShell(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.USE_CHANGE_COLOR_SHELL);
         _loc3_.writeByte(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendChangeColorShellTimeOver(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CHANGE_COLOR_OVER_DUE);
         _loc3_.writeByte(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendRouletteBox(param1:int, param2:int, param3:int = -1) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.LOTTERY_OPEN_BOX);
         _loc4_.writeByte(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendStartTurn() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.LOTTERY_RANDOM_SELECT);
         this.sendPackage(_loc1_);
      }
      
      public function sendFinishRoulette() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.LOTTERY_FINISH);
         this.sendPackage(_loc1_);
      }
      
      public function sendSellAll() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CADDY_SELL_ALL_GOODS);
         this.sendPackage(_loc1_);
      }
      
      public function sendOpenDead(param1:int, param2:int, param3:int) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.LOTTERY_OPEN_BOX);
         _loc4_.writeByte(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendRequestAwards(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CADDY_GET_AWARDS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendUseReworkName(param1:int, param2:int, param3:String) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.USE_REWORK_NAME);
         _loc4_.writeByte(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeUTF(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendUseConsortiaReworkName(param1:int, param2:int, param3:int, param4:String) : void
      {
         var _loc5_:PackageOut = new PackageOut(ePackageType.USE_CONSORTIA_REWORK_NAME);
         _loc5_.writeInt(param1);
         _loc5_.writeByte(param2);
         _loc5_.writeInt(param3);
         _loc5_.writeUTF(param4);
         this.sendPackage(_loc5_);
      }
      
      public function sendValidateMarry(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_STATUS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendPropose(param1:int, param2:String, param3:Boolean) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.MARRY_APPLY);
         _loc4_.writeInt(param1);
         _loc4_.writeUTF(param2);
         _loc4_.writeBoolean(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendProposeRespose(param1:Boolean, param2:int, param3:int) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.MARRY_APPLY_REPLY);
         _loc4_.writeBoolean(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendUnmarry(param1:Boolean = false) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.DIVORCE_APPLY);
         _loc2_.writeBoolean(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendMarryRoomLogin() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.MARRY_SCENE_LOGIN);
         this.sendPackage(_loc1_);
      }
      
      public function sendExitMarryRoom() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.SCENE_REMOVE_USER);
         this.sendPackage(_loc1_);
      }
      
      public function sendCreateRoom(param1:String, param2:String, param3:int, param4:int, param5:Boolean, param6:String) : void
      {
         var _loc7_:PackageOut = new PackageOut(ePackageType.MARRY_ROOM_CREATE);
         _loc7_.writeUTF(param1);
         _loc7_.writeUTF(param2);
         _loc7_.writeInt(param3);
         _loc7_.writeInt(param4);
         _loc7_.writeInt(100);
         _loc7_.writeBoolean(param5);
         _loc7_.writeUTF(param6);
         this.sendPackage(_loc7_);
      }
      
      public function sendEnterRoom(param1:int, param2:String, param3:int = 1) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.MARRY_ROOM_LOGIN);
         _loc4_.writeInt(param1);
         _loc4_.writeUTF(param2);
         _loc4_.writeInt(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendExitRoom() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.PLAYER_EXIT_MARRY_ROOM);
         this.sendPackage(_loc1_);
      }
      
      public function sendCurrentState(param1:uint) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.SCENE_STATE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendUpdateRoomList(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.ROOMLIST_UPDATE);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendChurchMove(param1:int, param2:int, param3:String) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc4_.writeByte(ChurchPackageType.MOVE);
         _loc4_.writeInt(param1);
         _loc4_.writeInt(param2);
         _loc4_.writeUTF(param3);
         this.sendPackage(_loc4_);
      }
      
      public function sendStartWedding() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc1_.writeByte(ChurchPackageType.HYMENEAL);
         this.sendPackage(_loc1_);
      }
      
      public function sendChurchContinuation(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc2_.writeByte(ChurchPackageType.CONTINUATION);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendChurchInvite(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc2_.writeByte(ChurchPackageType.INVITE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendChurchLargess(param1:uint) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc2_.writeByte(ChurchPackageType.LARGESS);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendUseFire(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc3_.writeByte(ChurchPackageType.USEFIRECRACKERS);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendChurchKick(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc2_.writeByte(ChurchPackageType.KICK);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendChurchMovieOver(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CHURCH_MOVIE_OVER);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendChurchForbid(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc2_.writeByte(ChurchPackageType.FORBID);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendPosition(param1:Number, param2:Number) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc3_.writeByte(ChurchPackageType.POSITION);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendModifyChurchDiscription(param1:String, param2:Boolean, param3:String, param4:String) : void
      {
         var _loc5_:PackageOut = new PackageOut(ePackageType.MARRY_ROOM_INFO_UPDATE);
         _loc5_.writeUTF(param1);
         _loc5_.writeBoolean(param2);
         _loc5_.writeUTF(param3);
         _loc5_.writeUTF(param4);
         this.sendPackage(_loc5_);
      }
      
      public function sendSceneChange(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRY_SCENE_CHANGE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendGunSalute(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.MARRY_CMD);
         _loc3_.writeByte(ChurchPackageType.GUNSALUTE);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendRegisterInfo(param1:int, param2:Boolean, param3:String = null) : void
      {
         var _loc4_:PackageOut = new PackageOut(ePackageType.MARRYINFO_ADD);
         _loc4_.writeBoolean(param2);
         _loc4_.writeUTF(param3);
         _loc4_.writeInt(param1);
         this.sendPackage(_loc4_);
      }
      
      public function sendModifyInfo(param1:Boolean, param2:String = null) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.MARRYINFO_UPDATE);
         _loc3_.writeBoolean(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendForMarryInfo(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.MARRYINFO_GET);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendGetLinkGoodsInfo(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.LINKREQUEST_GOODS);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendGetTropToBag(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GAME_TAKE_TEMP);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function createUserGuide(param1:int = 10) : void
      {
         var _loc2_:String = String(Math.random());
         var _loc3_:PackageOut = new PackageOut(ePackageType.GAME_ROOM_CREATE);
         _loc3_.writeByte(param1);
         _loc3_.writeByte(3);
         _loc3_.writeUTF("");
         _loc3_.writeUTF(_loc2_);
         this.sendPackage(_loc3_);
      }
      
      public function enterUserGuide(param1:int) : void
      {
         var _loc2_:int = 3;
         var _loc3_:PackageOut = new PackageOut(ePackageType.GAME_ROOM_SETUP_CHANGE);
         _loc3_.writeInt(param1);
         _loc3_.writeByte(10);
         _loc3_.writeByte(_loc2_);
         _loc3_.writeByte(0);
         _loc3_.writeInt(0);
         _loc3_.writeBoolean(false);
         this.sendPackage(_loc3_);
      }
      
      public function userGuideStart() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.GAME_START);
         this.sendPackage(_loc1_);
      }
      
      public function sendSaveDB() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.SAVE_DB);
         this.sendPackage(_loc1_);
      }
      
      public function createMonster() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc1_.writeByte(CrazyTankPackageType.GENERAL_COMMAND);
         _loc1_.writeInt(0);
         this.sendPackage(_loc1_);
      }
      
      public function deleteMonster() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.GAME_CMD);
         _loc1_.writeByte(CrazyTankPackageType.GENERAL_COMMAND);
         _loc1_.writeInt(1);
         this.sendPackage(_loc1_);
      }
      
      public function sendHotSpringEnter() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ENTER);
         this.sendPackage(_loc1_);
      }
      
      public function sendHotSpringRoomCreate(param1:*) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ROOM_CREATE);
         _loc2_.writeUTF(param1.roomName);
         _loc2_.writeUTF(param1.roomPassword);
         _loc2_.writeUTF(param1.roomIntroduction);
         _loc2_.writeInt(param1.maxCount);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomEdit(param1:*) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_CMD);
         _loc2_.writeByte(HotSpringPackageType.HOTSPRING_ROOM_EDIT);
         _loc2_.writeUTF(param1.roomName);
         _loc2_.writeUTF(param1.roomPassword);
         _loc2_.writeUTF(param1.roomIntroduction);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomQuickEnter() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ROOM_QUICK_ENTER);
         this.sendPackage(_loc1_);
      }
      
      public function sendHotSpringRoomEnterConfirm(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ROOM_ENTER_CONFIRM);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomEnter(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ROOM_ENTER);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendHotSpringRoomEnterView(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ROOM_ENTER_VIEW);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomPlayerRemove() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.HOTSPRING_ROOM_PLAYER_REMOVE);
         this.sendPackage(_loc1_);
      }
      
      public function sendHotSpringRoomPlayerTargetPoint(param1:*) : void
      {
         var _loc5_:uint = 0;
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_CMD);
         _loc2_.writeByte(HotSpringPackageType.TARGET_POINT);
         var _loc3_:Array = param1.walkPath.concat();
         var _loc4_:Array = [];
         while(_loc5_ < _loc3_.length)
         {
            _loc4_.push(int(_loc3_[_loc5_].x),int(_loc3_[_loc5_].y));
            _loc5_++;
         }
         var _loc6_:String = _loc4_.toString();
         _loc2_.writeUTF(_loc6_);
         _loc2_.writeInt(param1.playerInfo.ID);
         _loc2_.writeInt(param1.currentWalkStartPoint.x);
         _loc2_.writeInt(param1.currentWalkStartPoint.y);
         _loc2_.writeInt(1);
         _loc2_.writeInt(param1.playerDirection);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomRenewalFee(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_CMD);
         _loc2_.writeByte(HotSpringPackageType.HOTSPRING_ROOM_RENEWAL_FEE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomInvite(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_CMD);
         _loc2_.writeByte(HotSpringPackageType.HOTSPRING_ROOM_INVITE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomAdminRemovePlayer(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_CMD);
         _loc2_.writeByte(HotSpringPackageType.HOTSPRING_ROOM_ADMIN_REMOVE_PLAYER);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendHotSpringRoomPlayerContinue(param1:Boolean) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.HOTSPRING_CMD);
         _loc2_.writeByte(HotSpringPackageType.HOTSPRING_ROOM_PLAYER_CONTINUE);
         _loc2_.writeBoolean(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendGetTimeBox(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.GET_TIME_BOX);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendAchievementFinish(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.ACHIEVEMENT_FINISH);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendReworkRank(param1:String) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.USER_CHANGE_RANK);
         _loc2_.writeUTF(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendLookupEffort(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.LOOKUP_EFFORT);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendBeginFightNpc() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.FIGHT_NPC);
         this.sendPackage(_loc1_);
      }
      
      public function sendRequestUpdate() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.REQUEST_UPDATE);
         this.sendPackage(_loc1_);
      }
      
      public function sendQuestionReply(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.QUESTION_REPLY);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendOpenVip(param1:String, param2:int, param3:Boolean = false, param4:int = 0) : void
      {
         var _loc5_:PackageOut = new PackageOut(ePackageType.VIP_RENEWAL);
         _loc5_.writeUTF(param1);
         _loc5_.writeInt(param2);
         _loc5_.writeBoolean(param3);
         _loc5_.writeByte(param4);
         this.sendPackage(_loc5_);
      }
      
      public function sendAcademyRegister(param1:int, param2:Boolean, param3:String = null, param4:Boolean = false) : void
      {
         var _loc5_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         _loc5_.writeByte(AcademyPackageType.ACADEMY_REGISTER);
         _loc5_.writeInt(param1);
         _loc5_.writeBoolean(param2);
         _loc5_.writeUTF(param3);
         _loc5_.writeBoolean(param4);
         this.sendPackage(_loc5_);
      }
      
      public function sendAcademyRemoveRegister() : void
      {
         var _loc1_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         _loc1_.writeByte(AcademyPackageType.ACADEMY_REMOVE);
         this.sendPackage(_loc1_);
      }
      
      public function sendAcademyApprentice(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         _loc3_.writeByte(AcademyPackageType.ACADEMY_FOR_APPRENTICE);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendAcademyMaster(param1:int, param2:String) : void
      {
         var _loc3_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         _loc3_.writeByte(AcademyPackageType.ACADEMY_FOR_MASTER);
         _loc3_.writeInt(param1);
         _loc3_.writeUTF(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendAcademyMasterConfirm(param1:Boolean, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         if(param1)
         {
            _loc3_.writeByte(AcademyPackageType.MASTER_CONFIRM);
         }
         else
         {
            _loc3_.writeByte(AcademyPackageType.MASTER_REFUSE);
         }
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendAcademyApprenticeConfirm(param1:Boolean, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         if(param1)
         {
            _loc3_.writeByte(AcademyPackageType.APPRENTICE_CONFIRM);
         }
         else
         {
            _loc3_.writeByte(AcademyPackageType.APPRENTICE_REFUSE);
         }
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendAcademyFireMaster(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         _loc2_.writeByte(AcademyPackageType.FIRE_MASTER);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendAcademyFireApprentice(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(AcademyPackageType.ACADEMY_FATHER);
         _loc2_.writeByte(AcademyPackageType.FIRE_APPRENTICE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendUseLog(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.USE_LOG);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendBuyGift(param1:String, param2:int, param3:int, param4:int) : void
      {
         var _loc5_:PackageOut = new PackageOut(ePackageType.USER_SEND_GIFTS);
         _loc5_.writeUTF(param1);
         _loc5_.writeInt(param2);
         _loc5_.writeInt(param3);
         _loc5_.writeInt(param4);
         this.sendPackage(_loc5_);
      }
      
      public function sendReloadGift() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.USER_RELOAD_GIFT);
         this.sendPackage(_loc1_);
      }
      
      public function sendSnsMsg(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.SNS_MSG_RECEIVE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function getPlayerCardInfo(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.GET_PLAYER_CARD);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendMoveCards(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CARDS_DATA);
         _loc3_.writeInt(0);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendOpenViceCard(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CARDS_DATA);
         _loc2_.writeInt(1);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendOpenCardBox(param1:int, param2:int) : void
      {
         var _loc3_:PackageOut = new PackageOut(ePackageType.CARDS_DATA);
         _loc3_.writeInt(2);
         _loc3_.writeInt(param1);
         _loc3_.writeInt(param2);
         this.sendPackage(_loc3_);
      }
      
      public function sendUpGradeCard(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CARDS_DATA);
         _loc2_.writeInt(3);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendCardReset(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CARD_RESET);
         _loc2_.writeInt(0);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendReplaceCardProp(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.CARD_RESET);
         _loc2_.writeInt(1);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
      
      public function sendSortCards(param1:Vector.<int>) : void
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:PackageOut = new PackageOut(ePackageType.CARDS_DATA);
         _loc2_.writeInt(4);
         var _loc3_:int = int(param1.length);
         _loc2_.writeInt(_loc3_);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc5_ = param1[_loc4_];
            _loc6_ = _loc4_ + CardModel.EQUIP_CELLS_SUM;
            _loc2_.writeInt(_loc5_);
            _loc2_.writeInt(_loc6_);
            _loc4_++;
         }
         this.sendPackage(_loc2_);
      }
      
      public function sendFirstGetCards() : void
      {
         var _loc1_:PackageOut = new PackageOut(ePackageType.CARDS_DATA);
         _loc1_.writeInt(5);
         this.sendPackage(_loc1_);
      }
      
      public function sendFace(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.SCENE_FACE);
         _loc2_.writeInt(param1);
         _loc2_.writeInt(0);
         this.sendPackage(_loc2_);
      }
      
      public function sendOpition(param1:int) : void
      {
         var _loc2_:PackageOut = new PackageOut(ePackageType.OPTION_UPDATE);
         _loc2_.writeInt(param1);
         this.sendPackage(_loc2_);
      }
   }
}

