using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Web.Security;
using System.Security.Cryptography;
using System.Text;

namespace WebApplication1.Account
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            
        }

        private static bool PasswordMatches(string password)
        {
            string salt = ConfigurationManager.AppSettings["adminPasswordSalt"];
            string expectedHash = ConfigurationManager.AppSettings["adminPasswordHash"];

            if (!String.IsNullOrWhiteSpace(salt) && !String.IsNullOrWhiteSpace(expectedHash))
            {
                using (SHA256 sha = SHA256.Create())
                {
                    byte[] actualBytes = sha.ComputeHash(Encoding.UTF8.GetBytes(salt + ":" + (password ?? "")));
                    string actualHash = Convert.ToBase64String(actualBytes);
                    return SlowEquals(actualHash, expectedHash);
                }
            }

            // Backward-compatible only for development configs that explicitly opt in.
            string legacyPassword = ConfigurationManager.AppSettings["adminPassword"];
            return !String.IsNullOrEmpty(legacyPassword) &&
                   String.Equals(password, legacyPassword, StringComparison.Ordinal);
        }

        private static bool SlowEquals(string left, string right)
        {
            if (left == null || right == null || left.Length != right.Length)
                return false;

            int diff = 0;
            for (int i = 0; i < left.Length; i++)
                diff |= left[i] ^ right[i];
            return diff == 0;
        }

        protected void LoginUser_Authenticate(object sender, AuthenticateEventArgs e)
        {
            string username = LoginUser.UserName;
            string password = LoginUser.Password;
            e.Authenticated =
                username == ConfigurationManager.AppSettings["adminUser"] &&
                PasswordMatches(password);

            if (!e.Authenticated)
                LoginUser.FailureText = "username and password is not match";
        }

    }
}
