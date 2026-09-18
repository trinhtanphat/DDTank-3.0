$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$bot = Get-Content (Join-Path $root 'Fighting.Server\GameObjects\BotProxyPlayer.cs') -Raw
$trajectory = Get-Content (Join-Path $root 'Fighting.Server\GameObjects\BotAimTrajectory.cs') -Raw
$room = Get-Content (Join-Path $root 'Fighting.Server\Rooms\ProxyRoom.cs') -Raw
$mgr = Get-Content (Join-Path $root 'Fighting.Server\Rooms\ProxyRoomMgr.cs') -Raw
$pvp = Get-Content (Join-Path $root 'Game.Logic\PVPGame.cs') -Raw
$logicProject = Get-Content (Join-Path $root 'Game.Logic\Game.Logic.csproj') -Raw
$fightProject = Get-Content (Join-Path $root 'Fighting.Server\Fighting.Server.csproj') -Raw

function Assert-True([bool]$ok,[string]$message) { if (-not $ok) { throw $message } }

Assert-True ($bot.Contains('public class BotProxyPlayer : IGamePlayer, IBotGamePlayer')) 'bot player contract missing'
Assert-True ($bot.Contains('TryFindAccurateShot')) 'accurate shot planner missing'
Assert-True ($bot.Contains('TryFindTerrainClearShot')) 'terrain clearing planner missing'
Assert-True ($bot.Contains('TryFindFlyShot')) 'fly reposition planner missing'
Assert-True ($bot.Contains('SelfHealTemplateId = 10012')) 'self heal policy missing'
Assert-True ($bot.Contains('TeamHealTemplateId = 10009')) 'team heal policy missing'
Assert-True ($bot.Contains('FlyTemplateId = 10016')) 'fly prop missing'
Assert-True ($bot.Contains('DamageBoostTemplateId = 10004')) 'damage boost missing'
Assert-True ($bot.Contains('MultiBallTemplateId = 10003')) 'multi-ball missing'
Assert-True ($bot.Contains('game.GetAllFightPlayers()')) 'bot must reason server-side beyond viewport'
Assert-True ($trajectory.Contains('BotTrajectoryOutcome.Terrain')) 'terrain outcome missing'
Assert-True ($trajectory.Contains('targetDamageDistance(px, py) < blastRadius')) 'runtime splash parity missing'
Assert-True ($room.Contains('IsSyntheticBotRoom')) 'synthetic room guard missing'
Assert-True ($room.Contains('BotFillEligibleTick = syntheticBotRoom ? long.MaxValue : TickHelper.GetTickCount() + 5000L;')) '5 second bot eligibility missing'
Assert-True ($mgr.Contains('public static readonly int PICK_UP_INTERVAL = 1000;')) '1 second match poll missing'
Assert-True ($mgr.Contains('public static readonly int BOT_FILL_WAIT_MS = 5000;')) 'bot fill policy constant missing'
Assert-True ($mgr.Contains('Interlocked.Decrement')) 'negative runtime bot ID missing'
Assert-True ($mgr.Contains('CreateBotRoom')) 'bot room factory missing'
Assert-True ($pvp.Contains('p.LoadingProcess = 100;')) 'bot loading auto-complete missing'
Assert-True ($pvp.Contains('bot.TakeTurn')) 'bot turn hook missing'
Assert-True ($pvp.Contains('hasBot ? 0 : CalculateGuildMatchResult')) 'bot-match guild reward suppression missing'
Assert-True ($pvp.Contains('if (!isBot)')) 'human PvP scoring/reward path must remain active against bots'
Assert-True (-not $pvp.Contains('if (!hasBot && !isBot)')) 'human scoring must not be disabled merely because a bot is present'
Assert-True ($logicProject.Contains('IBotGamePlayer.cs')) 'Game.Logic project bot interface missing'
Assert-True ($fightProject.Contains('BotProxyPlayer.cs')) 'Fighting.Server bot player compile item missing'
Assert-True ($fightProject.Contains('BotAimTrajectory.cs')) 'Fighting.Server trajectory compile item missing'
Write-Output 'DDT30_PVP_SMART_BOT_SMOKE=PASS'
