-- ============================================================
-- GPH Map Search Data
-- Static search helpers that are not exposed reliably by ESO APIs.
-- Source for daily quest giver names/locations:
-- https://en.uesp.net/wiki/Online:Daily_Quests
-- Individual NPC page locations were fetched from UESP raw pages.
-- Coordinates sourced from manual mapping.
-- ============================================================

GamePadHelper_MapSearchData = GamePadHelper_MapSearchData or {}

local data = GamePadHelper_MapSearchData


data.DAILY_QUEST_GIVERS = {
    {
        name = "Alvur Baren", -- https://en.uesp.net/wiki/Online:Alvur_Baren
        category = "Mages Guild Daily Quests",
        locations = {
            { placeName = "Mages Guild", cityName = "Dreughside", zoneId = 19, cityMapId = 33, x = 0.5832324028, y = 0.5112639666, alliance = 2 },
            { placeName = "Mages Guild", cityName = "Elden Root", zoneId = 383, cityMapId = 446, x = 0.8238251209, y = 0.4906557500, alliance = 1 },
            { placeName = "Mages Guild", cityName = "Mournhold", zoneId = 57, cityMapId = 205, x = 0.3622862101, y = 0.5867315531, alliance = 3 },
        },
    },
    {
        name = "Ardanir", -- https://en.uesp.net/wiki/Online:Ardanir
        category = "Wayward Guardian",
        locations = {
            { placeName = "Markarth", cityName = "Markarth", zoneId = 1207, cityMapId = 1858, x = 0.7097710967, y = 0.5098394156 },
        },
    },
    {
        name = "Arzorag", -- https://en.uesp.net/wiki/Online:Arzorag
        category = "Wrothgar World Boss Dailies",
        locations = {
            { placeName = "Skalar's Hostel", cityName = "Orsinium", zoneId = 684, cityMapId = 895, x = 0.3167660236, y = 0.2770044804 },
        },
    },
    {
        name = "Battlemaster Rivyn", -- https://en.uesp.net/wiki/Online:Battlemaster_Rivyn
        category = "Battlegrounds Missions",
        locations = {
            { placeName = "Gladiator's Quarters", cityName = "Alinor", zoneId = 1011, cityMapId = 1430, x = 0.0890831128, y = 0.4126663506 },
            { placeName = "Gladiator's Quarters", cityName = "Daggerfall", zoneId = 3, cityMapId = 63, x = 0.4528657794, y = 0.2833637893 },
            { placeName = "Gladiator's Quarters", cityName = "Davon's Watch", zoneId = 41, cityMapId = 24, x = 0.6444798708, y = 0.7986122966 },
            { placeName = "Gladiator's Quarters", cityName = "Gonfalon Bay", zoneId = 1318, cityMapId = 2163, x = 0.1552033424, y = 0.3838516772 },
            { placeName = "Gladiator's Quarters", cityName = "Leyawiin", zoneId = 1261, cityMapId = 1940, x = 0.3808173537, y = 0.1457562000 },
            { placeName = "Gladiator's Quarters", cityName = "Rimmen", zoneId = 1086, cityMapId = 1576, x = 0.0888012722, y = 0.6129474044 },
            { placeName = "Gladiator's Quarters", cityName = "Vivec City", zoneId = 849, cityMapId = 1287, x = 0.2177096158, y = 0.5691549778 },
            { placeName = "Gladiator's Quarters", cityName = "Vulkhel Guard", zoneId = 381, cityMapId = 243, x = 0.5323008299, y = 0.5054043531 },
        },
    },
    {
        name = "Battlereeve Tanerline", -- https://en.uesp.net/wiki/Online:Battlereeve_Tanerline
        category = "Summerset World Event Daily",
        locations = {
            { placeName = "Plaza of the Hand", cityName = "Alinor", zoneId = 1011, cityMapId = 1430, x = 0.3182982802, y = 0.8105757833 },
        },
    },
    {
        name = "Beleru Omoril", -- https://en.uesp.net/wiki/Online:Beleru_Omoril
        category = "Vvardenfell World Boss Dailies",
        locations = {
            { placeName = "Hall of Justice", cityName = "Vivec City", zoneId = 849, cityMapId = 1287, x = 0.4785906971, y = 0.5526601076 },
        },
    },
    {
        name = "Bolgrul", -- https://en.uesp.net/wiki/Online:Bolgrul
        category = "Undaunted Daily Quests",
        locations = {
            { placeName = "Undaunted Enclave", cityName = "Dreughside", zoneId = 19, cityMapId = 33, x = 0.1467203200, y = 0.4824189544, alliance = 2 },
            { placeName = "Undaunted Enclave", cityName = "Elden Root", zoneId = 383, cityMapId = 445, x = 0.5607210398, y = 0.6603766084, alliance = 1 },
            { placeName = "Undaunted Enclave", cityName = "Mournhold", zoneId = 57, cityMapId = 205, x = 0.3173196912, y = 0.6755146980, alliance = 3 },
        },
    },
    {
        name = "Bolu", -- https://en.uesp.net/wiki/Online:Bolu
        category = "Murkmire World Boss Dailies",
        locations = {
            { placeName = "Lilmoth", cityName = "Lilmoth", zoneId = 726, cityMapId = 1560, x = 0.4509567022, y = 0.6382588148 },
        },
    },
    {
        name = "Bralthahawn", -- https://en.uesp.net/wiki/Online:Bralthahawn
        category = "The Reach Delve Dailies",
        locations = {
            { placeName = "Markarth", cityName = "Markarth", zoneId = 1207, cityMapId = 1858, x = 0.5804236531, y = 0.5801844597 },
        },
    },
    {
        name = "Britta Silanus", -- https://en.uesp.net/wiki/Online:Britta_Silanus
        category = "Blackwood World Boss Dailies",
        locations = {
            { placeName = "Leyawiin", cityName = "Leyawiin", zoneId = 1261, cityMapId = 1940, x = 0.2164784223, y = 0.5353142619 },
        },
    },
    {
        name = "Bruccius Baenius", -- https://en.uesp.net/wiki/Online:Bruccius_Baenius
        category = "Dragonhold World Boss Dailies",
        locations = {
            { placeName = "Senchal Merchant Square", cityName = "Senchal", zoneId = 1133, cityMapId = 1675, x = 0.5404431820, y = 0.6989180446 },
        },
    },
    {
        name = "Bursar of Tributes", -- https://en.uesp.net/wiki/Online:Bursar_of_Tributes
        category = "Blackfeather Court Dailies",
        locations = {
            { placeName = "Slag Town", cityName = "Brass Fortress", zoneId = 980, cityMapId = 1348, x = 0.6117810607, y = 0.4892891645 },
        },
    },
    {
        name = "Cardea Gallus", -- https://en.uesp.net/wiki/Online:Cardea_Gallus
        category = "Fighters Guild Daily Quests",
        locations = {
            { placeName = "Fighters Guild", cityName = "Dreughside", zoneId = 19, cityMapId = 33, x = 0.3621351123, y = 0.3019210696, alliance = 2 },
            { placeName = "Fighters Guild", cityName = "Elden Root", zoneId = 383, cityMapId = 446, x = 0.6467759609, y = 0.8231694102, alliance = 1 },
            { placeName = "Fighters Guild", cityName = "Mournhold", zoneId = 57, cityMapId = 205, x = 0.5448757410, y = 0.7273079157, alliance = 3 },
        },
    },
    {
        name = "Chizbari the Chipper", -- https://en.uesp.net/wiki/Online:Chizbari_the_Chipper
        category = "Dragonhold World Event Daily",
        locations = {
            { placeName = "Dragonguard Sanctum", cityName = "Dragonguard Sanctum", zoneId = 1133, x = 0.2724579275, y = 0.2858497202 },
        },
    },
    {
        name = "Clockwork Facilitator", -- https://en.uesp.net/wiki/Online:Clockwork_Facilitator
        category = "Clockwork City World Boss Dailies",
        locations = {
            { placeName = "Brass Fortress", cityName = "Brass Fortress", zoneId = 980, cityMapId = 1348, x = 0.5895296931, y = 0.5412595272 },
        },
    },
    {
        name = "Commandant Salerius", -- https://en.uesp.net/wiki/Online:Commandant_Salerius
        category = "West Weald Delve Dailies",
        locations = {
            { placeName = "Skingrad", cityName = "Skingrad", zoneId = 1443, cityMapId = 2514, x = 0.6211023331, y = 0.5777600408 },
        },
    },
    {
        name = "Deetum-Jas", -- https://en.uesp.net/wiki/Online:Deetum-Jas
        category = "Blackwood Delve Dailies",
        locations = {
            { placeName = "Leyawiin", cityName = "Leyawiin", zoneId = 1261, cityMapId = 1940, x = 0.2240708619, y = 0.5302291512 },
        },
    },
    {
        name = "Dirge Truptor", -- https://en.uesp.net/wiki/Online:Dirge_Truptor
        category = "New Moon Dailies",
        locations = {
            { placeName = "Dragonguard Sanctum", cityName = "Dragonguard Sanctum", zoneId = 1133, x = 0.3161886632, y = 0.4525164068 },
        },
    },
    {
        name = "Druid Aishabeh", -- https://en.uesp.net/wiki/Online:Druid_Aishabeh
        category = "Galen World Event Daily",
        locations = {
            { placeName = "Vastyr", cityName = "Vastyr", zoneId = 1383, cityMapId = 2227, x = 0.5592867136, y = 0.4597567618 },
        },
    },
    {
        name = "Druid Gastoc", -- https://en.uesp.net/wiki/Online:Druid_Gastoc
        category = "Galen World Boss Dailies",
        locations = {
            { placeName = "Vastyr", cityName = "Vastyr", zoneId = 1383, cityMapId = 2227, x = 0.5653922707, y = 0.4549231976 },
        },
    },
    {
        name = "Druid Peeska", -- https://en.uesp.net/wiki/Online:Druid_Peeska
        category = "High Isle World Event Daily",
        locations = {
            { placeName = "Gonfalon Bay", cityName = "Gonfalon Bay", zoneId = 1318, cityMapId = 2163, x = 0.4540071785, y = 0.3389952183 },
        },
    },
    {
        name = "Grigerda", -- https://en.uesp.net/wiki/Online:Grigerda
        category = "Bruma Daily Quests",
        locations = {
            { placeName = "Manor House", cityName = "Bruma", zoneId = 181, cityMapId = 16, x = 0.4695066810, y = 0.1727644503 },
        },
    },
    {
        name = "Guruzug", -- https://en.uesp.net/wiki/Online:Guruzug
        category = "Wrothgar Delve Dailies",
        locations = {
            { placeName = "Clan Longhouse", cityName = "Morkul Stronghold", zoneId = 684, x = 0.2577092367, y = 0.2359836767 },
        },
    },
    {
        name = "Guybert Flaubert", -- https://en.uesp.net/wiki/Online:Guybert_Flaubert
        category = "Dragonhold Delve Dailies",
        locations = {
            { placeName = "Senchal Merchant Square", cityName = "Senchal", zoneId = 1133, cityMapId = 1675, x = 0.5404431820, y = 0.6989180446 },
        },
    },
    {
        name = "Gwenyfe", -- https://en.uesp.net/wiki/Online:Gwenyfe
        category = "The Reach World Boss Dailies",
        locations = {
            { placeName = "Markarth", cityName = "Markarth", zoneId = 1207, cityMapId = 1858, x = 0.5935087204, y = 0.5781345963 },
        },
    },
    {
        name = "Hidaver", -- https://en.uesp.net/wiki/Online:Hidaver
        category = "Western Skyrim World Boss Dailies",
        locations = {
            { placeName = "Solitude", cityName = "Solitude", zoneId = 1160, cityMapId = 1773, x = 0.4348280132, y = 0.5176772475 },
        },
    },
    {
        name = "Hjorik", -- https://en.uesp.net/wiki/Online:Hjorik
        category = "Bruma Daily Quests",
        locations = {
            { placeName = "Bruma Chapel", cityName = "Bruma", zoneId = 181, cityMapId = 16, x = 0.4773422182, y = 0.1810999960 },
        },
    },
    {
        name = "Huntmaster Sorim-Nakar", -- https://en.uesp.net/wiki/Online:Huntmaster_Sorim-Nakar
        category = "Ashlander Hunt Dailies",
        locations = {
            { placeName = "Ald'ruhn", cityName = "Ald'ruhn", zoneId = 849, x = 0.3880285621, y = 0.4805646837 },
        },
    },
    {
        name = "Juline Courcelles", -- https://en.uesp.net/wiki/Online:Juline_Courcelles
        category = "Galen Delve Dailies",
        locations = {
            { placeName = "Vastyr", cityName = "Vastyr", zoneId = 1383, cityMapId = 2227, x = 0.5674274564, y = 0.4533120096 },
        },
    },
    {
        name = "Jurana", -- https://en.uesp.net/wiki/Online:Jurana
        category = "Vlastarus Daily Quests",
        locations = {
            { placeName = "Vlastarus", cityName = "Vlastarus", zoneId = 181, cityMapId = 16, x = 0.3062888980, y = 0.6631821990 },
        },
    },
    {
        name = "Justiciar Farowel", -- https://en.uesp.net/wiki/Online:Justiciar_Farowel
        category = "Summerset World Boss Dailies",
        locations = {
            { placeName = "Rinmawen's Plaza", cityName = "Alinor", zoneId = 1011, cityMapId = 1430, x = 0.4420191050, y = 0.6215175390 },
        },
    },
    {
        name = "Justiciar Tanorian", -- https://en.uesp.net/wiki/Online:Justiciar_Tanorian
        category = "Summerset Delve Dailies",
        locations = {
            { placeName = "Rinmawen's Plaza", cityName = "Alinor", zoneId = 1011, cityMapId = 1430, x = 0.4420191050, y = 0.6215175390 },
        },
    },
    {
        name = "Kishka", -- https://en.uesp.net/wiki/Online:Kishka
        category = "Tales of Tribute Daily",
        locations = {
            { placeName = "Gonfalon Gaming Hall", cityName = "Gonfalon Bay", zoneId = 1318, cityMapId = 2163, x = 0.5925837159, y = 0.6735047698 },
        },
    },
    {
        name = "Lector Volonaro", -- https://en.uesp.net/wiki/Online:Lector_Volonaro
        category = "Solstice Delve Dailies",
        locations = {
            { placeName = "Cathedral Square", cityName = "Sunport", zoneId = 1502, cityMapId = 2654, x = 0.5714650750, y = 0.6742879152 },
        },
    },
    {
        name = "Legionary Jaida", -- https://en.uesp.net/wiki/Online:Legionary_Jaida
        category = "West Weald World Event Daily",
        locations = {
            { placeName = "Skingrad", cityName = "Skingrad", zoneId = 1443, cityMapId = 2514, x = 0.6164059043, y = 0.5765205026 },
        },
    },
    {
        name = "Lieutenant Agrance", -- https://en.uesp.net/wiki/Online:Lieutenant_Agrance
        category = "West Weald World Boss Dailies",
        locations = {
            { placeName = "Skingrad", cityName = "Skingrad", zoneId = 1443, cityMapId = 2514, x = 0.6211023331, y = 0.5777600408 },
        },
    },
    {
        name = "Lliae the Quick", -- https://en.uesp.net/wiki/Online:Lliae_the_Quick
        category = "Chorrol and Weynon Priory Daily Quests",
        locations = {
            { placeName = "Chorrol", cityName = "Chorrol", zoneId = 181, cityMapId = 16, x = 0.1737888902, y = 0.3858844340 },
        },
    },
    {
        name = "Luna Beriel", -- https://en.uesp.net/wiki/Online:Luna_Beriel
        category = "Deadlands Delve Dailies",
        locations = {
            { placeName = "Fargrave", cityName = "Fargrave", zoneId = 1283, cityMapId = 2035, x = 0.2527459562, y = 0.3096819520 },
        },
    },
    {
        name = "Mael", -- https://en.uesp.net/wiki/Online:Mael
        category = "Chorrol and Weynon Priory Daily Quests",
        locations = {
            { placeName = "Chorrol", cityName = "Chorrol", zoneId = 181, cityMapId = 16, x = 0.2163755596, y = 0.3975844383 },
        },
    },
    {
        name = "Marunji", -- https://en.uesp.net/wiki/Online:Marunji
        category = "Tales of Tribute Daily",
        locations = {
            { placeName = "Gonfalon Gaming Hall", cityName = "Gonfalon Bay", zoneId = 1318, cityMapId = 2163, x = 0.5925837159, y = 0.6735047698 },
        },
    },
    {
        name = "Master Malkhest", -- https://en.uesp.net/wiki/Online:Master_Malkhest
        category = "Infinite Archive Daily",
        locations = {
            { placeName = "Infinite Archive", cityName = "Infinite Archive", zoneId = 1436, x = 0.4568627477, y = 0.5058823824 },
        },
    },
    {
        name = "Morlia", -- https://en.uesp.net/wiki/Online:Morlia
        category = "Solstice World Boss Dailies",
        locations = {
            { placeName = "Cathedral Square", cityName = "Sunport", zoneId = 1502, cityMapId = 2654, x = 0.5673776865, y = 0.6738621593 },
        },
    },
    {
        name = "Nelerien", -- https://en.uesp.net/wiki/Online:Nelerien
        category = "Vlastarus Daily Quests",
        locations = {
            { placeName = "Vlastarus", cityName = "Vlastarus", zoneId = 181, cityMapId = 16, x = 0.3056488931, y = 0.6583666801 },
        },
    },
    {
        name = "Nisuzi", -- https://en.uesp.net/wiki/Online:Nisuzi
        category = "Northern Elsweyr Delve Dailies",
        locations = {
            { placeName = "Job Brokers' tent", cityName = "Rimmen", zoneId = 1086, cityMapId = 1576, x = 0.3082407117, y = 0.7174170613 },
        },
    },
    {
        name = "Novice Holli", -- https://en.uesp.net/wiki/Online:Novice_Holli
        category = "Clockwork City Delve Dailies",
        locations = {
            { placeName = "Brass Fortress", cityName = "Brass Fortress", zoneId = 980, cityMapId = 1348, x = 0.6162100434, y = 0.5530887842 },
        },
    },
    {
        name = "Numani-Rasi", -- https://en.uesp.net/wiki/Online:Numani-Rasi
        category = "Ashlander Relic Dailies",
        locations = {
            { placeName = "Ald'ruhn", cityName = "Ald'ruhn", zoneId = 849, x = 0.4020166397, y = 0.4626117349 },
        },
    },
    {
        name = "Ordinator Nelyn", -- https://en.uesp.net/wiki/Online:Ordinator_Nelyn
        category = "Necrom World Boss Dailies",
        locations = {
            { placeName = "Necrom", cityName = "Necrom", zoneId = 1414, cityMapId = 2343, x = 0.5233277678, y = 0.5735207200 },
        },
    },
    {
        name = "Ordinator Tandasea", -- https://en.uesp.net/wiki/Online:Ordinator_Tandasea
        category = "Bastion Nymic Daily",
        locations = {
            { placeName = "Necrom", cityName = "Necrom", zoneId = 1414, cityMapId = 2343, x = 0.5240057111, y = 0.5641165972 },
        },
    },
    {
        name = "Ordinator Tilena", -- https://en.uesp.net/wiki/Online:Ordinator_Tilena
        category = "Necrom Delve Dailies",
        locations = {
            { placeName = "Necrom", cityName = "Necrom", zoneId = 1414, cityMapId = 2343, x = 0.5230235457, y = 0.5783270597 },
        },
    },
    {
        name = "Parisse Plouff", -- https://en.uesp.net/wiki/Online:Parisse_Plouff
        category = "High Isle World Boss Dailies",
        locations = {
            { placeName = "Gonfalon Bay", cityName = "Gonfalon Bay", zoneId = 1318, cityMapId = 2163, x = 0.4412081242, y = 0.3052631617 },
        },
    },
    {
        name = "Prefect Antias", -- https://en.uesp.net/wiki/Online:Prefect_Antias
        category = "Cropsford Daily Quests",
        locations = {
            { placeName = "Cropsford", cityName = "Cropsford", zoneId = 181, cityMapId = 16, x = 0.6876888871, y = 0.6351400018 },
        },
    },
    {
        name = "Razgurug", -- https://en.uesp.net/wiki/Online:Razgurug
        category = "Tarnished Dailies",
        locations = {
            { placeName = "Slag Town", cityName = "Brass Fortress", zoneId = 980, cityMapId = 1348, x = 0.6104187369, y = 0.5036413074 },
        },
    },
    {
        name = "Ri'hirr", -- https://en.uesp.net/wiki/Online:Ri'hirr
        category = "Northern Elsweyr World Boss Dailies",
        locations = {
            { placeName = "Job Brokers' tent", cityName = "Rimmen", zoneId = 1086, cityMapId = 1576, x = 0.3098749816, y = 0.7124734521 },
        },
    },
    {
        name = "Speaker Terenus", -- https://en.uesp.net/wiki/Online:Speaker_Terenus
        category = "Dark Brotherhood Sacraments",
        locations = {
            { placeName = "Dark Brotherhood Sanctuary", cityName = "Anvil", zoneId = 823, cityMapId = 1074, x = 0.2401068062, y = 0.6885277629 },
        },
    },
    {
        name = "Swordthane Jylta", -- https://en.uesp.net/wiki/Online:Swordthane_Jylta
        category = "Western Skyrim World Event Daily",
        locations = {
            { placeName = "Solitude", cityName = "Solitude", zoneId = 1160, cityMapId = 1773, x = 0.4142244756, y = 0.5048190951 },
        },
    },
    {
        name = "Sylvian Herius", -- https://en.uesp.net/wiki/Online:Sylvian_Herius
        category = "Cheydinhal Daily Quests",
        locations = {
            { placeName = "Cheydinhal", cityName = "Cheydinhal", zoneId = 181, cityMapId = 16, x = 0.7720400095, y = 0.3961022198 },
        },
    },
    {
        name = "Tinzen", -- https://en.uesp.net/wiki/Online:Tinzen
        category = "Western Skyrim Delve Dailies",
        locations = {
            { placeName = "Solitude", cityName = "Solitude", zoneId = 1160, cityMapId = 1773, x = 0.4278876483, y = 0.5140656829 },
        },
    },
    {
        name = "Traylan Omoril", -- https://en.uesp.net/wiki/Online:Traylan_Omoril
        category = "Vvardenfell Delve Dailies",
        locations = {
            { placeName = "Hall of Justice", cityName = "Vivec City", zoneId = 849, cityMapId = 1287, x = 0.4791199267, y = 0.5571587086 },
        },
    },
    {
        name = "Tuwul", -- https://en.uesp.net/wiki/Online:Tuwul
        category = "Root-Whisper Dailies",
        locations = {
            { placeName = "Root-Whisper Village", cityName = "Root-Whisper Village", zoneId = 726, x = 0.7637448034, y = 0.7447340171 },
        },
    },
    {
        name = "Ufgra gra-Gum", -- https://en.uesp.net/wiki/Online:Ufgra_gra-Gum
        category = "Cropsford Daily Quests",
        locations = {
            { placeName = "Cropsford", cityName = "Cropsford", zoneId = 181, cityMapId = 16, x = 0.6882155538, y = 0.6307377815 },
        },
    },
    {
        name = "Varo Hosidias", -- https://en.uesp.net/wiki/Online:Varo_Hosidias
        category = "Murkmire Delve Dailies",
        locations = {
            { placeName = "Lilmoth", cityName = "Lilmoth", zoneId = 726, cityMapId = 1560, x = 0.4464905560, y = 0.6364693046 },
        },
    },
    {
        name = "Vaveli Indavel", -- https://en.uesp.net/wiki/Online:Vaveli_Indavel
        category = "Deadlands World Boss Dailies",
        locations = {
            { placeName = "Fargrave", cityName = "Fargrave", zoneId = 1283, cityMapId = 2035, x = 0.2459675819, y = 0.3083097339 },
        },
    },
    {
        name = "Vyctoria Girien", -- https://en.uesp.net/wiki/Online:Vyctoria_Girien
        category = "Cheydinhal Daily Quests",
        locations = {
            { placeName = "Cheydinhal", cityName = "Cheydinhal", zoneId = 181, cityMapId = 16, x = 0.7664933205, y = 0.3963666558 },
        },
    },
    {
        name = "Wayllod", -- https://en.uesp.net/wiki/Online:Wayllod
        category = "High Isle Delve Dailies",
        locations = {
            { placeName = "Gonfalon Bay", cityName = "Gonfalon Bay", zoneId = 1318, cityMapId = 2163, x = 0.4452751279, y = 0.3144736886 },
        },
    },
}

-- Maps icon filename keywords (after stripping path/suffix) to localized POI type labels.
-- Add new entries here when ESO introduces new POI icon types.
data.POI_TYPE_NAMES = {
    areaofinterest  = GetString(SI_GPH_MAPSEARCH_LABEL_AREA_OF_INTEREST),
    adventurezone   = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    ayleidruin      = GetString(SI_GPH_MAPSEARCH_LABEL_AYLEID_RUIN),
    ayliedruin      = GetString(SI_GPH_MAPSEARCH_LABEL_AYLEID_RUIN),
    battlefield     = GetString(SI_GPH_MAPSEARCH_LABEL_BATTLEFIELD),
    battleground    = GetString(SI_GPH_MAPSEARCH_LABEL_BATTLEFIELD),
    boss            = GetString(SI_GPH_MAPSEARCH_LABEL_WORLD_BOSS),
    camp            = GetString(SI_GPH_MAPSEARCH_LABEL_CAMP),
    cave            = GetString(SI_GPH_MAPSEARCH_LABEL_CAVE),
    cemetery        = GetString(SI_GPH_MAPSEARCH_LABEL_CEMETERY),
    cemetary        = GetString(SI_GPH_MAPSEARCH_LABEL_CEMETERY),
    city            = GetString(SI_GPH_MAPSEARCH_LABEL_CITY),
    crafting        = GetString(SI_GPH_MAPSEARCH_LABEL_CRAFTING_STATION),
    crypt           = GetString(SI_GPH_MAPSEARCH_LABEL_CRYPT),
    daedricruin     = GetString(SI_GPH_MAPSEARCH_LABEL_DAEDRIC_RUIN),
    darkbrotherhood = GetString(SI_GPH_MAPSEARCH_LABEL_DARK_BROTHERHOOD),
    delve           = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    dock            = GetString(SI_GPH_MAPSEARCH_LABEL_DOCK),
    dungeon         = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    dwemerruin      = GetString(SI_GPH_MAPSEARCH_LABEL_DWEMER_RUIN),
    endlessdungeon  = GetString(SI_GPH_MAPSEARCH_LABEL_ENDLESS_DUNGEON),
    estate          = GetString(SI_GPH_MAPSEARCH_LABEL_ESTATE),
    explorable      = GetString(SI_GPH_MAPSEARCH_LABEL_EXPLORABLE),
    farm            = GetString(SI_GPH_MAPSEARCH_LABEL_FARM),
    gate            = GetString(SI_GPH_MAPSEARCH_LABEL_GATE),
    grove           = GetString(SI_GPH_MAPSEARCH_LABEL_GROVE),
    harborage       = GetString(SI_GPH_MAPSEARCH_LABEL_HARBORAGE),
    house           = GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE),
    instance        = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    groupboss       = GetString(SI_GPH_MAPSEARCH_LABEL_WORLD_BOSS),
    groupdelve      = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    groupinstance   = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    -- explicit group_ keys so poi_group_* icons resolve correctly
    group_boss            = GetString(SI_GPH_MAPSEARCH_LABEL_WORLD_BOSS),
    group_delve           = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    group_instance        = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    group_dungeon         = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    group_house           = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_INSTANCE),
    group_keep            = GetString(SI_GPH_MAPSEARCH_LABEL_KEEP),
    group_cave            = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    group_areaofinterest  = GetString(SI_GPH_MAPSEARCH_LABEL_AREA_OF_INTEREST),
    group_cemetery        = GetString(SI_GPH_MAPSEARCH_LABEL_CEMETERY),
    group_lighthouse      = GetString(SI_GPH_MAPSEARCH_LABEL_LIGHTHOUSE),
    group_ruin            = GetString(SI_GPH_MAPSEARCH_LABEL_RUIN),
    group_portal          = GetString(SI_GPH_MAPSEARCH_LABEL_DOLMEN),
    group_estate          = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_TRIAL),
    keep            = GetString(SI_GPH_MAPSEARCH_LABEL_KEEP),
    lighthouse      = GetString(SI_GPH_MAPSEARCH_LABEL_LIGHTHOUSE),
    mine            = GetString(SI_GPH_MAPSEARCH_LABEL_MINE),
    mine_compete    = GetString(SI_GPH_MAPSEARCH_LABEL_MINE),
    mine_incompete  = GetString(SI_GPH_MAPSEARCH_LABEL_MINE),
    mundus          = GetString(SI_GPH_MAPSEARCH_LABEL_MUNDUS_STONE),
    mushromtower    = GetString(SI_GPH_MAPSEARCH_LABEL_MUSHROOM_TOWER),
    portal          = GetString(SI_GPH_MAPSEARCH_LABEL_DOLMEN),
    raiddungeon     = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_TRIAL),
    ruin            = GetString(SI_GPH_MAPSEARCH_LABEL_RUIN),
    sewer           = GetString(SI_GPH_MAPSEARCH_LABEL_SEWER),
    shrine          = GetString(SI_GPH_MAPSEARCH_LABEL_SHRINE),
    shrine_vampire  = GetString(SI_GPH_MAPSEARCH_LABEL_VAMPIRE_SHRINE),
    shrine_werewolf = GetString(SI_GPH_MAPSEARCH_LABEL_WEREWOLF_SHRINE),
    solotrial       = GetString(SI_GPH_MAPSEARCH_LABEL_SOLO_TRIAL),
    tower           = GetString(SI_GPH_MAPSEARCH_LABEL_TOWER),
    town            = GetString(SI_GPH_MAPSEARCH_LABEL_TOWN),
    transit         = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT),
    lift            = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT),
    nord_boat       = GetString(SI_GPH_MAPSEARCH_LABEL_NORD_BOAT),
    dwemergear      = GetString(SI_GPH_MAPSEARCH_LABEL_LIFT),
    ic_boneshard         = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_darkether         = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_tinyclaw          = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_marklegion        = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_monstrousteeth    = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_planararmorscraps = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_daedricshackles   = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    ic_daedricembers     = GetString(SI_GPH_MAPSEARCH_LABEL_IMPERIAL_CITY),
    adventurezone_entrance             = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_jumppad              = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_faction_ruckus       = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_faction_thousandeyes = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_faction_glittering   = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_skirmish             = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    adventurezone_contentgrouptimed    = GetString(SI_GPH_MAPSEARCH_LABEL_ADVENTURE_ZONE),
    wayshrine    = GetString(SI_GPH_MAPSEARCH_LABEL_WAYSHRINE),
    icon_missing = GetString(SI_GPH_MAPSEARCH_LABEL_UNKNOWN),
    unknown      = GetString(SI_GPH_MAPSEARCH_LABEL_UNKNOWN),
}

-- Direct label lookup by ESO's poiType enum (avoids icon parsing for unambiguous types).
-- Type 2 is intentionally absent: it covers both Mundus Stones and Great Lifts,
-- so icon parsing is required to tell them apart.
data.POI_TYPE_DIRECT = {
    [3] = GetString(SI_GPH_MAPSEARCH_LABEL_DELVE),
    [4] = GetString(SI_GPH_MAPSEARCH_LABEL_DOLMEN),
    [5] = GetString(SI_GPH_MAPSEARCH_LABEL_PUBLIC_DUNGEON),
    [6] = GetString(SI_GPH_MAPSEARCH_LABEL_GROUP_DUNGEON),
    [7] = GetString(SI_GPH_MAPSEARCH_LABEL_HOUSE),
}

-- Crafted set map-location lookup: zoneId -> locationName -> { setId, traits }.
-- These entries come from GetNumMapLocations service pins instead of POIs.
data.CRAFTING_SET_LOCATIONS = {
    [267] = { -- Eyevea
        ["Eyes of Mara"] = { setId = 87, traits = 8 }, -- Eyes of Mara
        ["Shalidor's Curse"] = { setId = 95, traits = 8 }, -- Shalidor's Curse
    },
    [642] = { -- The Earth Forge
        ["The Earth Forge"] = { setId = 92, traits = 8 }, -- Kagrenac's Hope
        ["Pressure Room III"] = { setId = 84, traits = 8 }, -- Orgnum's Scales
    },
}

-- Crafted set POI lookup: zoneId -> poiIndex -> { setId, traits }.
-- MapSearch.lua resolves localized set names and bonuses through ESO's
-- GetItemSetInfo/GetItemSetBonusInfo.
data.CRAFTING_SET_POIS = {
    [3] = { -- Glenumbra
        [56] = { setId = 40, traits = 2 }, -- Night's Silence - Mesanthano's Tower
        [60] = { setId = 37, traits = 2 }, -- Death's Wind - Chill House
        [61] = { setId = 54, traits = 2 }, -- Ashen Grip - Par Molag
    },
    [19] = { -- Stormhaven
        [56] = { setId = 75, traits = 3 }, -- Torug's Pact - Hammerdeath Workshop
        [57] = { setId = 43, traits = 3 }, -- Armor of the Seducer - Fisherman's Island
        [59] = { setId = 38, traits = 3 }, -- Twilight's Embrace - Windridge Warehouse
    },
    [20] = { -- Rivenspire
        [52] = { setId = 48, traits = 4 }, -- Magnus' Gift - Veawend Ede
        [53] = { setId = 41, traits = 4 }, -- Whitestrake's Retribution - Westwind Lighthouse
        [57] = { setId = 78, traits = 4 }, -- Hist Bark - Trader's Rest
    },
    [41] = { -- Stonefalls
        [54] = { setId = 37, traits = 2 }, -- Death's Wind - Armature's Upheaval
        [56] = { setId = 40, traits = 2 }, -- Night's Silence - Steamfont Cavern
        [59] = { setId = 54, traits = 2 }, -- Ashen Grip - Magmaflow Overlook
    },
    [57] = { -- Deshaan
        [51] = { setId = 38, traits = 3 }, -- Twilight's Embrace - Avayan's Farm
        [52] = { setId = 75, traits = 3 }, -- Torug's Pact - Lake Hlaalu Retreat
        [53] = { setId = 43, traits = 3 }, -- Armor of the Seducer - Berezan's Mine
    },
    [58] = { -- Malabal Tor
        [53] = { setId = 81, traits = 5 }, -- Song of Lamae - Sleepy Senche Overlook
        [56] = { setId = 82, traits = 5 }, -- Alessia's Bulwark - Chancel of Divine Entreaty
        [58] = { setId = 44, traits = 5 }, -- Vampire's Kiss - Matthild's Last Venture
    },
    [92] = { -- Bangkorai
        [49] = { setId = 51, traits = 6 }, -- Night Mother's Gaze - Silaseli Ruins
        [55] = { setId = 79, traits = 6 }, -- Willow's Path - Viridian Hideaway
        [57] = { setId = 80, traits = 6 }, -- Hunding's Rage - Wethers' Cleft
    },
    [101] = { -- Eastmarch
        [52] = { setId = 82, traits = 5 }, -- Alessia's Bulwark - Hammerhome
        [54] = { setId = 81, traits = 5 }, -- Song of Lamae - Tinkerer Tobin's Workshop
        [55] = { setId = 44, traits = 5 }, -- Vampire's Kiss - Crimson Kada's Crafting Cavern
    },
    [103] = { -- The Rift
        [53] = { setId = 79, traits = 6 }, -- Willow's Path - Smokefrost Vigil
        [57] = { setId = 51, traits = 6 }, -- Night Mother's Gaze - Eldbjorg's Hideaway
        [59] = { setId = 80, traits = 6 }, -- Hunding's Rage - Trollslayer's Gully
    },
    [104] = { -- Alik'r Desert
        [54] = { setId = 81, traits = 5 }, -- Song of Lamae - Rkulftzel
        [55] = { setId = 82, traits = 5 }, -- Alessia's Bulwark - Alezer Kotu
        [59] = { setId = 44, traits = 5 }, -- Vampire's Kiss - Artisan's Oasis
    },
    [108] = { -- Greenshade
        [50] = { setId = 41, traits = 4 }, -- Whitestrake's Retribution - Lanalda Pond
        [52] = { setId = 48, traits = 4 }, -- Magnus' Gift - Arananga
        [55] = { setId = 78, traits = 4 }, -- Hist Bark - Rootwatch Tower
    },
    [117] = { -- Shadowfen
        [50] = { setId = 48, traits = 4 }, -- Magnus' Gift - Xal Haj-Ei Shrine
        [57] = { setId = 78, traits = 4 }, -- Hist Bark - Hatchling's Crown
        [59] = { setId = 41, traits = 4 }, -- Whitestrake's Retribution - Weeping Wamasu Falls
    },
    [181] = { -- Cyrodiil
        [107] = { setId = 482, traits = 3 }, -- Dauntless Combatant - Cropsford Armory
        [108] = { setId = 480, traits = 3 }, -- Critical Riposte - Vlastarus Armory
        [109] = { setId = 481, traits = 3 }, -- Unchained Aggressor - Bruma Armory
    },
    [347] = { -- Coldharbour
        [47] = { setId = 74, traits = 8 }, -- Spectre's Eye - Deathspinner's Lair
        [56] = { setId = 73, traits = 8 }, -- Oblivion's Foe - Font of Schemes
    },
    [381] = { -- Auridon
        [50] = { setId = 40, traits = 2 }, -- Night's Silence - Hightide Keep
        [55] = { setId = 54, traits = 2 }, -- Ashen Grip - Beacon Falls
        [56] = { setId = 37, traits = 2 }, -- Death's Wind - Eastshore Islets Camp
    },
    [382] = { -- Reaper's March
        [48] = { setId = 51, traits = 6 }, -- Night Mother's Gaze - Old Town Cavern
        [51] = { setId = 80, traits = 6 }, -- Hunding's Rage - Broken Arch
        [52] = { setId = 79, traits = 6 }, -- Willow's Path - Greenspeaker's Grove
    },
    [383] = { -- Grahtwood
        [49] = { setId = 38, traits = 3 }, -- Twilight's Embrace - Vineshade Lodge
        [52] = { setId = 43, traits = 3 }, -- Armor of the Seducer - Temple of the Eight
        [55] = { setId = 75, traits = 3 }, -- Torug's Pact - Fisherman's Isle
    },
    [584] = { -- Imperial City
        [22] = { setId = 177, traits = 7 }, -- Redistributor - Arboretum Armory
        [23] = { setId = 176, traits = 5 }, -- Noble's Conquest - Nobles Armory
        [24] = { setId = 178, traits = 9 }, -- Armor Master - Memorial Armory
    },
    [684] = { -- Wrothgar
        [51] = { setId = 208, traits = 3 }, -- Trial by Fire - Malacath Statue
        [52] = { setId = 207, traits = 6 }, -- Law of Julianos - Boreal Forge
        [53] = { setId = 219, traits = 9 }, -- Morkuldin - Morkuldin Forge
    },
    [726] = { -- Murkmire
        [17] = { setId = 410, traits = 4 }, -- Might of the Lost Legion - Ruined Village
        [18] = { setId = 409, traits = 2 }, -- Naga Shaman - Deep Swamp Forge
        [19] = { setId = 408, traits = 7 }, -- Grave-Stake Collector - Sweet Breeze Overlook
    },
    [816] = { -- Hew's Bane
        [19] = { setId = 226, traits = 9 }, -- Eternal Hunt - The Lost Pavilion
        [21] = { setId = 224, traits = 5 }, -- Tava's Favor - Forebear's Junction
        [24] = { setId = 225, traits = 7 }, -- Clever Alchemist - No Shira Workshop
    },
    [823] = { -- Gold Coast
        [18] = { setId = 240, traits = 5 }, -- Kvatch Gladiator - Marja's Mill
        [19] = { setId = 241, traits = 7 }, -- Varen's Legacy - Strid River Artisans Camp
        [20] = { setId = 242, traits = 9 }, -- Pelinal's Wrath - Colovian Revolt Forge Yard
    },
    [849] = { -- Vvardenfell
        [44] = { setId = 323, traits = 3 }, -- Assassin's Guile - Marandus
        [45] = { setId = 324, traits = 8 }, -- Daedric Trickery - Randas Ancestral Tomb
        [46] = { setId = 325, traits = 6 }, -- Shacklebreaker - Zergonipal
    },
    [888] = { -- Craglorn
        [12] = { setId = 161, traits = 9 }, -- Twice-Born Star - Atelier of the Twice-Born Star
        [43] = { setId = 148, traits = 8 }, -- Way of the Arena - Lanista's Waystation
    },
    [980] = { -- Clockwork City
        [19] = { setId = 351, traits = 2 }, -- Innate Axiom - The Refurbishing Yard
        [20] = { setId = 353, traits = 6 }, -- Mechanical Acuity - Pavilion of Artifice
    },
    [981] = { -- Brass Fortress
        [3] = { setId = 352, traits = 4 }, -- Fortified Brass - Restricted Brassworks
    },
    [1011] = { -- Summerset
        [33] = { setId = 385, traits = 3 }, -- Adept Rider - Shimmerene Dockworks
        [34] = { setId = 387, traits = 9 }, -- Nocturnal's Favor - Augury Basin
    },
    [1027] = { -- Artaeum
        [1] = { setId = 386, traits = 6 }, -- Sload's Semblance - Artaeum Craftworks
    },
    [1086] = { -- Northern Elsweyr
        [26] = { setId = 438, traits = 5 }, -- Senche-raht's Grit - Starlight Adeptorium
        [27] = { setId = 437, traits = 8 }, -- Coldharbour's Favorite - Valenwood Border Artisan Camp
        [28] = { setId = 439, traits = 3 }, -- Vastarie's Tutelage - Rimmen Masterworks
    },
    [1133] = { -- Southern Elsweyr
        [11] = { setId = 470, traits = 9 }, -- New Moon Acolyte - Fur-Forge Cove
        [12] = { setId = 468, traits = 3 }, -- Daring Corsair - Cat's-Claw Station
    },
    [1146] = { -- Tideholm
        [2] = { setId = 469, traits = 6 }, -- Ancient Dragonguard - Dragonguard Armory
    },
    [1160] = { -- Western Skyrim
        [48] = { setId = 490, traits = 5 }, -- Stuhn's Favor - Hunter's House
        [49] = { setId = 491, traits = 7 }, -- Dragon's Appetite - Dragon's Belly
    },
    [1161] = { -- Blackreach: Greymoor Caverns
        [22] = { setId = 506, traits = 3 }, -- Spell Parasite - Parasite's Cave
    },
    [1207] = { -- The Reach
        [4] = { setId = 540, traits = 6 }, -- Legacy of Karth - Druadach Redoubt
        [17] = { setId = 539, traits = 3 }, -- Red Eagle's Fury - Red Eagle Redoubt
    },
    [1208] = { -- Blackreach: Arkthzand Cavern
        [11] = { setId = 541, traits = 9 }, -- Aetherial Ascension - Philosopher's Cradle
    },
    [1261] = { -- Blackwood
        [50] = { setId = 584, traits = 5 }, -- Diamond's Victory - Pentric Run
        [51] = { setId = 583, traits = 7 }, -- Heartland Conqueror - Sariellen's Sword
        [52] = { setId = 582, traits = 3 }, -- Hist Whisperer - Withered Root
    },
    [1283] = { -- The Shambles
        [1] = { setId = 612, traits = 5 }, -- Iron Flask - Forgotten Feretory
    },
    [1286] = { -- The Deadlands
        [19] = { setId = 610, traits = 3 }, -- Wretched Vitality - Stormwright's Cleft
        [20] = { setId = 611, traits = 7 }, -- Deadlands Demolisher - The Razorworks
    },
    [1318] = { -- High Isle
        [36] = { setId = 641, traits = 5 }, -- Serpent's Disdain - Stonelore Forge and Craft
        [37] = { setId = 640, traits = 3 }, -- Order's Wrath - Steadfast Hammer and Saw
        [38] = { setId = 642, traits = 7 }, -- Druid's Braid - Hidden Foundry
    },
    [1383] = { -- Galen
        [8] = { setId = 678, traits = 3 }, -- Old Growth Brewer - Old Port Mornard
        [9] = { setId = 677, traits = 7 }, -- Chimera's Rebuke - Fort Avrippe
        [10] = { setId = 679, traits = 5 }, -- Claw of the Forest Wraith - Oaken Forge
    },
    [1413] = { -- Apocrypha
        [18] = { setId = 697, traits = 7 }, -- Seeker Synthesis - Versicolor Carrels
        [19] = { setId = 695, traits = 5 }, -- Shattered Fate - Artisan's Hermitage
    },
    [1414] = { -- Telvanni Peninsula
        [15] = { setId = 696, traits = 3 }, -- Telvanni Efficiency - Tel Hlurag Ven
    },
    [1443] = { -- West Weald
        [3] = { setId = 764, traits = 5 }, -- Highland Sentinel - Leftwheal Granary
        [4] = { setId = 763, traits = 3 }, -- Tharriker's Strike - Singer's Outpost
        [5] = { setId = 765, traits = 7 }, -- Threads of War - Deserter's Lagoon
    },
    [1502] = { -- Solstice
        [51] = { setId = 809, traits = 5 }, -- Tide-Born Wildstalker - Tide-Born Foundry
        [74] = { setId = 808, traits = 3 }, -- Shared Burden - Salt-Air Station
        [75] = { setId = 810, traits = 7 }, -- Fellowship's Fortitude - Fellowship Forge
    },
}
