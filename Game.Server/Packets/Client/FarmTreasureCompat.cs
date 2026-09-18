using System;
using System.Collections.Generic;
using System.Linq;
using Bussiness;
using Bussiness.Managers;
using Game.Base.Packets;
using SqlDataProvider.Data;

namespace Game.Server.Packets.Client
{
    internal static class FarmTreasureCompat
    {
        private const byte FarmEnter = 1;
        private const byte FarmGrow = 2;
        private const byte FarmGain = 4;
        private const byte FarmKill = 7;
        private const byte FarmExit = 16;
        private static readonly object TreasureSync = new object();
        private static readonly HashSet<int> TreasureSessions = new HashSet<int>();
        private static readonly Random TreasureRandom = new Random();

        public static bool TryHandleFarm(GameClient client, GSPacketIn packet)
        {
            if (client == null || client.Player == null || packet == null || packet.DataLeft < 1)
                return false;
            int offset = packet.Offset;
            int payloadLength = packet.DataLeft;
            byte command = packet.ReadByte();
            packet.Offset = offset;
            bool isFarm = command == FarmGrow || command == FarmGain || command == FarmKill || command == FarmExit ||
                          (command == FarmEnter && payloadLength == 5);
            if (!isFarm)
                return false;

            switch (command)
            {
                case FarmEnter:
                    HandleFarmEnter(client, packet);
                    break;
                case FarmGrow:
                    HandleFarmGrow(client, packet);
                    break;
                case FarmGain:
                    HandleFarmGain(client, packet);
                    break;
                case FarmKill:
                    HandleFarmKill(client, packet);
                    break;
                case FarmExit:
                    packet.ReadByte();
                    break;
            }
            return true;
        }

        private static void EnsureDefaultFields(PlayerBussiness db, int userId)
        {
            UserFieldInfo[] existing = db.GetSingleFields(userId);
            if (existing != null && existing.Length > 0)
                return;
            DateTime now = DateTime.Now;
            for (int i = 0; i < 8; i++)
            {
                UserFieldInfo field = new UserFieldInfo();
                field.FarmID = userId;
                field.FieldID = i;
                field.SeedID = 0;
                field.PlantTime = now;
                field.AccelerateTime = 0;
                field.FieldValidDate = 1;
                field.PayTime = now.AddYears(100);
                field.GainCount = 0;
                field.AutoSeedID = 0;
                field.AutoFertilizerID = 0;
                field.AutoSeedIDCount = 0;
                field.AutoFertilizerCount = 0;
                field.isAutomatic = false;
                field.AutomaticTime = now;
                field.IsExit = true;
                field.payFieldTime = 876000;
                db.AddFields(field);
            }
        }

        private static UserFieldInfo FindField(UserFieldInfo[] fields, int fieldId)
        {
            if (fields == null)
                return null;
            foreach (UserFieldInfo field in fields)
                if (field != null && field.FieldID == fieldId)
                    return field;
            return null;
        }

        private static void HandleFarmEnter(GameClient client, GSPacketIn packet)
        {
            packet.ReadByte();
            int userId = packet.ReadInt();
            using (PlayerBussiness db = new PlayerBussiness())
            {
                if (userId == client.Player.PlayerCharacter.ID)
                    EnsureDefaultFields(db, userId);
                UserFieldInfo[] fields = db.GetSingleFields(userId) ?? new UserFieldInfo[0];
                GSPacketIn response = new GSPacketIn(81, client.Player.PlayerCharacter.ID);
                response.WriteByte(FarmEnter);
                response.WriteInt(userId);
                response.WriteBoolean(false);
                response.WriteInt(0);
                response.WriteDateTime(DateTime.Now);
                response.WriteInt(0);
                response.WriteInt(0);
                response.WriteInt(0);
                response.WriteInt(fields.Length);
                foreach (UserFieldInfo field in fields)
                {
                    response.WriteInt(field.FieldID);
                    response.WriteInt(field.SeedID);
                    response.WriteDateTime(field.PayTime);
                    response.WriteDateTime(field.PlantTime);
                    response.WriteInt(field.GainCount);
                    response.WriteInt(field.FieldValidDate);
                    response.WriteInt(field.AccelerateTime);
                }
                if (userId == client.Player.PlayerCharacter.ID)
                {
                    response.WriteInt(5000);
                    response.WriteString("168,50|720,150");
                    response.WriteString("168,100|720,300");
                    response.WriteDateTime(DateTime.Now);
                    response.WriteInt(0);
                    response.WriteInt(0);
                    response.WriteInt(20);
                }
                else
                {
                    response.WriteBoolean(false);
                }
                client.Player.SendTCP(response);
            }
        }

        private static void HandleFarmGrow(GameClient client, GSPacketIn packet)
        {
            packet.ReadByte();
            if (packet.DataLeft < 9)
                return;
            packet.ReadByte();
            int templateId = packet.ReadInt();
            int fieldId = packet.ReadInt();
            if (fieldId < 0 || fieldId > 15)
                return;
            ItemTemplateInfo seed = ItemMgr.FindItemTemplate(templateId);
            if (seed == null || seed.CategoryID != 32 || client.Player.GetItemCount(templateId) < 1)
                return;

            lock (client.Player)
            {
                using (PlayerBussiness db = new PlayerBussiness())
                {
                    EnsureDefaultFields(db, client.Player.PlayerCharacter.ID);
                    UserFieldInfo field = FindField(db.GetSingleFields(client.Player.PlayerCharacter.ID), fieldId);
                    if (field == null || field.SeedID != 0 || !field.IsValidField())
                        return;
                    int oldSeed = field.SeedID;
                    DateTime oldPlant = field.PlantTime;
                    int oldAccelerate = field.AccelerateTime;
                    int oldValid = field.FieldValidDate;
                    int oldGain = field.GainCount;

                    field.SeedID = templateId;
                    field.PlantTime = DateTime.Now;
                    field.AccelerateTime = 0;
                    field.FieldValidDate = Math.Max(1, seed.Property3);
                    field.GainCount = Math.Max(1, seed.Property2);
                    if (!db.UpdateFields(field))
                        return;
                    if (!client.Player.RemoveTemplate(templateId, 1))
                    {
                        field.SeedID = oldSeed;
                        field.PlantTime = oldPlant;
                        field.AccelerateTime = oldAccelerate;
                        field.FieldValidDate = oldValid;
                        field.GainCount = oldGain;
                        db.UpdateFields(field);
                        return;
                    }

                    GSPacketIn response = new GSPacketIn(81, client.Player.PlayerCharacter.ID);
                    response.WriteByte(FarmGrow);
                    response.WriteInt(field.FieldID);
                    response.WriteInt(field.SeedID);
                    response.WriteDateTime(field.PlantTime);
                    response.WriteDateTime(field.PayTime);
                    response.WriteInt(field.GainCount);
                    response.WriteInt(field.FieldValidDate);
                    client.Player.SendTCP(response);
                }
            }
        }

        private static bool IsMature(UserFieldInfo field)
        {
            if (field == null || field.SeedID == 0)
                return false;
            int used = (int)(DateTime.Now - field.PlantTime).TotalMinutes + field.AccelerateTime;
            return used >= field.FieldValidDate;
        }

        private static void ResetField(UserFieldInfo field)
        {
            field.SeedID = 0;
            field.PlantTime = DateTime.Now;
            field.AccelerateTime = 0;
            field.FieldValidDate = 1;
            field.GainCount = 0;
        }

        private static void HandleFarmGain(GameClient client, GSPacketIn packet)
        {
            packet.ReadByte();
            if (packet.DataLeft < 8)
                return;
            int userId = packet.ReadInt();
            int fieldId = packet.ReadInt();
            if (userId != client.Player.PlayerCharacter.ID)
                return;
            lock (client.Player)
            {
                using (PlayerBussiness db = new PlayerBussiness())
                {
                    UserFieldInfo field = FindField(db.GetSingleFields(userId), fieldId);
                    if (!IsMature(field))
                        return;
                    ItemTemplateInfo seed = ItemMgr.FindItemTemplate(field.SeedID);
                    ItemTemplateInfo food = seed == null ? null : ItemMgr.FindItemTemplate(seed.Property4);
                    if (seed == null || food == null)
                        return;
                    int oldSeed = field.SeedID;
                    DateTime oldPlant = field.PlantTime;
                    int oldAccelerate = field.AccelerateTime;
                    int oldValid = field.FieldValidDate;
                    int oldGain = field.GainCount;
                    ItemInfo reward = ItemInfo.CreateFromTemplate(food, Math.Max(1, field.GainCount), 102);
                    if (reward == null)
                        return;
                    reward.IsBinds = true;

                    ResetField(field);
                    if (!db.UpdateFields(field))
                        return;
                    if (!client.Player.AddTemplate(reward, food.BagType, reward.Count))
                    {
                        field.SeedID = oldSeed;
                        field.PlantTime = oldPlant;
                        field.AccelerateTime = oldAccelerate;
                        field.FieldValidDate = oldValid;
                        field.GainCount = oldGain;
                        db.UpdateFields(field);
                        return;
                    }
                    GSPacketIn response = new GSPacketIn(81, userId);
                    response.WriteByte(FarmGain);
                    response.WriteBoolean(true);
                    response.WriteInt(field.FieldID);
                    response.WriteInt(field.SeedID);
                    response.WriteDateTime(field.PlantTime);
                    response.WriteInt(field.GainCount);
                    response.WriteInt(field.AccelerateTime);
                    client.Player.SendTCP(response);
                }
            }
        }

        private static void HandleFarmKill(GameClient client, GSPacketIn packet)
        {
            packet.ReadByte();
            if (packet.DataLeft < 4)
                return;
            int fieldId = packet.ReadInt();
            using (PlayerBussiness db = new PlayerBussiness())
            {
                UserFieldInfo field = FindField(db.GetSingleFields(client.Player.PlayerCharacter.ID), fieldId);
                if (field == null)
                    return;
                ResetField(field);
                if (!db.UpdateFields(field))
                    return;
                GSPacketIn response = new GSPacketIn(81, client.Player.PlayerCharacter.ID);
                response.WriteByte(FarmKill);
                response.WriteBoolean(true);
                response.WriteInt(field.FieldID);
                response.WriteInt(field.SeedID);
                response.WriteInt(field.AccelerateTime);
                client.Player.SendTCP(response);
            }
        }

        public static bool TryHandleTreasure(GameClient client, GSPacketIn packet)
        {
            if (client == null || client.Player == null || packet == null || packet.DataLeft < 4)
                return false;
            int offset = packet.Offset;
            int payloadLength = packet.DataLeft;
            int command = packet.ReadInt();
            packet.Offset = offset;
            int userId = client.Player.PlayerCharacter.ID;
            bool session;
            lock (TreasureSync)
                session = TreasureSessions.Contains(userId);
            bool isTreasure = command == 0 ||
                              ((command == 1 || command == 3) && payloadLength >= 8) ||
                              ((command == 2 || command == 6) && session);
            if (!isTreasure)
                return false;

            packet.ReadInt();
            switch (command)
            {
                case 0:
                    HandleTreasureEnter(client);
                    break;
                case 1:
                    HandleTreasureHelp(client, packet);
                    break;
                case 2:
                    HandleTreasureEnd(client);
                    break;
                case 3:
                    HandleTreasureDig(client, packet);
                    break;
                case 6:
                    HandleTreasureStart(client);
                    break;
            }
            return true;
        }

        private static UserTreasureInfo CreateTreasureState(GameClient client)
        {
            UserTreasureInfo state = new UserTreasureInfo();
            state.ID = 0;
            state.UserID = client.Player.PlayerCharacter.ID;
            state.NickName = client.Player.PlayerCharacter.NickName;
            state.logoinDays = 1;
            state.treasure = 1;
            state.treasureAdd = 0;
            state.friendHelpTimes = 0;
            state.isEndTreasure = false;
            state.isBeginTreasure = false;
            state.LastLoginDay = DateTime.Now;
            return state;
        }

        private static void SaveTreasureState(PlayerBussiness db, UserTreasureInfo state)
        {
            if (state.ID > 0)
                db.UpdateUserTreasureInfo(state);
            else
                db.AddUserTreasureInfo(state);
        }

        private static List<TreasureDataInfo> CreateTreasureBoard(PlayerBussiness db, int userId)
        {
            TreasureAwardInfo[] awards = db.GetAllTreasureAward();
            List<TreasureDataInfo> result = new List<TreasureDataInfo>();
            if (awards == null || awards.Length == 0)
                return result;
            HashSet<int> used = new HashSet<int>();
            int target = Math.Min(16, awards.Select(x => x.TemplateID).Distinct().Count());
            int attempts = 0;
            while (result.Count < target && attempts++ < 4096)
            {
                TreasureAwardInfo award;
                lock (TreasureSync)
                    award = awards[TreasureRandom.Next(awards.Length)];
                if (award == null || !used.Add(award.TemplateID))
                    continue;
                TreasureDataInfo item = new TreasureDataInfo();
                item.ID = 0;
                item.UserID = userId;
                item.TemplateID = award.TemplateID;
                item.Count = Math.Max(1, award.Count);
                item.ValidDate = award.Validate;
                item.pos = -1;
                item.BeginDate = DateTime.Now;
                item.IsExit = true;
                result.Add(item);
            }
            return result;
        }

        private static void HandleTreasureEnter(GameClient client)
        {
            int userId = client.Player.PlayerCharacter.ID;
            using (PlayerBussiness db = new PlayerBussiness())
            {
                UserTreasureInfo state = db.GetSingleTreasure(userId);
                bool freshState = state == null;
                if (freshState)
                    state = CreateTreasureState(client);
                List<TreasureDataInfo> data = db.GetSingleTreasureData(userId) ?? new List<TreasureDataInfo>();
                bool newDay = !freshState && state.LastLoginDay.Date < DateTime.Now.Date;
                if (data.Count == 0 || newDay)
                {
                    foreach (TreasureDataInfo old in data)
                    {
                        old.IsExit = false;
                        db.UpdateTreasureData(old);
                    }
                    data = CreateTreasureBoard(db, userId);
                    foreach (TreasureDataInfo item in data)
                        db.AddTreasureData(item);
                }
                if (newDay)
                {
                    if ((int)(DateTime.Now - state.LastLoginDay).TotalDays > 1)
                        state.logoinDays = 0;
                    state.logoinDays++;
                    state.treasure = Math.Min(3, state.logoinDays);
                    state.treasureAdd = 0;
                    state.friendHelpTimes = 0;
                    state.isBeginTreasure = false;
                    state.isEndTreasure = false;
                    state.LastLoginDay = DateTime.Now;
                }
                SaveTreasureState(db, state);
                lock (TreasureSync)
                    TreasureSessions.Add(userId);

                GSPacketIn response = new GSPacketIn(135, userId);
                response.WriteInt(0);
                response.WriteInt(state.logoinDays);
                response.WriteInt(state.treasure);
                response.WriteInt(state.treasureAdd);
                response.WriteInt(state.friendHelpTimes);
                response.WriteBoolean(state.isEndTreasure);
                response.WriteBoolean(state.isBeginTreasure);
                response.WriteInt(data.Count);
                foreach (TreasureDataInfo item in data)
                {
                    response.WriteInt(item.TemplateID);
                    response.WriteInt(item.ValidDate);
                    response.WriteInt(item.Count);
                }
                List<TreasureDataInfo> dug = data.FindAll(x => x != null && x.pos > 0);
                response.WriteInt(dug.Count);
                foreach (TreasureDataInfo item in dug)
                {
                    response.WriteInt(item.TemplateID);
                    response.WriteInt(item.pos);
                    response.WriteInt(item.ValidDate);
                    response.WriteInt(item.Count);
                }
                client.Player.SendTCP(response);
            }
        }

        private static void HandleTreasureStart(GameClient client)
        {
            using (PlayerBussiness db = new PlayerBussiness())
            {
                UserTreasureInfo state = db.GetSingleTreasure(client.Player.PlayerCharacter.ID);
                if (state == null)
                    state = CreateTreasureState(client);
                state.isBeginTreasure = true;
                SaveTreasureState(db, state);
                GSPacketIn response = new GSPacketIn(135, client.Player.PlayerCharacter.ID);
                response.WriteInt(6);
                response.WriteBoolean(true);
                client.Player.SendTCP(response);
            }
        }

        private static void HandleTreasureEnd(GameClient client)
        {
            int userId = client.Player.PlayerCharacter.ID;
            using (PlayerBussiness db = new PlayerBussiness())
            {
                UserTreasureInfo state = db.GetSingleTreasure(userId);
                if (state == null)
                    state = CreateTreasureState(client);
                state.isBeginTreasure = false;
                state.isEndTreasure = true;
                SaveTreasureState(db, state);
            }
            lock (TreasureSync)
                TreasureSessions.Remove(userId);
            GSPacketIn response = new GSPacketIn(135, userId);
            response.WriteInt(2);
            response.WriteBoolean(true);
            client.Player.SendTCP(response);
        }

        private static void HandleTreasureHelp(GameClient client, GSPacketIn packet)
        {
            if (packet.DataLeft >= 4)
                packet.ReadInt();
            GSPacketIn response = new GSPacketIn(135, client.Player.PlayerCharacter.ID);
            response.WriteInt(1);
            response.WriteInt(0);
            client.Player.SendTCP(response);
        }

        private static void HandleTreasureDig(GameClient client, GSPacketIn packet)
        {
            if (packet.DataLeft < 4)
                return;
            int position = packet.ReadInt();
            int userId = client.Player.PlayerCharacter.ID;
            using (PlayerBussiness db = new PlayerBussiness())
            {
                UserTreasureInfo state = db.GetSingleTreasure(userId);
                List<TreasureDataInfo> data = db.GetSingleTreasureData(userId);
                if (state == null || data == null || position < 1 || position > data.Count)
                    return;
                TreasureDataInfo reward = data[position - 1];
                if (reward == null || reward.pos > 0)
                    return;
                ItemTemplateInfo template = ItemMgr.FindItemTemplate(reward.TemplateID);
                if (template == null || (state.treasure <= 0 && state.treasureAdd <= 0))
                    return;

                int oldTreasure = state.treasure;
                int oldTreasureAdd = state.treasureAdd;
                int oldPos = reward.pos;
                if (state.treasure > 0)
                    state.treasure--;
                else
                    state.treasureAdd--;
                reward.pos = position;
                bool stateSaved = db.UpdateUserTreasureInfo(state);
                bool dataSaved = db.UpdateTreasureData(reward);
                if (!stateSaved || !dataSaved)
                {
                    state.treasure = oldTreasure;
                    state.treasureAdd = oldTreasureAdd;
                    reward.pos = oldPos;
                    db.UpdateUserTreasureInfo(state);
                    db.UpdateTreasureData(reward);
                    return;
                }

                ItemInfo item = ItemInfo.CreateFromTemplate(template, Math.Max(1, reward.Count), 105);
                if (item == null)
                    return;
                item.IsBinds = true;
                item.ValidDate = reward.ValidDate;
                if (!client.Player.AddTemplate(item, template.BagType, item.Count))
                {
                    state.treasure = oldTreasure;
                    state.treasureAdd = oldTreasureAdd;
                    reward.pos = oldPos;
                    db.UpdateUserTreasureInfo(state);
                    db.UpdateTreasureData(reward);
                    return;
                }

                GSPacketIn response = new GSPacketIn(135, userId);
                response.WriteInt(3);
                response.WriteInt(reward.TemplateID);
                response.WriteInt(position);
                response.WriteInt(reward.Count);
                response.WriteInt(state.treasure);
                response.WriteInt(state.treasureAdd);
                client.Player.SendTCP(response);
            }
        }
    }
}
