using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Threading;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1.Admin
{
    public partial class SetVip : Page
    {
        private const int MaxVipLevel = 20;
        private static readonly int[] VipExpFloors = new int[]
        {
            0, 200, 400, 800, 2000, 4000, 8000, 20000, 40000, 80000,
            200000, 400000, 800000, 1200000, 1800000, 2600000, 3600000,
            4800000, 6200000, 7800000
        };

        private sealed class PlayerLookup
        {
            public int UserId;
            public string NickName;
            public int State;
        }

        private string DbConnectionString
        {
            get
            {
                string value = ConfigurationManager.AppSettings["conString"];
                if (String.IsNullOrWhiteSpace(value))
                    throw new ConfigurationErrorsException("appSettings/conString is missing.");
                return value;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void LookupButton_Click(object sender, EventArgs e)
        {
            LoadSnapshot(LookupTextBox.Text.Trim());
        }

        protected void PlusOneButton_Click(object sender, EventArgs e)
        {
            ApplyVip(LookupTextBox.Text.Trim(), null, true);
        }

        protected void ApplyButton_Click(object sender, EventArgs e)
        {
            int target;
            if (!Int32.TryParse(TargetVipDropDown.SelectedValue, out target))
            {
                SetStatus("Hãy tra cứu nhân vật rồi chọn VIP đích.", false);
                return;
            }
            ApplyVip(LookupTextBox.Text.Trim(), target, false);
        }

        protected void QuickVip10Button_Click(object sender, EventArgs e)
        {
            ApplyVip(LookupTextBox.Text.Trim(), 10, false);
        }

        protected void QuickVip15Button_Click(object sender, EventArgs e)
        {
            ApplyVip(LookupTextBox.Text.Trim(), 15, false);
        }

        protected void QuickVip20Button_Click(object sender, EventArgs e)
        {
            ApplyVip(LookupTextBox.Text.Trim(), 20, false);
        }

        private static int GetVipExpFloor(int level)
        {
            if (level <= 0) return 0;
            if (level > MaxVipLevel) level = MaxVipLevel;
            return VipExpFloors[level - 1];
        }

        private static int GetNextDays(int level, int exp)
        {
            if (level <= 0 || level >= MaxVipLevel) return 0;
            int remaining = Math.Max(0, GetVipExpFloor(level + 1) - exp);
            return (remaining + 9) / 10;
        }

        private int GetDurationDays()
        {
            int days;
            if (!Int32.TryParse(DurationDropDown.SelectedValue, out days)) return -1;
            return days == 0 || days == 30 || days == 90 || days == 180 || days == 365 ? days : -1;
        }

        private static PlayerLookup ResolvePlayer(SqlConnection connection, SqlTransaction transaction, string lookup, bool forUpdate)
        {
            string table = forUpdate
                ? "dbo.Sys_Users_Detail WITH (UPDLOCK,HOLDLOCK,ROWLOCK)"
                : "dbo.Sys_Users_Detail";

            using (SqlCommand command = new SqlCommand(
                "SELECT TOP 1 UserID,NickName,State FROM " + table +
                " WHERE IsExist=1 AND (NickName=@Lookup OR UserName=@Lookup) " +
                "ORDER BY CASE WHEN NickName=@Lookup THEN 0 ELSE 1 END,UserID",
                connection, transaction))
            {
                command.Parameters.Add("@Lookup", SqlDbType.NVarChar, 50).Value = lookup;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    if (!reader.Read()) return null;
                    PlayerLookup result = new PlayerLookup();
                    result.UserId = Convert.ToInt32(reader["UserID"]);
                    result.NickName = Convert.ToString(reader["NickName"]);
                    result.State = reader["State"] == DBNull.Value ? 0 : Convert.ToInt32(reader["State"]);
                    return result;
                }
            }
        }

        private static bool VipSchemaReady(SqlConnection connection)
        {
            using (SqlCommand command = new SqlCommand(
                "SELECT CASE WHEN OBJECT_ID('dbo.Sys_VIP_Info','U') IS NOT NULL THEN 1 ELSE 0 END",
                connection))
            {
                return Convert.ToInt32(command.ExecuteScalar()) == 1;
            }
        }

        private void LoadSnapshot(string lookup)
        {
            ResetSnapshot();
            if (String.IsNullOrWhiteSpace(lookup))
            {
                SetStatus("Vui lòng nhập tên nhân vật hoặc tài khoản.", false);
                return;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(DbConnectionString))
                {
                    connection.Open();
                    if (!VipSchemaReady(connection))
                    {
                        SetStatus("CSDL Gunny 3.0 chưa có schema VIP. Hãy chạy migration VIP20 trước.", false);
                        return;
                    }

                    PlayerLookup player = ResolvePlayer(connection, null, lookup, false);
                    if (player == null)
                    {
                        SetStatus("Không tìm thấy nhân vật/tài khoản.", false);
                        return;
                    }

                    int level = 0;
                    int exp = 0;
                    DateTime? expire = null;
                    using (SqlCommand command = new SqlCommand(
                        "SELECT TOP 1 typeVIP,VIPLevel,VIPExp,VIPExpireDay FROM dbo.Sys_VIP_Info WHERE UserID=@UserID",
                        connection))
                    {
                        command.Parameters.Add("@UserID", SqlDbType.Int).Value = player.UserId;
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                int typeVip = reader["typeVIP"] == DBNull.Value ? 0 : Convert.ToInt32(reader["typeVIP"]);
                                level = reader["VIPLevel"] == DBNull.Value ? 1 : Convert.ToInt32(reader["VIPLevel"]);
                                exp = reader["VIPExp"] == DBNull.Value ? 0 : Convert.ToInt32(reader["VIPExp"]);
                                expire = reader["VIPExpireDay"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["VIPExpireDay"]);
                                if (typeVip <= 0 || !expire.HasValue || expire.Value < DateTime.Now) level = 0;
                            }
                        }
                    }

                    SetSnapshot(player, level, exp, expire);
                    PopulateTargets(level);
                    SetStatus("Đã tải dữ liệu VIP của " + player.NickName + ".", true);
                }
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminVip30", ex.ToString());
                ResetSnapshot();
                SetStatus("Không thể đọc dữ liệu VIP. Kiểm tra log AdminGunny.", false);
            }
        }

        private bool PrepareOffline(SqlConnection connection, PlayerLookup player)
        {
            if (player.State == 0) return true;

            try
            {
                using (Bussiness.ManageBussiness manage = new Bussiness.ManageBussiness())
                {
                    manage.KitoffUser(player.UserId, "AdminGunny đang cập nhật VIP. Vui lòng đăng nhập lại.");
                }
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminVip30Kick", ex.ToString());
            }

            DateTime deadline = DateTime.UtcNow.AddSeconds(8);
            while (DateTime.UtcNow < deadline)
            {
                using (SqlCommand command = new SqlCommand(
                    "SELECT State FROM dbo.Sys_Users_Detail WHERE UserID=@UserID", connection))
                {
                    command.Parameters.Add("@UserID", SqlDbType.Int).Value = player.UserId;
                    object value = command.ExecuteScalar();
                    if (value == null || value == DBNull.Value || Convert.ToInt32(value) == 0) return true;
                }
                Thread.Sleep(100);
            }
            return false;
        }

        private void ApplyVip(string lookup, int? requestedVip, bool plusOne)
        {
            if (String.IsNullOrWhiteSpace(lookup))
            {
                SetStatus("Vui lòng nhập tên nhân vật hoặc tài khoản.", false);
                return;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(DbConnectionString))
                {
                    connection.Open();
                    if (!VipSchemaReady(connection))
                    {
                        SetStatus("CSDL chưa có schema VIP20. Chưa thay đổi dữ liệu.", false);
                        return;
                    }

                    PlayerLookup initial = ResolvePlayer(connection, null, lookup, false);
                    if (initial == null)
                    {
                        SetStatus("Không tìm thấy nhân vật/tài khoản.", false);
                        return;
                    }
                    if (!PrepareOffline(connection, initial))
                    {
                        SetStatus("Không thể đưa nhân vật về offline an toàn. Hãy thử lại.", false);
                        return;
                    }

                    SqlTransaction transaction = connection.BeginTransaction(IsolationLevel.Serializable);
                    try
                    {
                        PlayerLookup player = ResolvePlayer(connection, transaction, lookup, true);
                        if (player == null)
                        {
                            transaction.Rollback();
                            SetStatus("Dữ liệu nhân vật vừa thay đổi. Hãy tra cứu lại.", false);
                            return;
                        }

                        int currentLevel = 0;
                        int currentExp = 0;
                        int currentType = 0;
                        DateTime? currentExpire = null;
                        bool hasRow = false;

                        using (SqlCommand query = new SqlCommand(
                            "SELECT typeVIP,VIPLevel,VIPExp,VIPExpireDay FROM dbo.Sys_VIP_Info " +
                            "WITH (UPDLOCK,HOLDLOCK,ROWLOCK) WHERE UserID=@UserID",
                            connection, transaction))
                        {
                            query.Parameters.Add("@UserID", SqlDbType.Int).Value = player.UserId;
                            using (SqlDataReader reader = query.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    hasRow = true;
                                    currentType = Convert.ToInt32(reader["typeVIP"]);
                                    currentLevel = Convert.ToInt32(reader["VIPLevel"]);
                                    currentExp = Convert.ToInt32(reader["VIPExp"]);
                                    currentExpire = reader["VIPExpireDay"] == DBNull.Value
                                        ? (DateTime?)null : Convert.ToDateTime(reader["VIPExpireDay"]);
                                }
                            }
                        }

                        bool currentlyActive = currentType > 0 && currentExpire.HasValue && currentExpire.Value >= DateTime.Now;
                        int visibleCurrent = currentlyActive ? currentLevel : 0;
                        int target = plusOne ? Math.Min(MaxVipLevel, visibleCurrent + 1) : requestedVip.GetValueOrDefault();

                        if (target < 0 || target > MaxVipLevel || target == visibleCurrent)
                        {
                            transaction.Rollback();
                            SetStatus("VIP đích phải từ 0 đến 20 và khác VIP hiện tại.", false);
                            return;
                        }

                        int duration = GetDurationDays();
                        if (duration < 0)
                        {
                            transaction.Rollback();
                            SetStatus("Thời hạn VIP không hợp lệ.", false);
                            return;
                        }

                        DateTime now = DateTime.Now;
                        int targetExp = target > 0 ? GetVipExpFloor(target) : 0;
                        int nextDays = target > 0 ? GetNextDays(target, targetExp) : 0;
                        DateTime expireDay = now.AddSeconds(-1);

                        if (target > 0)
                        {
                            if (duration == 0)
                            {
                                if (currentlyActive && currentExpire.HasValue)
                                    expireDay = currentExpire.Value;
                                else
                                {
                                    transaction.Rollback();
                                    SetStatus("VIP chưa hoạt động; hãy chọn thời hạn để kích hoạt.", false);
                                    return;
                                }
                            }
                            else
                            {
                                DateTime baseDate = currentlyActive && currentExpire.HasValue ? currentExpire.Value : now;
                                expireDay = baseDate.AddDays(duration);
                            }
                        }

                        if (hasRow)
                        {
                            using (SqlCommand update = new SqlCommand(
                                "UPDATE dbo.Sys_VIP_Info SET typeVIP=@Type,VIPLevel=@Level,VIPExp=@Exp," +
                                "VIPExpireDay=@Expire,LastVIPPackTime=@Now,VIPLastdate=@Now," +
                                "VIPNextLevelDaysNeeded=@Next,CanTakeVipReward=@Reward WHERE UserID=@UserID",
                                connection, transaction))
                            {
                                update.Parameters.Add("@Type", SqlDbType.Int).Value = target > 0 ? 1 : 0;
                                update.Parameters.Add("@Level", SqlDbType.Int).Value = target > 0 ? target : 1;
                                update.Parameters.Add("@Exp", SqlDbType.Int).Value = targetExp;
                                update.Parameters.Add("@Expire", SqlDbType.DateTime).Value = expireDay;
                                update.Parameters.Add("@Now", SqlDbType.DateTime).Value = now;
                                update.Parameters.Add("@Next", SqlDbType.Int).Value = nextDays;
                                update.Parameters.Add("@Reward", SqlDbType.Bit).Value = target > 0;
                                update.Parameters.Add("@UserID", SqlDbType.Int).Value = player.UserId;
                                if (update.ExecuteNonQuery() != 1)
                                    throw new InvalidOperationException("VIP row update affected an unexpected number of rows.");
                            }
                        }
                        else if (target > 0)
                        {
                            using (SqlCommand insert = new SqlCommand(
                                "INSERT dbo.Sys_VIP_Info " +
                                "(UserID,typeVIP,VIPLevel,VIPExp,VIPOnlineDays,VIPOfflineDays,VIPExpireDay," +
                                "LastVIPPackTime,VIPLastdate,VIPNextLevelDaysNeeded,CanTakeVipReward) " +
                                "VALUES(@UserID,1,@Level,@Exp,0,0,@Expire,@Now,@Now,@Next,1)",
                                connection, transaction))
                            {
                                insert.Parameters.Add("@UserID", SqlDbType.Int).Value = player.UserId;
                                insert.Parameters.Add("@Level", SqlDbType.Int).Value = target;
                                insert.Parameters.Add("@Exp", SqlDbType.Int).Value = targetExp;
                                insert.Parameters.Add("@Expire", SqlDbType.DateTime).Value = expireDay;
                                insert.Parameters.Add("@Now", SqlDbType.DateTime).Value = now;
                                insert.Parameters.Add("@Next", SqlDbType.Int).Value = nextDays;
                                insert.ExecuteNonQuery();
                            }
                        }

                        transaction.Commit();
                        SetSnapshot(player, target, targetExp, target > 0 ? (DateTime?)expireDay : null);
                        PopulateTargets(target);
                        SetStatus("Đã cập nhật " + player.NickName + " từ VIP " + visibleCurrent + " sang VIP " + target +
                            ". Đăng nhập lại game để nhận dữ liệu mới.", true);
                    }
                    catch
                    {
                        try { transaction.Rollback(); } catch { }
                        throw;
                    }
                }
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminVip30Apply", ex.ToString());
                SetStatus("Không thể cập nhật VIP. Dữ liệu chưa được thay đổi.", false);
            }
        }

        private void PopulateTargets(int current)
        {
            TargetVipDropDown.Items.Clear();
            if (current != 0) TargetVipDropDown.Items.Add(new ListItem("Tắt VIP (VIP 0)", "0"));
            for (int vip = 1; vip <= MaxVipLevel; vip++)
            {
                if (vip != current) TargetVipDropDown.Items.Add(new ListItem("VIP " + vip, vip.ToString()));
            }
            TargetVipDropDown.Enabled = TargetVipDropDown.Items.Count > 0;
            ApplyButton.Enabled = TargetVipDropDown.Enabled;
            PlusOneButton.Enabled = current < MaxVipLevel;
            QuickVip10Button.Enabled = current != 10;
            QuickVip15Button.Enabled = current != 15;
            QuickVip20Button.Enabled = current != 20;
        }

        private void SetSnapshot(PlayerLookup player, int level, int exp, DateTime? expire)
        {
            LookupTextBox.Text = player.NickName;
            UserIdHidden.Value = player.UserId.ToString();
            CurrentVipLabel.Text = level > 0 ? "VIP " + level : "Chưa có VIP";
            VipExpLabel.Text = exp.ToString("N0");
            ExpireLabel.Text = expire.HasValue ? expire.Value.ToString("dd/MM/yyyy HH:mm") : "Chưa kích hoạt";
        }

        private void ResetSnapshot()
        {
            UserIdHidden.Value = String.Empty;
            CurrentVipLabel.Text = "-";
            VipExpLabel.Text = "-";
            ExpireLabel.Text = "-";
            TargetVipDropDown.Items.Clear();
            TargetVipDropDown.Enabled = false;
            ApplyButton.Enabled = false;
            PlusOneButton.Enabled = false;
            QuickVip10Button.Enabled = false;
            QuickVip15Button.Enabled = false;
            QuickVip20Button.Enabled = false;
        }

        private void SetStatus(string message, bool success)
        {
            StatusLabel.Text = message;
            StatusLabel.Style["color"] = success ? "#176b3a" : "#a12d36";
        }
    }
}
