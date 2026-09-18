# Gunny 3.0 VIP20 live client source

This folder archives the ActionScript/XML extracted from the live Gunny 3.0 carrier and verified after the VIP20 patch.

Production carrier:
- Public IIS alias: http://103.9.156.181/v30/gunny/2.png
- Format: ALME wrapper around a CWS SWF.
- VIP20 live carrier SHA256: A6FB0B6FD33D752E211B7F0B92ADB5B1153B15C2D7E9743E8643DE714E0D82F6
- VIP20 XML SHA256: B80EB789F02DC2ECC3B4E077DC9E4C7AB70F608806677FC75710CBE2FAB27908

Verified behavior:
- VIP progression 1..20, VIP20 = MAX.
- EXP floors end at 7,800,000.
- Renewal packet keeps legacy isBand and appends paymentMode:
  nickname -> days -> isBand -> paymentMode.
- paymentMode 0 = Xu, 1 = Vang.
- Client shows both Xu and Vang balances.
- 1 month, 3 months, 6 months, 1 year and 2 years are supported.
- Missing VIP10+ artwork is clamped to legacy icon frames so the client does not request non-existent frames.

Canonical deployment stores the verified carrier/XML under runtime-assets/v30 so Install-DDTank30Web.ps1 cannot overwrite VIP20 with the legacy external source.

The patch script in tools/patch_v30_live_vip20_client.py is intentionally strict: it requires exact source matches before replacing anything, so applying it to a different client generation fails instead of silently corrupting the carrier.