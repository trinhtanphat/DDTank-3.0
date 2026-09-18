<%@ Page Title="Quản lý người chơi Gunny 3.0" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
    CodeBehind="PlayerTools.aspx.cs" Inherits="WebApplication1.Admin.PlayerTools" %>

<asp:Content ID="PlayerToolsHead" ContentPlaceHolderID="HeadContent" runat="server">
<style type="text/css">
.pt-shell{max-width:1080px;margin:20px auto;font-family:"Segoe UI",Arial,sans-serif;color:#172033}
.pt-card{background:#fff;border:1px solid #dbe5f0;border-radius:16px;padding:20px;box-shadow:0 10px 28px rgba(30,55,90,.09);margin-bottom:15px}
.pt-title{margin:0;color:#203653;font-size:26px;font-weight:700;font-variant:normal}.pt-sub{margin:6px 0 16px;color:#687994}
.pt-search{display:flex;gap:10px;align-items:end;flex-wrap:wrap}.pt-field{display:grid;gap:6px;min-width:180px;flex:1}
.pt-field label{font-weight:600;color:#40506a}.pt-field input,.pt-field select,.pt-field textarea{box-sizing:border-box;width:100%;padding:10px 11px;border:1px solid #c9d6e6;border-radius:9px;background:#fbfcfe}
.pt-btn{padding:10px 14px;border:1px solid #afc2d8;border-radius:9px;background:#edf4fb;color:#20486f;cursor:pointer;font-weight:600}.pt-btn:hover{background:#dfeefa}
.pt-danger{background:#fff0f0;border-color:#e5b8b8;color:#922}.pt-good{background:#effaf2;border-color:#b9ddc2;color:#28633a}
.pt-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.pt-summary{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px;margin-bottom:16px}
.pt-stat{padding:12px;border:1px solid #dde6f0;border-radius:11px;background:#f7f9fc}.pt-stat span{display:block;color:#71819a;font-size:12px}.pt-stat strong{display:block;margin-top:4px;color:#203653;font-size:17px;word-break:break-word}
.pt-actions{display:flex;gap:9px;flex-wrap:wrap;margin-top:14px}.pt-status{display:block;margin-top:12px;padding:11px 13px;border-radius:10px;background:#f2f6fb;color:#52657e}
.pt-section{margin:4px 0 12px;font-size:18px;color:#203653;font-weight:700}
.pt-note{color:#71819a;font-size:13px;line-height:1.5;margin-top:10px}
@media(max-width:800px){.pt-grid{grid-template-columns:1fr 1fr}.pt-summary{grid-template-columns:1fr 1fr}}
@media(max-width:520px){.pt-grid,.pt-summary{grid-template-columns:1fr}}
</style>
</asp:Content>

<asp:Content ID="PlayerToolsBody" ContentPlaceHolderID="MainContent" runat="server">
<div class="pt-shell">
    <div class="pt-card">
        <h1 class="pt-title">Quản lý người chơi - Gunny 3.0</h1>
        <p class="pt-sub">Tìm bằng tên nhân vật hoặc tài khoản. Mọi thay đổi đều áp dụng riêng Db_Tank_V30.</p>
        <div class="pt-search">
            <div class="pt-field">
                <label>Tên nhân vật / tài khoản</label>
                <asp:TextBox ID="LookupTextBox" runat="server" MaxLength="50"></asp:TextBox>
            </div>
            <asp:Button ID="LookupButton" runat="server" Text="Tra cứu" CssClass="pt-btn" OnClick="LookupButton_Click" />
        </div>
        <asp:Label ID="StatusLabel" runat="server" CssClass="pt-status" Text="Nhập tên rồi bấm Tra cứu."></asp:Label>
    </div>

    <asp:Panel ID="PlayerPanel" runat="server" Visible="false">
        <div class="pt-card">
            <div class="pt-summary">
                <div class="pt-stat"><span>User ID</span><strong><asp:Label ID="UserIdLabel" runat="server"></asp:Label></strong></div>
                <div class="pt-stat"><span>Tài khoản</span><strong><asp:Label ID="UserNameLabel" runat="server"></asp:Label></strong></div>
                <div class="pt-stat"><span>Nhân vật</span><strong><asp:Label ID="NickNameLabel" runat="server"></asp:Label></strong></div>
                <div class="pt-stat"><span>Trạng thái</span><strong><asp:Label ID="StateLabel" runat="server"></asp:Label></strong></div>
            </div>

            <div class="pt-section">Chỉ số & tài nguyên</div>
            <div class="pt-grid">
                <div class="pt-field"><label>Cấp độ</label><asp:TextBox ID="GradeTextBox" runat="server"></asp:TextBox></div>
                <div class="pt-field"><label>GP / EXP</label><asp:TextBox ID="GpTextBox" runat="server"></asp:TextBox></div>
                <div class="pt-field"><label>Vàng</label><asp:TextBox ID="GoldTextBox" runat="server"></asp:TextBox></div>
                <div class="pt-field"><label>Xu / Money</label><asp:TextBox ID="MoneyTextBox" runat="server"></asp:TextBox></div>
                <div class="pt-field"><label>Gift Token</label><asp:TextBox ID="GiftTokenTextBox" runat="server"></asp:TextBox></div>
                <div class="pt-field"><label>Khóa đến</label><asp:TextBox ID="BanUntilTextBox" runat="server" ReadOnly="true"></asp:TextBox></div>
            </div>
            <div class="pt-actions">
                <asp:Button ID="SaveButton" runat="server" Text="Lưu thay đổi" CssClass="pt-btn pt-good" OnClick="SaveButton_Click" />
                <asp:Button ID="KickButton" runat="server" Text="Kick khỏi game" CssClass="pt-btn" OnClick="KickButton_Click" />
            </div>
            <p class="pt-note">Nếu nhân vật đang online, AdminGunny sẽ kick và chờ trạng thái offline trước khi sửa để tránh GameServer ghi dữ liệu cũ ngược lại.</p>
        </div>

        <div class="pt-card">
            <div class="pt-section">Ban / Unban</div>
            <div class="pt-grid">
                <div class="pt-field">
                    <label>Thời hạn khóa</label>
                    <asp:DropDownList ID="BanDaysDropDown" runat="server">
                        <asp:ListItem Text="1 ngày" Value="1"></asp:ListItem>
                        <asp:ListItem Text="7 ngày" Value="7"></asp:ListItem>
                        <asp:ListItem Text="30 ngày" Value="30" Selected="True"></asp:ListItem>
                        <asp:ListItem Text="365 ngày" Value="365"></asp:ListItem>
                        <asp:ListItem Text="10 năm" Value="3650"></asp:ListItem>
                    </asp:DropDownList>
                </div>
                <div class="pt-field" style="grid-column:span 2">
                    <label>Lý do</label>
                    <asp:TextBox ID="BanReasonTextBox" runat="server" MaxLength="200" Text="Ban bởi AdminGunny V30"></asp:TextBox>
                </div>
            </div>
            <div class="pt-actions">
                <asp:Button ID="BanButton" runat="server" Text="Ban tài khoản" CssClass="pt-btn pt-danger" OnClick="BanButton_Click" />
                <asp:Button ID="UnbanButton" runat="server" Text="Unban tài khoản" CssClass="pt-btn pt-good" OnClick="UnbanButton_Click" />
            </div>
        </div>
        <asp:HiddenField ID="UserIdHidden" runat="server" />
    </asp:Panel>
</div>
</asp:Content>
