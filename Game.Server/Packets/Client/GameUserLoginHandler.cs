using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Game.Base.Packets;
using Game.Server.GameObjects;
using Game.Server.Managers;
using Bussiness;
using Game.Server.Rooms;
using Game.Server.GameUtils;
using Bussiness.Managers;
using SqlDataProvider.Data;

namespace Game.Server.Packets.Client
{
    [PacketHandler((int)ePackageType.GAME_ROOM_LOGIN, "进入游戏")]
    public class GameUserLoginHandler : IPacketHandler
    {
       

        public int HandlePacket(GameClient client, GSPacketIn packet)
        {
            //type可能的值为 -2, -1, 1, 3, 4
            //当type = 1, 3, 4时,分别指快速加入组队战,Boss战,夺宝战
            //当type = -1时,房间ID为所点的房间ID，无密码时也传空字符串
            //当type = -2时,表示PVE游戏中的邀请
            byte firstByte = packet.ReadByte();
            if (firstByte == 2)
            {
                return HandleFarmGrow(client, packet);
            }

            bool isInvite = firstByte != 0;
            int type = packet.ReadInt();
            int isRoundID = packet.ReadInt();
            int roomId = -1;
            string pwd = null;
          
            if (isRoundID==-1)
            {
                roomId = packet.ReadInt();
                pwd = packet.ReadString();
            }
            if (type == 1) type = 0;
            else if (type == 2) type = 4;
            //string pwd = null;
            //switch (type)
            //{
            //    case -1:
            //        roomId = packet.ReadInt();
            //        pwd = packet.ReadString();
            //        break;
            //    default:
            //        break;
            //}
           
            //TrieuLSL
            //GSPacketIn pkg2 = new GSPacketIn((byte)ePackageType.SYS_NOTICE);
            //pkg2.WriteInt(1);
            //pkg2.WriteString("Bạn đang sử dụng gunny phiên bản do smallwind1912 phát triển mọi thắc mắc xin liên hệ smallwind1912@gmail.com hoặc truy cập wohzoo.com ");
            //client.Out.SendTCP(pkg2);
            RoomMgr.EnterRoom(client.Player, roomId, pwd, type);

            return 0;
        }
        private int HandleFarmGrow(GameClient client, GSPacketIn packet)
        {
            packet.ReadByte(); // legacy farm bag type (13)
            int templateID = packet.ReadInt();
            int fieldID = packet.ReadInt();

            ItemTemplateInfo seedTemplate = ItemMgr.FindItemTemplate(templateID);
            if (seedTemplate == null || fieldID < 0)
                return 0;

            UserFieldInfo field = null;
            using (PlayerBussiness db = new PlayerBussiness())
            {
                UserFieldInfo[] fields = db.GetSingleFields(client.Player.PlayerCharacter.ID);
                for (int i = 0; i < fields.Length; i++)
                {
                    if (fields[i] != null && fields[i].FieldID == fieldID)
                    {
                        field = fields[i];
                        break;
                    }
                }
            }

            if (field == null || field.SeedID != 0 || !field.IsValidField())
                return 0;

            PlayerInventory farmBag = new PlayerInventory(client.Player, true, 30, 13, 0, true);
            farmBag.LoadFromDatabase();
            if (farmBag.GetItemCount(templateID) <= 0)
                return 0;

            int oldSeedID = field.SeedID;
            DateTime oldPlantTime = field.PlantTime;
            int oldGainCount = field.GainCount;
            int oldValidDate = field.FieldValidDate;
            int oldAccelerate = field.AccelerateTime;

            field.SeedID = seedTemplate.TemplateID;
            field.PlantTime = DateTime.Now;
            field.GainCount = seedTemplate.Property2;
            field.FieldValidDate = seedTemplate.Property3;
            field.AccelerateTime = 0;

            bool saved;
            using (PlayerBussiness db = new PlayerBussiness())
            {
                saved = db.UpdateFields(field);
            }
            if (!saved)
                return 0;

            if (!farmBag.RemoveTemplate(templateID, 1))
            {
                field.SeedID = oldSeedID;
                field.PlantTime = oldPlantTime;
                field.GainCount = oldGainCount;
                field.FieldValidDate = oldValidDate;
                field.AccelerateTime = oldAccelerate;
                using (PlayerBussiness db = new PlayerBussiness())
                    db.UpdateFields(field);
                return 0;
            }
            farmBag.SaveToDatabase();

            GSPacketIn response = new GSPacketIn((byte)ePackageType.GAME_ROOM_LOGIN, client.Player.PlayerCharacter.ID);
            response.WriteByte(2);
            response.WriteInt(field.FieldID);
            response.WriteInt(field.SeedID);
            response.WriteDateTime(field.PlantTime);
            response.WriteDateTime(field.PayTime);
            response.WriteInt(field.GainCount);
            response.WriteInt(field.FieldValidDate);
            client.Out.SendTCP(response);
            return 0;
        }

    }
}
