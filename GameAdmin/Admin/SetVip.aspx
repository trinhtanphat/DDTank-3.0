<%@ Page Title="Quản lý VIP" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
    CodeBehind="SetVip.aspx.cs" Inherits="WebApplication1.Admin.SetVip" %>

<asp:Content ID="VipHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style type="text/css">
        .vip-shell{max-width:980px;margin:24px auto;color:#172033}
        .vip-card{background:#fff;border:1px solid #dbe3ef;border-radius:16px;padding:22px;box-shadow:0 12px 36px rgba(30,55,90,.12)}
        .vip-title{margin:0 0 5px;font-size:26px}.vip-sub{margin:0 0 20px;color:#60708b}
        .vip-grid{display:grid;grid-template-columns:repeat(3,minmax(180px,1fr));gap:14px}
        .vip-field{display:grid;gap:6px}.vip-field label{font-weight:600;color:#40506a}
        .vip-field input,.vip-field select{width:100%;box-sizing:border-box;padding:10px 11px;border:1px solid #cbd6e6;border-radius:9px;background:#f9fbfe}
        .vip-actions,.vip-quick{display:flex;flex-wrap:wrap;gap:9px;margin-top:15px}
        .vip-actions input,.vip-quick input{padding:10px 15px;border:1px solid #b9c8dd;border-radius:9px;background:#eef4fc;color:#1f3c63;cursor:pointer}
        .vip-actions input:hover,.vip-quick input:hover{background:#ddeafb}.vip-actions input:disabled,.vip-quick input:disabled{opacity:.45;cursor:not-allowed}
        .vip-quick{padding:12px;border:1px dashed #c5d2e3;border-radius:12px}.vip-quick-title{width:100%;font-size:12px;font-weight:700;color:#71819a;text-transform:uppercase;letter-spacing:.07em}
        .vip-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;margin-top:18px}
        .vip-stat{padding:13px;border-radius:11px;background:#f5f8fc;border:1px solid #dbe3ef}.vip-stat span{display:block;color:#6b7b94;font-size:12px}.vip-stat strong{display:block;margin-top:4px;font-size:20px;color:#203653}
        .vip-status{display:block;margin-top:16px;padding:12px 14px;border-radius:10px;background:#f1f5fa}
        .vip-note{margin-top:12px;color:#687994;line-height:1.5}
        @media(max-width:760px){.vip-grid,.vip-stats{grid-template-columns:1fr}}
    </style>
</asp:Content>

<asp:Content ID="VipBody" ContentPlaceHolderID="MainContent" runat="server">
    <div class="vip-shell">
        <div class="vip-card">
            <h1 class="vip-title">VIP Gunny 3.0</h1>
            <p class="vip-sub">Tra cứu nhân vật, nâng/hạ VIP 1–20 và đồng bộ đúng EXP sàn để game không còn hiển thị tiến trình âm.</p>

            <div class="vip-grid">
                <div class="vip-field">
                    <label for="LookupTextBox">Tên nhân vật / tài khoản</label>
                    <asp:TextBox ID="LookupTextBox" runat="server" MaxLength="50"></asp:TextBox>
                </div>
                <div class="vip-field">
                    <label for="TargetVipDropDown">VIP đích</label>
                    <asp:DropDownList ID="TargetVipDropDown" runat="server" Enabled="false"></asp:DropDownList>
                </div>
                <div class="vip-field">
                    <label for="DurationDropDown">Gia hạn</label>
                    <asp:DropDownList ID="DurationDropDown" runat="server">
                        <asp:ListItem Text="Giữ nguyên hạn (nếu còn VIP)" Value="0"></asp:ListItem>
                        <asp:ListItem Text="+30 ngày" Value="30" Selected="True"></asp:ListItem>
                        <asp:ListItem Text="+90 ngày" Value="90"></asp:ListItem>
                        <asp:ListItem Text="+180 ngày" Value="180"></asp:ListItem>
                        <asp:ListItem Text="+365 ngày" Value="365"></asp:ListItem>
                    </asp:DropDownList>
                </div>
            </div>

            <div class="vip-actions">
                <asp:Button ID="LookupButton" runat="server" Text="Tra cứu" OnClick="LookupButton_Click" />
                <asp:Button ID="PlusOneButton" runat="server" Text="+1 VIP" Enabled="false" OnClick="PlusOneButton_Click" />
                <asp:Button ID="ApplyButton" runat="server" Text="Áp dụng VIP đã chọn" Enabled="false" OnClick="ApplyButton_Click" />
            </div>

            <div class="vip-quick">
                <div class="vip-quick-title">Nâng nhanh</div>
                <asp:Button ID="QuickVip10Button" runat="server" Text="VIP 10" Enabled="false" OnClick="QuickVip10Button_Click" />
                <asp:Button ID="QuickVip15Button" runat="server" Text="VIP 15" Enabled="false" OnClick="QuickVip15Button_Click" />
                <asp:Button ID="QuickVip20Button" runat="server" Text="VIP 20 MAX" Enabled="false" OnClick="QuickVip20Button_Click" />
            </div>

            <div class="vip-stats">
                <div class="vip-stat"><span>VIP hiện tại</span><strong><asp:Label ID="CurrentVipLabel" runat="server" Text="-"></asp:Label></strong></div>
                <div class="vip-stat"><span>VIP EXP</span><strong><asp:Label ID="VipExpLabel" runat="server" Text="-"></asp:Label></strong></div>
                <div class="vip-stat"><span>Hết hạn</span><strong><asp:Label ID="ExpireLabel" runat="server" Text="-"></asp:Label></strong></div>
            </div>

            <asp:Label ID="StatusLabel" runat="server" CssClass="vip-status" Text="Nhập tên nhân vật rồi bấm Tra cứu."></asp:Label>
            <asp:HiddenField ID="UserIdHidden" runat="server" />
            <p class="vip-note">Nếu nhân vật đang online, AdminGunny sẽ ngắt phiên trước khi sửa để tránh dữ liệu game ghi đè ngược lại. Sau khi cập nhật, đăng nhập lại để nạp VIP mới.</p>
        </div>
    </div>
</asp:Content>
