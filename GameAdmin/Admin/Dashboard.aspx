<%@ Page Title="Gunny 3.0 Admin Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
    CodeBehind="Dashboard.aspx.cs" Inherits="WebApplication1.Admin.Dashboard" %>

<asp:Content ID="DashboardHead" ContentPlaceHolderID="HeadContent" runat="server">
<style type="text/css">
.v30-shell{max-width:1120px;margin:20px auto;font-family:"Segoe UI",Arial,sans-serif;color:#172033}
.v30-hero{display:flex;justify-content:space-between;gap:20px;align-items:center;padding:22px 24px;border-radius:18px;background:linear-gradient(135deg,#14213d,#214b76);color:#fff;box-shadow:0 12px 30px rgba(25,48,80,.18)}
.v30-hero h1{margin:0;color:#fff;font-size:28px;font-weight:700;font-variant:normal}.v30-hero p{margin:7px 0 0;color:#dce9f7}
.v30-chip{display:inline-block;padding:8px 12px;border:1px solid rgba(255,255,255,.28);border-radius:999px;background:rgba(255,255,255,.1);white-space:nowrap}
.v30-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px;margin-top:16px}
.v30-stat{background:#fff;border:1px solid #dbe5f0;border-radius:15px;padding:17px 18px;box-shadow:0 8px 22px rgba(30,55,90,.08)}
.v30-stat span{display:block;color:#65758b;font-size:13px}.v30-stat strong{display:block;margin-top:6px;color:#17365d;font-size:26px}
.v30-card{margin-top:16px;background:#fff;border:1px solid #dbe5f0;border-radius:15px;padding:20px;box-shadow:0 8px 22px rgba(30,55,90,.08)}
.v30-card h2{margin:0 0 12px;font-size:19px;color:#203653;font-variant:normal}
.v30-actions{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px}
.v30-actions a{display:block;padding:14px 15px;border:1px solid #cbd8e8;border-radius:11px;background:#f6f9fd;color:#234c78;text-decoration:none;font-weight:600}
.v30-actions a:hover{background:#eaf2fb;color:#17365d}
.v30-status{display:block;margin-top:14px;padding:11px 13px;border-radius:10px;background:#f2f6fb;color:#55677f}
@media(max-width:850px){.v30-stats,.v30-actions{grid-template-columns:1fr 1fr}.v30-hero{align-items:flex-start;flex-direction:column}}
@media(max-width:560px){.v30-stats,.v30-actions{grid-template-columns:1fr}}
</style>
</asp:Content>

<asp:Content ID="DashboardBody" ContentPlaceHolderID="MainContent" runat="server">
<div class="v30-shell">
    <div class="v30-hero">
        <div>
            <h1>Gunny 3.0 Admin Dashboard</h1>
            <p>Quản trị riêng instance V30 trên VPS 103.9.156.181.</p>
        </div>
        <div class="v30-chip">DB: Db_Tank_V30</div>
    </div>

    <div class="v30-stats">
        <div class="v30-stat"><span>Nhân vật đang tồn tại</span><strong><asp:Label ID="PlayersLabel" runat="server" Text="-"></asp:Label></strong></div>
        <div class="v30-stat"><span>Đang online</span><strong><asp:Label ID="OnlineLabel" runat="server" Text="-"></asp:Label></strong></div>
        <div class="v30-stat"><span>Tài khoản đang khóa</span><strong><asp:Label ID="BannedLabel" runat="server" Text="-"></asp:Label></strong></div>
        <div class="v30-stat"><span>VIP đang hoạt động</span><strong><asp:Label ID="VipLabel" runat="server" Text="-"></asp:Label></strong></div>
        <div class="v30-stat"><span>Vật phẩm đang tồn tại</span><strong><asp:Label ID="ItemsLabel" runat="server" Text="-"></asp:Label></strong></div>
        <div class="v30-stat"><span>Người chơi có nông trại</span><strong><asp:Label ID="FarmersLabel" runat="server" Text="-"></asp:Label></strong></div>
    </div>

    <div class="v30-card">
        <h2>Thao tác nhanh</h2>
        <div class="v30-actions">
            <a href="<%= ResolveUrl("~/Admin/PlayerTools.aspx") %>">Quản lý người chơi / ban / unban</a>
            <a href="<%= ResolveUrl("~/Admin/SetVip.aspx") %>">Nâng / hạ VIP 1–20</a>
            <a href="<%= ResolveUrl("~/Admin/sendMail5Item.aspx") %>">Gửi tối đa 5 vật phẩm</a>
            <a href="<%= ResolveUrl("~/Admin/SendMail.aspx") %>">Gửi thư hệ thống</a>
            <a href="<%= ResolveUrl("~/Admin/Item.aspx") %>">Tra cứu Template Item</a>
            <a href="<%= ResolveUrl("~/Admin/customItem.aspx") %>">Custom Item legacy</a>
        </div>
        <asp:Label ID="StatusLabel" runat="server" CssClass="v30-status"></asp:Label>
    </div>
</div>
</asp:Content>
