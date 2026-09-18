using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Threading;
using System.Web.UI;

namespace WebApplication1.Admin
{
    public partial class PlayerTools : Page
    {
        private sealed class PlayerSnapshot
        {
            public int UserId;
            public string UserName;
            public string NickName;
            public int Grade;
            public int GP;
            public int Gold;
            public int Money;
            public int GiftToken;
            public int State;
            public bool IsExist;
            public DateTime ForbidDate;
            public string ForbidReason;
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

        private static PlayerSnapshot ReadPlayer(SqlCommand command)
        {
            using (SqlDataReader reader = command.ExecuteReader())
            {
                if (!reader.Read()) return null;
                PlayerSnapshot player = new PlayerSnapshot();
                player.UserId = Convert.ToInt32(reader["UserID"]);
                player.UserName = Convert.ToString(reader["UserName"]);
                player.NickName = Convert.ToString(reader["NickName"]);
                player.Grade = Convert.ToInt32(reader["Grade"]);
                player.GP = Convert.ToInt32(reader["GP"]);
                player.Gold = Convert.ToInt32(reader["Gold"]);
                player.Money = Convert.ToInt32(reader["Money"]);
                player.GiftToken = Convert.ToInt32(reader["GiftToken"]);
                player.State = Convert.ToInt32(reader["State"]);
                player.IsExist = Convert.ToBoolean(reader["IsExist"]);
                player.ForbidDate = Convert.ToDateTime(reader["ForbidDate"]);
                player.ForbidReason = reader["ForbidReason"] == DBNull.Value ? "" : Convert.ToString(reader["ForbidReason"]);
                return player;
            }
        }

        private static PlayerSnapshot ResolvePlayer(SqlConnection connection, string lookup)
        {
            using (SqlCommand command = new SqlCommand(
                "SELECT TOP 1 UserID,UserName,NickName,Grade,GP,Gold,Money,GiftToken,State,IsExist,ForbidDate,ForbidReason " +
                "FROM dbo.Sys_Users_Detail WHERE NickName=@Lookup OR UserName=@Lookup " +
                "ORDER BY CASE WHEN NickName=@Lookup THEN 0 ELSE 1 END,UserID", connection))
            {
                command.Parameters.Add("@Lookup", SqlDbType.NVarChar, 50).Value = lookup;
                return ReadPlayer(command);
            }
        }

        private static PlayerSnapshot ResolvePlayerById(SqlConnection connection, int userId)
        {
            using (SqlCommand command = new SqlCommand(
                "SELECT TOP 1 UserID,UserName,NickName,Grade,GP,Gold,Money,GiftToken,State,IsExist,ForbidDate,ForbidReason " +
                "FROM dbo.Sys_Users_Detail WHERE UserID=@UserID", connection))
            {
                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                return ReadPlayer(command);
            }
        }

        private void BindSnapshot(PlayerSnapshot player)
        {
            if (player == null)
            {
                PlayerPanel.Visible = false;
                UserIdHidden.Value = "";
                return;
            }

            PlayerPanel.Visible = true;
            UserIdHidden.Value = player.UserId.ToString();
            UserIdLabel.Text = player.UserId.ToString();
            UserNameLabel.Text = Server.HtmlEncode(player.UserName);
            NickNameLabel.Text = Server.HtmlEncode(player.NickName);
            GradeTextBox.Text = player.Grade.ToString();
            GpTextBox.Text = player.GP.ToString();
            GoldTextBox.Text = player.Gold.ToString();
            MoneyTextBox.Text = player.Money.ToString();
            GiftTokenTextBox.Text = player.GiftToken.ToString();

            bool banned = !player.IsExist || player.ForbidDate > DateTime.Now;
            StateLabel.Text = banned
                ? "ĐANG KHÓA"
                : (player.State == 0 ? "Offline" : "Online / State " + player.State);
            BanUntilTextBox.Text = banned
                ? player.ForbidDate.ToString("dd/MM/yyyy HH:mm:ss")
                : "Không khóa";
            if (!String.IsNullOrWhiteSpace(player.ForbidReason))
                BanReasonTextBox.Text = player.ForbidReason;
        }

        private void LoadSnapshot(string lookup)
        {
            if (String.IsNullOrWhiteSpace(lookup))
            {
                SetStatus("Vui lòng nhập tên nhân vật hoặc tài khoản.", false);
                BindSnapshot(null);
                return;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(DbConnectionString))
                {
                    connection.Open();
                    PlayerSnapshot player = ResolvePlayer(connection, lookup);
                    if (player == null)
                    {
                        BindSnapshot(null);
                        SetStatus("Không tìm thấy nhân vật/tài khoản: " + Server.HtmlEncode(lookup), false);
                        return;
                    }
                    BindSnapshot(player);
                    SetStatus("Đã nạp dữ liệu " + Server.HtmlEncode(player.NickName) + ".", true);
                }
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30", ex.ToString());
                BindSnapshot(null);
                SetStatus("Không thể đọc dữ liệu người chơi. Kiểm tra log AdminGunny.", false);
            }
        }

        private void LoadSnapshotById(int userId, string message, bool success)
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(DbConnectionString))
                {
                    connection.Open();
                    PlayerSnapshot player = ResolvePlayerById(connection, userId);
                    BindSnapshot(player);
                    if (player != null)
                        LookupTextBox.Text = player.NickName;
                }
                SetStatus(message, success);
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30Refresh", ex.ToString());
                SetStatus("Đã thao tác nhưng không thể nạp lại snapshot. Kiểm tra log.", false);
            }
        }

        private static bool TryReadNonNegative(string raw, out int value)
        {
            return Int32.TryParse(raw, out value) && value >= 0;
        }

        private bool PrepareOffline(SqlConnection connection, PlayerSnapshot player)
        {
            if (player == null || player.State == 0) return true;

            try
            {
                using (Bussiness.ManageBussiness manage = new Bussiness.ManageBussiness())
                {
                    manage.KitoffUser(player.UserId, "AdminGunny đang cập nhật dữ liệu. Vui lòng đăng nhập lại.");
                }
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30Kick", ex.ToString());
            }

            DateTime deadline = DateTime.UtcNow.AddSeconds(8);
            while (DateTime.UtcNow < deadline)
            {
                using (SqlCommand command = new SqlCommand(
                    "SELECT State FROM dbo.Sys_Users_Detail WHERE UserID=@UserID", connection))
                {
                    command.Parameters.Add("@UserID", SqlDbType.Int).Value = player.UserId;
                    object value = command.ExecuteScalar();
                    if (value == null || value == DBNull.Value || Convert.ToInt32(value) == 0)
                        return true;
                }
                Thread.Sleep(100);
            }
            return false;
        }

        protected void SaveButton_Click(object sender, EventArgs e)
        {
            int userId;
            int grade;
            int gp;
            int gold;
            int money;
            int giftToken;

            if (!Int32.TryParse(UserIdHidden.Value, out userId) || userId <= 0)
            {
                SetStatus("Hãy tra cứu người chơi trước.", false);
                return;
            }
            if (!Int32.TryParse(GradeTextBox.Text, out grade) || grade < 1 || grade > 99)
            {
                SetStatus("Cấp độ phải nằm trong khoảng 1–99.", false);
                return;
            }
            if (!TryReadNonNegative(GpTextBox.Text, out gp) ||
                !TryReadNonNegative(GoldTextBox.Text, out gold) ||
                !TryReadNonNegative(MoneyTextBox.Text, out money) ||
                !TryReadNonNegative(GiftTokenTextBox.Text, out giftToken))
            {
                SetStatus("GP, vàng, xu và Gift Token phải là số nguyên không âm.", false);
                return;
            }

            try
            {
                using (SqlConnection connection = new SqlConnection(DbConnectionString))
                {
                    connection.Open();
                    PlayerSnapshot player = ResolvePlayerById(connection, userId);
                    if (player == null)
                    {
                        SetStatus("Người chơi không còn tồn tại.", false);
                        return;
                    }
                    if (!PrepareOffline(connection, player))
                    {
                        SetStatus("Không thể đưa nhân vật về offline an toàn. Hãy thử lại.", false);
                        return;
                    }

                    using (SqlTransaction transaction = connection.BeginTransaction(IsolationLevel.Serializable))
                    {
                        try
                        {
                            using (SqlCommand command = new SqlCommand(
                                "UPDATE dbo.Sys_Users_Detail WITH (ROWLOCK) SET Grade=@Grade,GP=@GP,Gold=@Gold,Money=@Money,GiftToken=@GiftToken " +
                                "WHERE UserID=@UserID", connection, transaction))
                            {
                                command.Parameters.Add("@Grade", SqlDbType.Int).Value = grade;
                                command.Parameters.Add("@GP", SqlDbType.Int).Value = gp;
                                command.Parameters.Add("@Gold", SqlDbType.Int).Value = gold;
                                command.Parameters.Add("@Money", SqlDbType.Int).Value = money;
                                command.Parameters.Add("@GiftToken", SqlDbType.Int).Value = giftToken;
                                command.Parameters.Add("@UserID", SqlDbType.Int).Value = userId;
                                if (command.ExecuteNonQuery() != 1)
                                    throw new InvalidOperationException("Player update affected an unexpected row count.");
                            }
                            transaction.Commit();
                        }
                        catch
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
                LoadSnapshotById(userId, "Đã cập nhật chỉ số/tài nguyên. Người chơi có thể đăng nhập lại.", true);
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30Save", ex.ToString());
                SetStatus("Cập nhật thất bại. Không có thay đổi chưa commit.", false);
            }
        }

        protected void KickButton_Click(object sender, EventArgs e)
        {
            int userId;
            if (!Int32.TryParse(UserIdHidden.Value, out userId) || userId <= 0)
            {
                SetStatus("Hãy tra cứu người chơi trước.", false);
                return;
            }

            try
            {
                int result;
                using (Bussiness.ManageBussiness manage = new Bussiness.ManageBussiness())
                {
                    result = manage.KitoffUser(userId, "Bạn đã được đăng xuất bởi AdminGunny.");
                }
                LoadSnapshotById(userId,
                    result == 0 ? "Đã gửi lệnh kick tới GameServer." : "Lệnh kick trả mã " + result + ".",
                    result == 0);
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30KickManual", ex.ToString());
                SetStatus("Không thể gửi lệnh kick.", false);
            }
        }

        protected void BanButton_Click(object sender, EventArgs e)
        {
            int userId;
            int days;
            if (!Int32.TryParse(UserIdHidden.Value, out userId) || userId <= 0 ||
                !Int32.TryParse(BanDaysDropDown.SelectedValue, out days) ||
                (days != 1 && days != 7 && days != 30 && days != 365 && days != 3650))
            {
                SetStatus("Dữ liệu ban không hợp lệ.", false);
                return;
            }

            string reason = BanReasonTextBox.Text.Trim();
            if (String.IsNullOrWhiteSpace(reason)) reason = "Ban bởi AdminGunny V30";
            try
            {
                bool ok;
                using (Bussiness.ManageBussiness manage = new Bussiness.ManageBussiness())
                {
                    ok = manage.ForbidPlayerByUserID(userId, DateTime.Now.AddDays(days), false, reason);
                }
                LoadSnapshotById(userId,
                    ok ? "Đã ban người chơi trong " + days + " ngày và kick phiên online." : "Game/DB từ chối thao tác ban.",
                    ok);
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30Ban", ex.ToString());
                SetStatus("Ban thất bại. Kiểm tra log AdminGunny.", false);
            }
        }

        protected void UnbanButton_Click(object sender, EventArgs e)
        {
            int userId;
            if (!Int32.TryParse(UserIdHidden.Value, out userId) || userId <= 0)
            {
                SetStatus("Hãy tra cứu người chơi trước.", false);
                return;
            }

            try
            {
                bool ok;
                using (Bussiness.ManageBussiness manage = new Bussiness.ManageBussiness())
                {
                    ok = manage.ForbidPlayerByUserID(userId, DateTime.Now, true, "");
                }
                LoadSnapshotById(userId, ok ? "Đã unban tài khoản." : "Game/DB từ chối thao tác unban.", ok);
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminPlayerTools30Unban", ex.ToString());
                SetStatus("Unban thất bại. Kiểm tra log AdminGunny.", false);
            }
        }

        private void SetStatus(string message, bool success)
        {
            StatusLabel.Text = message;
            StatusLabel.Style["background"] = success ? "#effaf2" : "#fff2f2";
            StatusLabel.Style["color"] = success ? "#28633a" : "#8c3131";
        }
    }
}
