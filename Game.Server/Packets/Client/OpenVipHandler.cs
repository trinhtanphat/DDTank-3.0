using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Bussiness.Managers;
using Game.Base.Packets;
using Game.Server.GameObjects;
using SqlDataProvider.Data;

namespace Game.Server.Packets.Client
{
    [PacketHandler((byte)ePackageType.VIP_RENEWAL, "VIP activation / renewal")]
    public class OpenVipHandler : IPacketHandler
    {
        private const int VipTemplateId = 11992;
        private const byte PayWithXu = 0;
        private const byte PayWithGold = 1;
        private const int GoldPerXu = 1000;
        private const int MaxVipLevel = 20;

        private static readonly int[] VipExpFloors = new int[]
        {
            0, 200, 400, 800, 2000, 4000, 8000, 20000, 40000, 80000,
            200000, 400000, 800000, 1200000, 1800000, 2600000, 3600000,
            4800000, 6200000, 7800000
        };

        public int HandlePacket(GameClient client, GSPacketIn packet)
        {
            if (client == null || client.Player == null) return 0;

            string requestedNickName = packet.ReadString();
            int renewalDays = packet.ReadInt();

            // Legacy Flash clients append an isBand boolean as the third field.
            // Keep it on the wire and only treat an optional fourth byte as
            // the explicit Xu/Gold payment mode.
            bool legacyIsBand = packet.DataLeft > 0 ? packet.ReadBoolean() : false;
            byte paymentMode = packet.DataLeft > 0 ? packet.ReadByte() : PayWithXu;

            if (!String.Equals(requestedNickName, client.Player.PlayerCharacter.NickName,
                StringComparison.OrdinalIgnoreCase))
            {
                client.Out.SendMessage(eMessageType.Normal, "Yeu cau VIP khong hop le.");
                return 0;
            }

            if (paymentMode != PayWithXu && paymentMode != PayWithGold)
            {
                client.Out.SendMessage(eMessageType.Normal, "Phuong thuc thanh toan VIP khong hop le.");
                return 0;
            }

            int xuPrice = GetRenewalPrice(renewalDays);
            if (xuPrice <= 0)
            {
                client.Out.SendMessage(eMessageType.Normal, "Thoi han VIP khong hop le.");
                return 0;
            }

            long requestedCharge = paymentMode == PayWithGold
                ? (long)xuPrice * GoldPerXu
                : xuPrice;
            if (requestedCharge <= 0 || requestedCharge > Int32.MaxValue)
            {
                client.Out.SendMessage(eMessageType.Normal, "Gia VIP vuot gioi han.");
                return 0;
            }

            int charge = (int)requestedCharge;
            if (paymentMode == PayWithGold)
            {
                if (client.Player.PlayerCharacter.Gold < charge)
                {
                    client.Out.SendMessage(eMessageType.Normal, "Khong du Vang.");
                    return 0;
                }
            }
            else if (client.Player.PlayerCharacter.Money < charge)
            {
                client.Out.SendMessage(eMessageType.Normal, "Khong du Xu.");
                return 0;
            }

            string connectionString = GetConnectionString();
            if (String.IsNullOrEmpty(connectionString))
            {
                client.Out.SendMessage(eMessageType.ERROR, "Cau hinh CSDL VIP khong hop le.");
                return 0;
            }

            VipState state;
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    if (!VipSchemaReady(connection))
                    {
                        client.Out.SendMessage(eMessageType.ERROR, "CSDL chua duoc cap nhat VIP20.");
                        return 0;
                    }

                    using (SqlTransaction transaction = connection.BeginTransaction(IsolationLevel.Serializable))
                    {
                        if (!ChargeCurrency(connection, transaction, client.Player.PlayerCharacter.ID,
                            paymentMode, charge))
                        {
                            transaction.Rollback();
                            client.Out.SendMessage(eMessageType.Normal,
                                paymentMode == PayWithGold ? "Khong du Vang." : "Khong du Xu.");
                            return 0;
                        }

                        DateTime expireDay;
                        int renewalResult = RenewVip(connection, transaction,
                            client.Player.PlayerCharacter.ID, renewalDays, out expireDay);
                        if (renewalResult != 1)
                        {
                            transaction.Rollback();
                            client.Out.SendMessage(eMessageType.ERROR, "Khong the gia han VIP.");
                            return 0;
                        }

                        state = LoadVipState(connection, transaction, client.Player.PlayerCharacter.ID, true);
                        if (state == null)
                        {
                            transaction.Rollback();
                            client.Out.SendMessage(eMessageType.ERROR, "Khong doc duoc du lieu VIP.");
                            return 0;
                        }

                        state.TypeVip = Math.Max(1, state.TypeVip);
                        state.ExpireDay = expireDay;
                        state.Exp = Math.Min(VipExpFloors[MaxVipLevel - 1],
                            Math.Max(state.Exp, GetVipFloor(state.Level)) + renewalDays * 10);
                        state.Level = GetLevelForExp(state.Exp);
                        state.NextLevelDays = GetNextLevelDays(state.Level, state.Exp);
                        state.LastDate = DateTime.Now;
                        state.CanTakeReward = true;

                        SaveVipState(connection, transaction, client.Player.PlayerCharacter.ID, state);
                        transaction.Commit();
                    }
                }
            }
            catch (Exception ex)
            {
                client.Out.SendMessage(eMessageType.ERROR, "Gia han VIP that bai. Giao dich khong duoc ghi nhan.");
                System.Diagnostics.Trace.WriteLine(ex.ToString());
                return 0;
            }

            if (paymentMode == PayWithGold)
                client.Player.RemoveGold(charge);
            else
                client.Player.RemoveMoney(charge);

            SendVipState(client, state);
            client.Out.SendMessage(eMessageType.Normal,
                "Gia han VIP thanh cong. VIP hien tai: " + state.Level + ".");
            return 1;
        }

        private static string GetConnectionString()
        {
            string value = ConfigurationManager.AppSettings["conString"];
            if (!String.IsNullOrEmpty(value)) return value;
            ConnectionStringSettings settings = ConfigurationManager.ConnectionStrings["Db_TankConnectionString"];
            return settings == null ? null : settings.ConnectionString;
        }

        private static bool VipSchemaReady(SqlConnection connection)
        {
            using (SqlCommand command = new SqlCommand(
                "SELECT CASE WHEN OBJECT_ID('dbo.Sys_VIP_Info','U') IS NOT NULL " +
                "AND OBJECT_ID('dbo.SP_VIPRenewal_Single','P') IS NOT NULL THEN 1 ELSE 0 END",
                connection))
            {
                return Convert.ToInt32(command.ExecuteScalar()) == 1;
            }
        }

        private static int GetRenewalPrice(int renewalDays)
        {
            ShopItemInfo item = ShopMgr.FindShopbyTemplatID(VipTemplateId).FirstOrDefault();
            int oneMonth = 399;
            int threeMonths = 1197;
            int oneYear = 4200;

            if (item != null)
            {
                if (item.AUnit == 31 && item.AValue1 > 0) oneMonth = item.AValue1;
                if (item.BUnit == 93 && item.BValue1 > 0) threeMonths = item.BValue1;
                if (item.CUnit == 365 && item.CValue1 > 0) oneYear = item.CValue1;
            }

            // Accept both legacy Flash durations (30/90/180) and newer 31-day bundles.
            if (renewalDays == 30 || renewalDays == 31) return oneMonth;
            if (renewalDays == 90 || renewalDays == 93) return threeMonths;
            if (renewalDays == 180 || renewalDays == 186) return oneMonth * 6;
            if (renewalDays == 365) return oneYear;
            if (renewalDays == 730) return checked(oneYear * 2);

            if (renewalDays > 0 && renewalDays % 31 == 0)
            {
                int months = renewalDays / 31;
                if (months >= 1 && months <= 24) return oneMonth * months;
            }
            return 0;
        }

        private static bool ChargeCurrency(SqlConnection connection, SqlTransaction transaction,
            int userId, byte paymentMode, int charge)
        {
            string column = paymentMode == PayWithGold ? "Gold" : "Money";
            using (SqlCommand command = new SqlCommand(
                "UPDATE dbo.Sys_Users_Detail SET " + column + "=" + column + "-@Charge " +
                "WHERE UserID=@UserID AND " + column + ">=@Charge",
                connection, transaction))
            {
                command.Parameters.Add("@Charge", SqlDbType.Int).Value = charge;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                return command.ExecuteNonQuery() == 1;
            }
        }

        private static int RenewVip(SqlConnection connection, SqlTransaction transaction,
            int userId, int renewalDays, out DateTime expireDay)
        {
            using (SqlCommand command = new SqlCommand("dbo.SP_VIPRenewal_Single", connection, transaction))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                command.Parameters.Add("@RenewalDays", SqlDbType.Int).Value = renewalDays;
                SqlParameter expire = command.Parameters.Add("@ExpireDayOut", SqlDbType.DateTime);
                expire.Direction = ParameterDirection.Output;
                SqlParameter result = command.Parameters.Add("@Result", SqlDbType.Int);
                result.Direction = ParameterDirection.ReturnValue;
                command.ExecuteNonQuery();
                expireDay = expire.Value == DBNull.Value ? DateTime.Now : Convert.ToDateTime(expire.Value);
                return result.Value == DBNull.Value ? 0 : Convert.ToInt32(result.Value);
            }
        }

        private sealed class VipState
        {
            public int TypeVip;
            public int Level;
            public int Exp;
            public DateTime ExpireDay;
            public DateTime LastDate;
            public int NextLevelDays;
            public bool CanTakeReward;
        }

        private static VipState LoadVipState(SqlConnection connection, SqlTransaction transaction,
            int userId, bool forUpdate)
        {
            string lockHint = forUpdate ? " WITH (UPDLOCK,HOLDLOCK,ROWLOCK)" : String.Empty;
            using (SqlCommand command = new SqlCommand(
                "SELECT TOP 1 typeVIP,VIPLevel,VIPExp,VIPExpireDay,VIPLastdate," +
                "VIPNextLevelDaysNeeded,CanTakeVipReward FROM dbo.Sys_VIP_Info" + lockHint +
                " WHERE UserID=@UserID",
                connection, transaction))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    if (!reader.Read()) return null;
                    VipState state = new VipState();
                    state.TypeVip = Convert.ToInt32(reader["typeVIP"]);
                    state.Level = Math.Max(1, Math.Min(MaxVipLevel, Convert.ToInt32(reader["VIPLevel"])));
                    state.Exp = Math.Max(0, Convert.ToInt32(reader["VIPExp"]));
                    state.ExpireDay = Convert.ToDateTime(reader["VIPExpireDay"]);
                    state.LastDate = Convert.ToDateTime(reader["VIPLastdate"]);
                    state.NextLevelDays = Convert.ToInt32(reader["VIPNextLevelDaysNeeded"]);
                    state.CanTakeReward = Convert.ToBoolean(reader["CanTakeVipReward"]);
                    return state;
                }
            }
        }

        private static void SaveVipState(SqlConnection connection, SqlTransaction transaction,
            int userId, VipState state)
        {
            using (SqlCommand command = new SqlCommand(
                "UPDATE dbo.Sys_VIP_Info SET typeVIP=@Type,VIPLevel=@Level,VIPExp=@Exp," +
                "VIPExpireDay=@Expire,VIPLastdate=@Last,VIPNextLevelDaysNeeded=@Next," +
                "CanTakeVipReward=@Reward WHERE UserID=@UserID",
                connection, transaction))
            {
                command.Parameters.Add("@Type", SqlDbType.Int).Value = state.TypeVip;
                command.Parameters.Add("@Level", SqlDbType.Int).Value = state.Level;
                command.Parameters.Add("@Exp", SqlDbType.Int).Value = state.Exp;
                command.Parameters.Add("@Expire", SqlDbType.DateTime).Value = state.ExpireDay;
                command.Parameters.Add("@Last", SqlDbType.DateTime).Value = state.LastDate;
                command.Parameters.Add("@Next", SqlDbType.Int).Value = state.NextLevelDays;
                command.Parameters.Add("@Reward", SqlDbType.Bit).Value = state.CanTakeReward;
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                if (command.ExecuteNonQuery() != 1)
                    throw new InvalidOperationException("VIP state update failed.");
            }
        }

        private static int GetVipFloor(int level)
        {
            if (level < 1) level = 1;
            if (level > MaxVipLevel) level = MaxVipLevel;
            return VipExpFloors[level - 1];
        }

        private static int GetLevelForExp(int exp)
        {
            int level = 1;
            for (int candidate = 2; candidate <= MaxVipLevel; candidate++)
            {
                if (exp < GetVipFloor(candidate)) break;
                level = candidate;
            }
            return level;
        }

        private static int GetNextLevelDays(int level, int exp)
        {
            if (level >= MaxVipLevel) return 0;
            int remaining = Math.Max(0, GetVipFloor(level + 1) - exp);
            return (remaining + 9) / 10;
        }

        private static void SendVipState(GameClient client, VipState state)
        {
            GSPacketIn response = new GSPacketIn((short)ePackageType.VIP_RENEWAL,
                client.Player.PlayerCharacter.ID);
            response.WriteByte((byte)state.TypeVip);
            response.WriteInt(state.Level);
            response.WriteInt(state.Exp);
            response.WriteDateTime(state.ExpireDay);
            response.WriteDateTime(state.LastDate);
            response.WriteInt(state.NextLevelDays);
            response.WriteBoolean(state.CanTakeReward);
            client.Out.SendTCP(response);
        }
    }
}
