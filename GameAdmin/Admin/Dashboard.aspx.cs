using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.UI;

namespace WebApplication1.Admin
{
    public partial class Dashboard : Page
    {
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
            if (!IsPostBack)
                LoadStats();
        }

        private static int ExecuteCount(SqlConnection connection, string sql)
        {
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                object value = command.ExecuteScalar();
                return value == null || value == DBNull.Value ? 0 : Convert.ToInt32(value);
            }
        }

        private void LoadStats()
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(DbConnectionString))
                {
                    connection.Open();
                    PlayersLabel.Text = ExecuteCount(connection,
                        "SELECT COUNT(*) FROM dbo.Sys_Users_Detail WHERE IsExist=1").ToString("N0");
                    OnlineLabel.Text = ExecuteCount(connection,
                        "SELECT COUNT(*) FROM dbo.Sys_Users_Detail WHERE IsExist=1 AND State<>0").ToString("N0");
                    BannedLabel.Text = ExecuteCount(connection,
                        "SELECT COUNT(*) FROM dbo.Sys_Users_Detail WHERE IsExist=0 OR ForbidDate>GETDATE()").ToString("N0");
                    VipLabel.Text = ExecuteCount(connection,
                        "SELECT COUNT(*) FROM dbo.Sys_VIP_Info WHERE VIPLevel>0 AND VIPExpireDay>GETDATE()").ToString("N0");
                    ItemsLabel.Text = ExecuteCount(connection,
                        "SELECT COUNT(*) FROM dbo.Sys_Users_Goods WHERE IsExist=1").ToString("N0");
                    FarmersLabel.Text = ExecuteCount(connection,
                        "SELECT COUNT(DISTINCT FarmID) FROM dbo.Sys_User_Field").ToString("N0");
                }

                StatusLabel.Text = "Dữ liệu V30 cập nhật lúc " + DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss") + ".";
            }
            catch (Exception ex)
            {
                Trace.Warn("AdminDashboard30", ex.ToString());
                StatusLabel.Text = "Không thể đọc thống kê Db_Tank_V30. Kiểm tra log AdminGunny.";
            }
        }
    }
}
