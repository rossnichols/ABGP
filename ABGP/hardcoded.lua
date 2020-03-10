local _G = _G;
local ABGP = ABGP;

local date = date;

_G.ABGP_Data = {};
_G.ABGP_Data[ABGP.Phases.p1] = {
	["gpHistory"] = {
		{
			["player"] = "Saccrilege",
			["item"] = "Nemesis Skullcap",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["gp"] = 250,
		}, -- [1]
		{
			["gp"] = 0,
			["item"] = "Eskhandar's Collar",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
			["player"] = "Cleaves",
		}, -- [2]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Dhafra",
		}, -- [3]
		{
			["gp"] = 0,
			["item"] = "Dragonstalker's Helm",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16939|h[Dragonstalker's Helm]|h|r",
			["player"] = "Bigsausage",
		}, -- [4]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Juicebolt",
		}, -- [5]
		{
			["player"] = "Xan",
			["item"] = "Ring of Binding",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [6]
		{
			["player"] = "Huntingkabu",
			["item"] = "Dragonstalker's Helm",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16939|h[Dragonstalker's Helm]|h|r",
			["gp"] = 250,
		}, -- [7]
		{
			["player"] = "Righteous",
			["item"] = "Essence of the Pure Flame",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
			["gp"] = 0,
		}, -- [8]
		{
			["player"] = "Cleaves",
			["item"] = "Onslaught Girdle",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:19137|h[Onslaught Girdle]|h|r",
			["gp"] = 300,
		}, -- [9]
		{
			["player"] = "Groggy",
			["item"] = "Judgement Legplates",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16954|h[Judgement Legplates]|h|r",
			["gp"] = 0,
		}, -- [10]
		{
			["player"] = "Darknéss",
			["item"] = "Wild Growth Spaulders",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r",
			["gp"] = 300,
		}, -- [11]
		{
			["player"] = "Sausage",
			["item"] = "Robes of Prophecy",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16815|h[Robes of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [12]
		{
			["gp"] = 0,
			["item"] = "Breastplate of Might",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16865|h[Breastplate of Might]|h|r",
			["player"] = "Coop",
		}, -- [13]
		{
			["player"] = "Xane",
			["item"] = "Arcanist Mantle",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16797|h[Arcanist Mantle]|h|r",
			["gp"] = 0,
		}, -- [14]
		{
			["player"] = "Xane",
			["item"] = "Mana Igniting Cord",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [15]
		{
			["gp"] = 0,
			["item"] = "Aurastone Hammer",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
			["player"] = "Quellia",
		}, -- [16]
		{
			["gp"] = 0,
			["item"] = "Gutgore Ripper",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:17071|h[Gutgore Ripper]|h|r",
			["player"] = "Suzukagozen",
		}, -- [17]
		{
			["player"] = "Coop",
			["item"] = "Wristguards of Stability",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:19146|h[Wristguards of Stability]|h|r",
			["gp"] = 150,
		}, -- [18]
		{
			["player"] = "Suzukagozen",
			["item"] = "Nightslayer Gloves",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16826|h[Nightslayer Gloves]|h|r",
			["gp"] = 0,
		}, -- [19]
		{
			["player"] = "Yoink",
			["item"] = "Nightslayer Pants",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16822|h[Nightslayer Pants]|h|r",
			["gp"] = 0,
		}, -- [20]
		{
			["player"] = "Esconar",
			["item"] = "Flameguard Gauntlets",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:19143|h[Flameguard Gauntlets]|h|r",
			["gp"] = 100,
		}, -- [21]
		{
			["player"] = "Saccrilege",
			["item"] = "Felheart Gloves",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r",
			["gp"] = 0,
		}, -- [22]
		{
			["player"] = "Xane",
			["item"] = "Arcanist Boots",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16800|h[Arcanist Boots]|h|r",
			["gp"] = 150,
		}, -- [23]
		{
			["gp"] = 0,
			["item"] = "Vambraces of Prophecy",
			["date"] = "03/05/20",
			["itemLink"] = "|cffa335ee|Hitem:16819|h[Vambraces of Prophecy]|h|r",
			["player"] = "Sausage",
		}, -- [24]
		{
			["player"] = "Saccrilege",
			["item"] = "Fang of the Mystics",
			["date"] = "03/04/20",
			["itemLink"] = "|cffa335ee|Hitem:17070|h[Fang of the Mystics]|h|r",
			["gp"] = 320,
		}, -- [25]
		{
			["player"] = "Tikki",
			["item"] = "Ring of Binding",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [26]
		{
			["player"] = "Oya",
			["item"] = "Deathbringer",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:17068|h[Deathbringer]|h|r",
			["gp"] = 200,
		}, -- [27]
		{
			["player"] = "Saccrilege",
			["item"] = "Head of Onyxia",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 0,
		}, -- [28]
		{
			["player"] = "Juicetea",
			["item"] = "Bloodfang Hood",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16908|h[Bloodfang Hood]|h|r",
			["gp"] = 0,
		}, -- [29]
		{
			["player"] = "Frostishot",
			["item"] = "Core Hound Tooth",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:18805|h[Core Hound Tooth]|h|r",
			["gp"] = 250,
		}, -- [30]
		{
			["player"] = "Nadrell",
			["item"] = "Azuresong Mageblade",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:17103|h[Azuresong Mageblade]|h|r",
			["gp"] = 300,
		}, -- [31]
		{
			["player"] = "Starlight",
			["item"] = "Aurastone Hammer",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
			["gp"] = 50,
		}, -- [32]
		{
			["player"] = "Clem",
			["item"] = "Choker of Enlightenment",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
			["gp"] = 60,
		}, -- [33]
		{
			["player"] = "Xanido",
			["item"] = "Arcanist Crown",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16795|h[Arcanist Crown]|h|r",
			["gp"] = 200,
		}, -- [34]
		{
			["player"] = "Zomby",
			["item"] = "Band of Accuria",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:17063|h[Band of Accuria]|h|r",
			["gp"] = 300,
		}, -- [35]
		{
			["player"] = "Huntingkabu",
			["item"] = "Giantstalker's Boots",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16849|h[Giantstalker's Boots]|h|r",
			["gp"] = 150,
		}, -- [36]
		{
			["player"] = "Xan",
			["item"] = "Choker of Enlightenment",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
			["gp"] = 60,
		}, -- [37]
		{
			["player"] = "Coop",
			["item"] = "Deathbringer",
			["date"] = "02/11/20",
			["itemLink"] = "|cffa335ee|Hitem:17068|h[Deathbringer]|h|r",
			["gp"] = 200,
		}, -- [38]
		{
			["player"] = "Jearom",
			["item"] = "Eskhandar's Collar",
			["date"] = "02/11/20",
			["itemLink"] = "|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
			["gp"] = 0,
		}, -- [39]
		{
			["player"] = "Tracer",
			["item"] = "Aged Core Leather Gloves",
			["date"] = "02/11/20",
			["itemLink"] = "|cffa335ee|Hitem:18823|h[Aged Core Leather Gloves]|h|r",
			["gp"] = 200,
		}, -- [40]
		{
			["player"] = "Quellia",
			["item"] = "Dragon's Blood Cape",
			["date"] = "02/11/20",
			["itemLink"] = "|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r",
			["gp"] = 100,
		}, -- [41]
		{
			["player"] = "Xane",
			["item"] = "Sapphiron Drape",
			["date"] = "02/11/20",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [42]
		{
			["player"] = "Cleaves",
			["item"] = "Blastershot Launcher",
			["date"] = "02/11/20",
			["itemLink"] = "|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
			["gp"] = 100,
		}, -- [43]
		{
			["player"] = "Gyda",
			["item"] = "Puissant Cape",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:18541|h[Puissant Cape]|h|r",
			["gp"] = 150,
		}, -- [44]
		{
			["player"] = "Azuj",
			["item"] = "Vis'kag the Bloodletter",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:17075|h[Vis'kag the Bloodletter]|h|r",
			["gp"] = 300,
		}, -- [45]
		{
			["gp"] = 0,
			["item"] = "Cloak of the Shrouded Mists",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
			["player"] = "Huntingkabu",
		}, -- [46]
		{
			["player"] = "Starlight",
			["item"] = "Stormrage Legguards",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:16901|h[Stormrage Legguards]|h|r",
			["gp"] = 75,
		}, -- [47]
		{
			["player"] = "Tikki",
			["item"] = "Wristguards of True Flight",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:18812|h[Wristguards of True Flight]|h|r",
			["gp"] = 30,
		}, -- [48]
		{
			["player"] = "Friend",
			["item"] = "Robe of Volatile Power",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r",
			["gp"] = 300,
		}, -- [49]
		{
			["player"] = "Clem",
			["item"] = "Mana Igniting Cord",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [50]
		{
			["player"] = "Jearom",
			["item"] = "Obsidian Edged Blade",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r",
			["gp"] = 0,
		}, -- [51]
		{
			["player"] = "Gyda",
			["item"] = "Nightslayer Pants",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:16822|h[Nightslayer Pants]|h|r",
			["gp"] = 0,
		}, -- [52]
		{
			["player"] = "Klisk",
			["item"] = "Medallion of Steadfast Might",
			["date"] = "02/04/20",
			["itemLink"] = "|cffa335ee|Hitem:17065|h[Medallion of Steadfast Might]|h|r",
			["gp"] = 150,
		}, -- [53]
		{
			["player"] = "Xanido",
			["item"] = "Cold Snap",
			["date"] = "02/02/20",
			["itemLink"] = "|cffa335ee|Hitem:19130|h[Cold Snap]|h|r",
			["gp"] = 100,
		}, -- [54]
		{
			["player"] = "Xan",
			["item"] = "Fel Infused Leggings",
			["date"] = "02/01/20",
			["itemLink"] = "|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
			["gp"] = 300,
		}, -- [55]
		{
			["player"] = "Xan",
			["item"] = "Sapphiron Drape",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [56]
		{
			["gp"] = 0,
			["item"] = "Halo of Transcendence",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["player"] = "Soggybottom",
		}, -- [57]
		{
			["player"] = "Sausage",
			["item"] = "Halo of Transcendence",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["gp"] = 250,
		}, -- [58]
		{
			["player"] = "Lago",
			["item"] = "Leggings of Transcendence",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r",
			["gp"] = 200,
		}, -- [59]
		{
			["player"] = "Sausage",
			["item"] = "Leggings of Transcendence",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r",
			["gp"] = 200,
		}, -- [60]
		{
			["player"] = "Tikki",
			["item"] = "Band of Accuria",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:17063|h[Band of Accuria]|h|r",
			["gp"] = 300,
		}, -- [61]
		{
			["player"] = "Bakedpancake",
			["item"] = "Cauterizing Band",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:19140|h[Cauterizing Band]|h|r",
			["gp"] = 250,
		}, -- [62]
		{
			["player"] = "Jearom",
			["item"] = "Blastershot Launcher",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
			["gp"] = 100,
		}, -- [63]
		{
			["player"] = "Starlight",
			["item"] = "Cenarion Helm",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16834|h[Cenarion Helm]|h|r",
			["gp"] = 0,
		}, -- [64]
		{
			["player"] = "Priestpimp",
			["item"] = "Circlet of Prophecy",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16813|h[Circlet of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [65]
		{
			["player"] = "Nadrell",
			["item"] = "Obsidian Edged Blade",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r",
			["gp"] = 0,
		}, -- [66]
		{
			["gp"] = 0,
			["item"] = "Gauntlets of Might",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["player"] = "Oya",
		}, -- [67]
		{
			["gp"] = 0,
			["item"] = "Sabatons of Might",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
			["player"] = "Esconar",
		}, -- [68]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Leggings",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:16847|h[Giantstalker's Leggings]|h|r",
			["gp"] = 150,
		}, -- [69]
		{
			["player"] = "Azuj",
			["item"] = "Striker's Mark",
			["date"] = "01/28/20",
			["itemLink"] = "|cffa335ee|Hitem:17069|h[Striker's Mark]|h|r",
			["gp"] = 100,
		}, -- [70]
		{
			["player"] = "Quellia",
			["item"] = "Doomhide Gauntlets",
			["date"] = "01/22/20",
			["itemLink"] = "|cffa335ee|Hitem:18544|h[Doomhide Gauntlets]|h|r",
			["gp"] = 75,
		}, -- [71]
		{
			["player"] = "Friend",
			["item"] = "Fang of the Mystics",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:17070|h[Fang of the Mystics]|h|r",
			["gp"] = 320,
		}, -- [72]
		{
			["gp"] = 0,
			["item"] = "Helm of Wrath",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
			["player"] = "Esconar",
		}, -- [73]
		{
			["gp"] = 0,
			["item"] = "Sapphiron Drape",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["player"] = "Clem",
		}, -- [74]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Darknéss",
		}, -- [75]
		{
			["gp"] = 0,
			["item"] = "Legplates of Wrath",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["player"] = "Esconar",
		}, -- [76]
		{
			["player"] = "Xanido",
			["item"] = "Band of Sulfuras",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:19138|h[Band of Sulfuras]|h|r",
			["gp"] = 0,
		}, -- [77]
		{
			["player"] = "Tracer",
			["item"] = "Band of Accuria",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:17063|h[Band of Accuria]|h|r",
			["gp"] = 300,
		}, -- [78]
		{
			["gp"] = 0,
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["player"] = "Clem",
		}, -- [79]
		{
			["player"] = "Lunamar",
			["item"] = "Arcanist Bindings",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16799|h[Arcanist Bindings]|h|r",
			["gp"] = 60,
		}, -- [80]
		{
			["player"] = "Juicetea",
			["item"] = "Nightslayer Chestpiece",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16820|h[Nightslayer Chestpiece]|h|r",
			["gp"] = 100,
		}, -- [81]
		{
			["player"] = "Darknéss",
			["item"] = "Robe of Volatile Power",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r",
			["gp"] = 300,
		}, -- [82]
		{
			["player"] = "Klue",
			["item"] = "Felheart Bracers",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16804|h[Felheart Bracers]|h|r",
			["gp"] = 60,
		}, -- [83]
		{
			["player"] = "Groggy",
			["item"] = "Lawbringer Bracers",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16857|h[Lawbringer Bracers]|h|r",
			["gp"] = 0,
		}, -- [84]
		{
			["player"] = "Soggybottom",
			["item"] = "Boots of Prophecy",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16811|h[Boots of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [85]
		{
			["player"] = "Nadrell",
			["item"] = "Lawbringer Spaulders",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16856|h[Lawbringer Spaulders]|h|r",
			["gp"] = 0,
		}, -- [86]
		{
			["player"] = "Cleaves",
			["item"] = "Quick Strike Ring",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:18821|h[Quick Strike Ring]|h|r",
			["gp"] = 200,
		}, -- [87]
		{
			["player"] = "Nadrell",
			["item"] = "Lawbringer Helm",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16854|h[Lawbringer Helm]|h|r",
			["gp"] = 0,
		}, -- [88]
		{
			["player"] = "Groggy",
			["item"] = "Robe of Volatile Power",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r",
			["gp"] = 300,
		}, -- [89]
		{
			["gp"] = 0,
			["item"] = "Pants of Prophecy",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16814|h[Pants of Prophecy]|h|r",
			["player"] = "Xan",
		}, -- [90]
		{
			["gp"] = 0,
			["item"] = "Legplates of Might",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
			["player"] = "Esconar",
		}, -- [91]
		{
			["player"] = "Krustytop",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "01/21/20",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [92]
		{
			["player"] = "Groggy",
			["item"] = "Flayed Doomguard Belt",
			["date"] = "01/15/20",
			["itemLink"] = "|cffa335ee|Hitem:19134|h[Flayed Doomguard Belt]|h|r",
			["gp"] = 30,
		}, -- [93]
		{
			["player"] = "Esconar",
			["item"] = "Puissant Cape",
			["date"] = "01/15/20",
			["itemLink"] = "|cffa335ee|Hitem:18541|h[Puissant Cape]|h|r",
			["gp"] = 150,
		}, -- [94]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Soggybottom",
		}, -- [95]
		{
			["gp"] = 0,
			["item"] = "Nemesis Skullcap",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["player"] = "Azuj",
		}, -- [96]
		{
			["gp"] = 0,
			["item"] = "Stormrage Cover",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16900|h[Stormrage Cover]|h|r",
			["player"] = "Righteous",
		}, -- [97]
		{
			["gp"] = 0,
			["item"] = "Eskhandar's Collar",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
			["player"] = "Coop",
		}, -- [98]
		{
			["player"] = "Xanido",
			["item"] = "Netherwind Pants",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16915|h[Netherwind Pants]|h|r",
			["gp"] = 250,
		}, -- [99]
		{
			["player"] = "Tracer",
			["item"] = "Perdition's Blade",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:18816|h[Perdition's Blade]|h|r",
			["gp"] = 300,
		}, -- [100]
		{
			["player"] = "Frostishot",
			["item"] = "Dragonstalker's Legguards",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16938|h[Dragonstalker's Legguards]|h|r",
			["gp"] = 250,
		}, -- [101]
		{
			["player"] = "Oya",
			["item"] = "Onslaught Girdle",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:19137|h[Onslaught Girdle]|h|r",
			["gp"] = 300,
		}, -- [102]
		{
			["gp"] = 0,
			["item"] = "The Eye of Divinity",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["player"] = "Sausage",
		}, -- [103]
		{
			["player"] = "Friend",
			["item"] = "Felheart Robes",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16809|h[Felheart Robes]|h|r",
			["gp"] = 0,
		}, -- [104]
		{
			["player"] = "Marizol",
			["item"] = "Staff of Dominance",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:18842|h[Staff of Dominance]|h|r",
			["gp"] = 300,
		}, -- [105]
		{
			["gp"] = 0,
			["item"] = "Bracers of Might",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["player"] = "Jearom",
		}, -- [106]
		{
			["player"] = "Righteous",
			["item"] = "Robe of Volatile Power",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r",
			["gp"] = 300,
		}, -- [107]
		{
			["player"] = "Klue",
			["item"] = "Seal of the Archmagus",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [108]
		{
			["player"] = "Lago",
			["item"] = "Vambraces of Prophecy",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16819|h[Vambraces of Prophecy]|h|r",
			["gp"] = 100,
		}, -- [109]
		{
			["gp"] = 0,
			["item"] = "Sabatons of Might",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [110]
		{
			["gp"] = 0,
			["item"] = "Gauntlets of Might",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["player"] = "Esconar",
		}, -- [111]
		{
			["gp"] = 0,
			["item"] = "Belt of Might",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16864|h[Belt of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [112]
		{
			["player"] = "Saccrilege",
			["item"] = "Arcanist Bindings",
			["date"] = "01/14/20",
			["itemLink"] = "|cffa335ee|Hitem:16799|h[Arcanist Bindings]|h|r",
			["gp"] = 60,
		}, -- [113]
		{
			["gp"] = 0,
			["item"] = "Halo of Transcendence",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["player"] = "Xan",
		}, -- [114]
		{
			["gp"] = 0,
			["item"] = "Halo of Transcendence",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["player"] = "Lago",
		}, -- [115]
		{
			["player"] = "Gyda",
			["item"] = "Head of Onyxia",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 0,
		}, -- [116]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Saccrilege",
		}, -- [117]
		{
			["player"] = "Klue",
			["item"] = "Ancient Cornerstone Grimoire",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:17067|h[Ancient Cornerstone Grimoire]|h|r",
			["gp"] = 0,
		}, -- [118]
		{
			["gp"] = 0,
			["item"] = "Nemesis Skullcap",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["player"] = "Krustytop",
		}, -- [119]
		{
			["gp"] = 0,
			["item"] = "Helm of Wrath",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
			["player"] = "Jezail",
		}, -- [120]
		{
			["gp"] = 0,
			["item"] = "Legplates of Wrath",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["player"] = "Oya",
		}, -- [121]
		{
			["gp"] = 0,
			["item"] = "Legplates of Wrath",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["player"] = "Jearom",
		}, -- [122]
		{
			["player"] = "Frostishot",
			["item"] = "Cloak of the Shrouded Mists",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
			["gp"] = 100,
		}, -- [123]
		{
			["player"] = "Nadrell",
			["item"] = "Cauterizing Band",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:19140|h[Cauterizing Band]|h|r",
			["gp"] = 250,
		}, -- [124]
		{
			["player"] = "Tikki",
			["item"] = "Blastershot Launcher",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
			["gp"] = 100,
		}, -- [125]
		{
			["gp"] = 0,
			["item"] = "Pauldrons of Might",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r",
			["player"] = "Coop",
		}, -- [126]
		{
			["player"] = "Klue",
			["item"] = "Felheart Slippers",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16803|h[Felheart Slippers]|h|r",
			["gp"] = 0,
		}, -- [127]
		{
			["player"] = "Xanido",
			["item"] = "Arcanist Mantle",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16797|h[Arcanist Mantle]|h|r",
			["gp"] = 0,
		}, -- [128]
		{
			["player"] = "Zomby",
			["item"] = "Aged Core Leather Gloves",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:18823|h[Aged Core Leather Gloves]|h|r",
			["gp"] = 200,
		}, -- [129]
		{
			["player"] = "Lunamar",
			["item"] = "Mana Igniting Cord",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [130]
		{
			["player"] = "Krustytop",
			["item"] = "Felheart Horns",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16808|h[Felheart Horns]|h|r",
			["gp"] = 0,
		}, -- [131]
		{
			["gp"] = 0,
			["item"] = "Drillborer Disk",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
			["player"] = "Coop",
		}, -- [132]
		{
			["player"] = "Lunamar",
			["item"] = "Ring of Spell Power",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:19147|h[Ring of Spell Power]|h|r",
			["gp"] = 250,
		}, -- [133]
		{
			["gp"] = 0,
			["item"] = "Gloves of Prophecy",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r",
			["player"] = "Xan",
		}, -- [134]
		{
			["gp"] = 0,
			["item"] = "Legplates of Might",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
			["player"] = "Esconar",
		}, -- [135]
		{
			["player"] = "Friend",
			["item"] = "Felheart Pants",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16810|h[Felheart Pants]|h|r",
			["gp"] = 0,
		}, -- [136]
		{
			["gp"] = 0,
			["item"] = "Aged Core Leather Gloves",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:18823|h[Aged Core Leather Gloves]|h|r",
			["player"] = "Gyda",
		}, -- [137]
		{
			["gp"] = 0,
			["item"] = "Gauntlets of Might",
			["date"] = "01/07/20",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["player"] = "Coop",
		}, -- [138]
		{
			["player"] = "Basherslice",
			["item"] = "Dragonstalker's Helm",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16939|h[Dragonstalker's Helm]|h|r",
			["gp"] = 250,
		}, -- [139]
		{
			["player"] = "Righteous",
			["item"] = "Malistar's Defender",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:17106|h[Malistar's Defender]|h|r",
			["gp"] = 30,
		}, -- [140]
		{
			["player"] = "Juicetea",
			["item"] = "Bloodfang Pants",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16909|h[Bloodfang Pants]|h|r",
			["gp"] = 200,
		}, -- [141]
		{
			["player"] = "Zomby",
			["item"] = "Bloodfang Pants",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16909|h[Bloodfang Pants]|h|r",
			["gp"] = 200,
		}, -- [142]
		{
			["player"] = "Klue",
			["item"] = "Sash of Whispered Secrets",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:18809|h[Sash of Whispered Secrets]|h|r",
			["gp"] = 200,
		}, -- [143]
		{
			["player"] = "Ezekkiel",
			["item"] = "Gloves of the Hypnotic Flame",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:18808|h[Gloves of the Hypnotic Flame]|h|r",
			["gp"] = 0,
		}, -- [144]
		{
			["player"] = "Xan",
			["item"] = "Robes of Prophecy",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16815|h[Robes of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [145]
		{
			["gp"] = 0,
			["item"] = "Pauldrons of Might",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [146]
		{
			["player"] = "Xanido",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [147]
		{
			["player"] = "Klisk",
			["item"] = "Heavy Dark Iron Ring",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r",
			["gp"] = 100,
		}, -- [148]
		{
			["player"] = "Frostishot",
			["item"] = "Giantstalker's Gloves",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16852|h[Giantstalker's Gloves]|h|r",
			["gp"] = 100,
		}, -- [149]
		{
			["player"] = "Krustytop",
			["item"] = "Felheart Shoulder Pads",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16807|h[Felheart Shoulder Pads]|h|r",
			["gp"] = 0,
		}, -- [150]
		{
			["player"] = "Xan",
			["item"] = "Girdle of Prophecy",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16817|h[Girdle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [151]
		{
			["player"] = "Marizol",
			["item"] = "Felheart Horns",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16808|h[Felheart Horns]|h|r",
			["gp"] = 0,
		}, -- [152]
		{
			["gp"] = 0,
			["item"] = "Drillborer Disk",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
			["player"] = "Jezail",
		}, -- [153]
		{
			["player"] = "Tracer",
			["item"] = "Sabatons of Might",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
			["gp"] = 150,
		}, -- [154]
		{
			["player"] = "Priestpimp",
			["item"] = "Gloves of Prophecy",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r",
			["gp"] = 50,
		}, -- [155]
		{
			["player"] = "Esconar",
			["item"] = "Flamewaker Legplates",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r",
			["gp"] = 0,
		}, -- [156]
		{
			["player"] = "Starlight",
			["item"] = "Cenarion Leggings",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16835|h[Cenarion Leggings]|h|r",
			["gp"] = 0,
		}, -- [157]
		{
			["player"] = "Xanido",
			["item"] = "Mana Igniting Cord",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [158]
		{
			["player"] = "Xanido",
			["item"] = "Arcanist Leggings",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:16796|h[Arcanist Leggings]|h|r",
			["gp"] = 80,
		}, -- [159]
		{
			["player"] = "Krustytop",
			["item"] = "Fel Infused Leggings",
			["date"] = "01/02/20",
			["itemLink"] = "|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
			["gp"] = 300,
		}, -- [160]
		{
			["player"] = "Jezail",
			["item"] = "Head of Onyxia",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [161]
		{
			["player"] = "Priestpimp",
			["item"] = "Halo of Transcendence",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["gp"] = 250,
		}, -- [162]
		{
			["player"] = "Xane",
			["item"] = "Netherwind Pants",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16915|h[Netherwind Pants]|h|r",
			["gp"] = 250,
		}, -- [163]
		{
			["player"] = "Xanido",
			["item"] = "Arcanist Bindings",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16799|h[Arcanist Bindings]|h|r",
			["gp"] = 60,
		}, -- [164]
		{
			["player"] = "Starlight",
			["item"] = "Wild Growth Spaulders",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r",
			["gp"] = 300,
		}, -- [165]
		{
			["player"] = "Xane",
			["item"] = "Azuresong Mageblade",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:17103|h[Azuresong Mageblade]|h|r",
			["gp"] = 300,
		}, -- [166]
		{
			["player"] = "Tracer",
			["item"] = "Pauldrons of Might",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r",
			["gp"] = 150,
		}, -- [167]
		{
			["player"] = "Frostishot",
			["item"] = "Giantstalker's Epaulets",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16848|h[Giantstalker's Epaulets]|h|r",
			["gp"] = 150,
		}, -- [168]
		{
			["gp"] = 0,
			["item"] = "Heavy Dark Iron Ring",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r",
			["player"] = "Oya",
		}, -- [169]
		{
			["player"] = "Bakedpancake",
			["item"] = "Seal of the Archmagus",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [170]
		{
			["player"] = "Groggy",
			["item"] = "Lawbringer Spaulders",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16856|h[Lawbringer Spaulders]|h|r",
			["gp"] = 0,
		}, -- [171]
		{
			["player"] = "Jezail",
			["item"] = "Quick Strike Ring",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:18821|h[Quick Strike Ring]|h|r",
			["gp"] = 200,
		}, -- [172]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Cover",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16821|h[Nightslayer Cover]|h|r",
			["gp"] = 0,
		}, -- [173]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Helm",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:16854|h[Lawbringer Helm]|h|r",
			["gp"] = 0,
		}, -- [174]
		{
			["player"] = "Tracer",
			["item"] = "Earthshaker",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:17073|h[Earthshaker]|h|r",
			["gp"] = 0,
		}, -- [175]
		{
			["player"] = "Zomby",
			["item"] = "Striker's Mark",
			["date"] = "12/30/19",
			["itemLink"] = "|cffa335ee|Hitem:17069|h[Striker's Mark]|h|r",
			["gp"] = 100,
		}, -- [176]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "12/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Krustytop",
		}, -- [177]
		{
			["player"] = "Jezail",
			["item"] = "Ring of Binding",
			["date"] = "12/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [178]
		{
			["player"] = "Darknéss",
			["item"] = "Judgement Crown",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16955|h[Judgement Crown]|h|r",
			["gp"] = 0,
		}, -- [179]
		{
			["player"] = "Klue",
			["item"] = "Nemesis Skullcap",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["gp"] = 250,
		}, -- [180]
		{
			["player"] = "Marizol",
			["item"] = "Sapphiron Drape",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [181]
		{
			["player"] = "Darknéss",
			["item"] = "Shard of the Scale",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17064|h[Shard of the Scale]|h|r",
			["gp"] = 200,
		}, -- [182]
		{
			["gp"] = 0,
			["item"] = "Legplates of Wrath",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["player"] = "Jezail",
		}, -- [183]
		{
			["player"] = "Cleaves",
			["item"] = "Essence of the Pure Flame",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
			["gp"] = 0,
		}, -- [184]
		{
			["gp"] = 0,
			["item"] = "Dragon's Blood Cape",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r",
			["player"] = "Jezail",
		}, -- [185]
		{
			["player"] = "Soggybottom",
			["item"] = "Leggings of Transcendence",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r",
			["gp"] = 200,
		}, -- [186]
		{
			["player"] = "Groggy",
			["item"] = "Finkle's Lava Dredger",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:18803|h[Finkle's Lava Dredger]|h|r",
			["gp"] = 0,
		}, -- [187]
		{
			["player"] = "Klisk",
			["item"] = "Core Forged Greaves",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:18806|h[Core Forged Greaves]|h|r",
			["gp"] = 0,
		}, -- [188]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Chestpiece",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16820|h[Nightslayer Chestpiece]|h|r",
			["gp"] = 100,
		}, -- [189]
		{
			["player"] = "Groggy",
			["item"] = "Azuresong Mageblade",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17103|h[Azuresong Mageblade]|h|r",
			["gp"] = 300,
		}, -- [190]
		{
			["player"] = "Lago",
			["item"] = "Mantle of Prophecy",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16816|h[Mantle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [191]
		{
			["player"] = "Juicetea",
			["item"] = "Nightslayer Shoulder Pads",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16823|h[Nightslayer Shoulder Pads]|h|r",
			["gp"] = 100,
		}, -- [192]
		{
			["gp"] = 0,
			["item"] = "Bracers of Might",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["player"] = "Jezail",
		}, -- [193]
		{
			["gp"] = 0,
			["item"] = "Bracers of Might",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["player"] = "Coop",
		}, -- [194]
		{
			["gp"] = 0,
			["item"] = "Sabatons of Might",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
			["player"] = "Jezail",
		}, -- [195]
		{
			["player"] = "Tracer",
			["item"] = "Heavy Dark Iron Ring",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r",
			["gp"] = 100,
		}, -- [196]
		{
			["player"] = "Xanido",
			["item"] = "Seal of the Archmagus",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [197]
		{
			["player"] = "Friend",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [198]
		{
			["gp"] = 0,
			["item"] = "Drillborer Disk",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
			["player"] = "Cleaves",
		}, -- [199]
		{
			["player"] = "Juicetea",
			["item"] = "Nightslayer Cover",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16821|h[Nightslayer Cover]|h|r",
			["gp"] = 0,
		}, -- [200]
		{
			["player"] = "Darknéss",
			["item"] = "Aurastone Hammer",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
			["gp"] = 50,
		}, -- [201]
		{
			["gp"] = 0,
			["item"] = "Eskhandar's Right Claw",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:18203|h[Eskhandar's Right Claw]|h|r",
			["player"] = "Jezail",
		}, -- [202]
		{
			["gp"] = 0,
			["item"] = "Legplates of Might",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
			["player"] = "Jezail",
		}, -- [203]
		{
			["gp"] = 0,
			["item"] = "Choker of Enlightenment",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
			["player"] = "Xanido",
		}, -- [204]
		{
			["gp"] = 0,
			["item"] = "Gauntlets of Might",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["player"] = "Jezail",
		}, -- [205]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Belt",
			["date"] = "12/17/19",
			["itemLink"] = "|cffa335ee|Hitem:16858|h[Lawbringer Belt]|h|r",
			["gp"] = 0,
		}, -- [206]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Darknéss",
		}, -- [207]
		{
			["gp"] = 0,
			["item"] = "Netherwind Crown",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r",
			["player"] = "Xanido",
		}, -- [208]
		{
			["player"] = "Krustytop",
			["item"] = "Nemesis Skullcap",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["gp"] = 250,
		}, -- [209]
		{
			["player"] = "Tracer",
			["item"] = "Head of Onyxia",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [210]
		{
			["player"] = "Lago",
			["item"] = "Halo of Transcendence",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["gp"] = 250,
		}, -- [211]
		{
			["player"] = "Juicetea",
			["item"] = "Bloodfang Hood",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16908|h[Bloodfang Hood]|h|r",
			["gp"] = 200,
		}, -- [212]
		{
			["player"] = "Friend",
			["item"] = "Band of Sulfuras",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:19138|h[Band of Sulfuras]|h|r",
			["gp"] = 0,
		}, -- [213]
		{
			["gp"] = 0,
			["item"] = "Dragon's Blood Cape",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r",
			["player"] = "Oya",
		}, -- [214]
		{
			["gp"] = 0,
			["item"] = "Legplates of Wrath",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["player"] = "Cleaves",
		}, -- [215]
		{
			["player"] = "Righteous",
			["item"] = "Wild Growth Spaulders",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r",
			["gp"] = 300,
		}, -- [216]
		{
			["player"] = "Ezekkiel",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [217]
		{
			["player"] = "Friend",
			["item"] = "Felheart Robes",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16809|h[Felheart Robes]|h|r",
			["gp"] = 0,
		}, -- [218]
		{
			["gp"] = 0,
			["item"] = "Breastplate of Might",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16865|h[Breastplate of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [219]
		{
			["player"] = "Soggybottom",
			["item"] = "Mantle of Prophecy",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16816|h[Mantle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [220]
		{
			["player"] = "Klisk",
			["item"] = "Pauldrons of Might",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r",
			["gp"] = 150,
		}, -- [221]
		{
			["player"] = "Marizol",
			["item"] = "Felheart Belt",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16806|h[Felheart Belt]|h|r",
			["gp"] = 0,
		}, -- [222]
		{
			["player"] = "Starlight",
			["item"] = "Cenarion Gloves",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16831|h[Cenarion Gloves]|h|r",
			["gp"] = 0,
		}, -- [223]
		{
			["player"] = "Klue",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [224]
		{
			["player"] = "Ezekkiel",
			["item"] = "Seal of the Archmagus",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [225]
		{
			["player"] = "Coop",
			["item"] = "Flameguard Gauntlets",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:19143|h[Flameguard Gauntlets]|h|r",
			["gp"] = 100,
		}, -- [226]
		{
			["player"] = "Saccrilege",
			["item"] = "Arcanist Crown",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16795|h[Arcanist Crown]|h|r",
			["gp"] = 200,
		}, -- [227]
		{
			["player"] = "Priestpimp",
			["item"] = "Vambraces of Prophecy",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16819|h[Vambraces of Prophecy]|h|r",
			["gp"] = 100,
		}, -- [228]
		{
			["player"] = "Saccrilege",
			["item"] = "Mana Igniting Cord",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [229]
		{
			["player"] = "Krustytop",
			["item"] = "Felheart Pants",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16810|h[Felheart Pants]|h|r",
			["gp"] = 0,
		}, -- [230]
		{
			["gp"] = 0,
			["item"] = "Gauntlets of Might",
			["date"] = "12/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [231]
		{
			["player"] = "Marizol",
			["item"] = "Fel Infused Leggings",
			["date"] = "12/08/19",
			["itemLink"] = "|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
			["gp"] = 300,
		}, -- [232]
		{
			["gp"] = 0,
			["item"] = "Head of Onyxia",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["player"] = "Klue",
		}, -- [233]
		{
			["player"] = "Friend",
			["item"] = "Sapphiron Drape",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [234]
		{
			["player"] = "Ezekkiel",
			["item"] = "Netherwind Crown",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r",
			["gp"] = 80,
		}, -- [235]
		{
			["player"] = "Bakedpancake",
			["item"] = "Halo of Transcendence",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["gp"] = 250,
		}, -- [236]
		{
			["player"] = "Tikki",
			["item"] = "Legplates of Wrath",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["gp"] = 250,
		}, -- [237]
		{
			["player"] = "Marizol",
			["item"] = "Choker of the Fire Lord",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18814|h[Choker of the Fire Lord]|h|r",
			["gp"] = 250,
		}, -- [238]
		{
			["gp"] = 0,
			["item"] = "Sash of Whispered Secrets",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18809|h[Sash of Whispered Secrets]|h|r",
			["player"] = "Darknéss",
		}, -- [239]
		{
			["player"] = "Saccrilege",
			["item"] = "Arcanist Robes",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16798|h[Arcanist Robes]|h|r",
			["gp"] = 0,
		}, -- [240]
		{
			["player"] = "Ezekkiel",
			["item"] = "Arcanist Belt",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16802|h[Arcanist Belt]|h|r",
			["gp"] = 0,
		}, -- [241]
		{
			["player"] = "Esconar",
			["item"] = "Blastershot Launcher",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
			["gp"] = 100,
		}, -- [242]
		{
			["player"] = "Xan",
			["item"] = "The Eye of Divinity",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["gp"] = 300,
		}, -- [243]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Shoulder Pads",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16823|h[Nightslayer Shoulder Pads]|h|r",
			["gp"] = 100,
		}, -- [244]
		{
			["player"] = "Priestpimp",
			["item"] = "Boots of Prophecy",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16811|h[Boots of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [245]
		{
			["player"] = "Marizol",
			["item"] = "Felheart Shoulder Pads",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16807|h[Felheart Shoulder Pads]|h|r",
			["gp"] = 0,
		}, -- [246]
		{
			["player"] = "Krustytop",
			["item"] = "Mana Igniting Cord",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [247]
		{
			["player"] = "Nadrell",
			["item"] = "Aurastone Hammer",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
			["gp"] = 50,
		}, -- [248]
		{
			["player"] = "Groggy",
			["item"] = "Lawbringer Helm",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16854|h[Lawbringer Helm]|h|r",
			["gp"] = 0,
		}, -- [249]
		{
			["player"] = "Bakedpancake",
			["item"] = "Gloves of Prophecy",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r",
			["gp"] = 50,
		}, -- [250]
		{
			["player"] = "Friend",
			["item"] = "Ring of Spell Power",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:19147|h[Ring of Spell Power]|h|r",
			["gp"] = 250,
		}, -- [251]
		{
			["player"] = "Groggy",
			["item"] = "Lawbringer Legplates",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16855|h[Lawbringer Legplates]|h|r",
			["gp"] = 0,
		}, -- [252]
		{
			["player"] = "Nadrell",
			["item"] = "Lawbringer Belt",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16858|h[Lawbringer Belt]|h|r",
			["gp"] = 0,
		}, -- [253]
		{
			["player"] = "Juicetea",
			["item"] = "Nightslayer Belt",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16827|h[Nightslayer Belt]|h|r",
			["gp"] = 80,
		}, -- [254]
		{
			["player"] = "Xane",
			["item"] = "Arcanist Belt",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16802|h[Arcanist Belt]|h|r",
			["gp"] = 0,
		}, -- [255]
		{
			["player"] = "Juicetea",
			["item"] = "Nightslayer Pants",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16822|h[Nightslayer Pants]|h|r",
			["gp"] = 0,
		}, -- [256]
		{
			["player"] = "Oya",
			["item"] = "Earthshaker",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:17073|h[Earthshaker]|h|r",
			["gp"] = 0,
		}, -- [257]
		{
			["player"] = "Nadrell",
			["item"] = "Lawbringer Boots",
			["date"] = "12/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16859|h[Lawbringer Boots]|h|r",
			["gp"] = 0,
		}, -- [258]
		{
			["gp"] = 0,
			["item"] = "Shard of the Flame",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:17082|h[Shard of the Flame]|h|r",
			["player"] = "Nadrell",
		}, -- [259]
		{
			["player"] = "Priestpimp",
			["item"] = "Leggings of Transcendence",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r",
			["gp"] = 200,
		}, -- [260]
		{
			["player"] = "Klisk",
			["item"] = "Cloak of the Shrouded Mists",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
			["gp"] = 100,
		}, -- [261]
		{
			["player"] = "Tracer",
			["item"] = "Essence of the Pure Flame",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
			["gp"] = 0,
		}, -- [262]
		{
			["player"] = "Tikki",
			["item"] = "Core Forged Greaves",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:18806|h[Core Forged Greaves]|h|r",
			["gp"] = 0,
		}, -- [263]
		{
			["player"] = "Esconar",
			["item"] = "Finkle's Lava Dredger",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:18803|h[Finkle's Lava Dredger]|h|r",
			["gp"] = 0,
		}, -- [264]
		{
			["player"] = "Xane",
			["item"] = "Arcanist Robes",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16798|h[Arcanist Robes]|h|r",
			["gp"] = 0,
		}, -- [265]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Chestguard",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16853|h[Lawbringer Chestguard]|h|r",
			["gp"] = 0,
		}, -- [266]
		{
			["player"] = "Coop",
			["item"] = "Flamewaker Legplates",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r",
			["gp"] = 0,
		}, -- [267]
		{
			["player"] = "Juicetea",
			["item"] = "Nightslayer Bracelets",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16825|h[Nightslayer Bracelets]|h|r",
			["gp"] = 0,
		}, -- [268]
		{
			["player"] = "Tikki",
			["item"] = "Heavy Dark Iron Ring",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r",
			["gp"] = 100,
		}, -- [269]
		{
			["player"] = "Saccrilege",
			["item"] = "Arcanist Gloves",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16801|h[Arcanist Gloves]|h|r",
			["gp"] = 0,
		}, -- [270]
		{
			["player"] = "Lunamar",
			["item"] = "Fire Runed Grimoire",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:19142|h[Fire Runed Grimoire]|h|r",
			["gp"] = 30,
		}, -- [271]
		{
			["player"] = "Lunamar",
			["item"] = "Arcanist Mantle",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16797|h[Arcanist Mantle]|h|r",
			["gp"] = 0,
		}, -- [272]
		{
			["player"] = "Lunamar",
			["item"] = "Arcanist Belt",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16802|h[Arcanist Belt]|h|r",
			["gp"] = 0,
		}, -- [273]
		{
			["player"] = "Tracer",
			["item"] = "Drillborer Disk",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
			["gp"] = 100,
		}, -- [274]
		{
			["player"] = "Lunamar",
			["item"] = "Arcanist Crown",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16795|h[Arcanist Crown]|h|r",
			["gp"] = 200,
		}, -- [275]
		{
			["gp"] = 0,
			["item"] = "Bracers of Might",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [276]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Gloves",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16826|h[Nightslayer Gloves]|h|r",
			["gp"] = 0,
		}, -- [277]
		{
			["gp"] = 0,
			["item"] = "Heavy Dark Iron Ring",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r",
			["player"] = "Coop",
		}, -- [278]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Belt",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16827|h[Nightslayer Belt]|h|r",
			["gp"] = 80,
		}, -- [279]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Pants",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16822|h[Nightslayer Pants]|h|r",
			["gp"] = 0,
		}, -- [280]
		{
			["player"] = "Ezekkiel",
			["item"] = "Mana Igniting Cord",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [281]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Legplates",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16855|h[Lawbringer Legplates]|h|r",
			["gp"] = 0,
		}, -- [282]
		{
			["player"] = "Starlight",
			["item"] = "Cenarion Boots",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16829|h[Cenarion Boots]|h|r",
			["gp"] = 125,
		}, -- [283]
		{
			["player"] = "Tracer",
			["item"] = "Gauntlets of Might",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["gp"] = 100,
		}, -- [284]
		{
			["player"] = "Starlight",
			["item"] = "Amberseal Keeper",
			["date"] = "12/02/19",
			["itemLink"] = "|cffa335ee|Hitem:17113|h[Amberseal Keeper]|h|r",
			["gp"] = 150,
		}, -- [285]
		{
			["player"] = "Soggybottom",
			["item"] = "Crystal Adorned Crown",
			["date"] = "12/01/19",
			["itemLink"] = "|cffa335ee|Hitem:19132|h[Crystal Adorned Crown]|h|r",
			["gp"] = 300,
		}, -- [286]
		{
			["gp"] = 0,
			["item"] = "Fel Infused Leggings",
			["date"] = "11/27/19",
			["itemLink"] = "|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
			["player"] = "Darknéss",
		}, -- [287]
		{
			["gp"] = 0,
			["item"] = "Fel Infused Leggings",
			["date"] = "11/27/19",
			["itemLink"] = "|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
			["player"] = "Tikki",
		}, -- [288]
		{
			["player"] = "Klisk",
			["item"] = "Head of Onyxia",
			["date"] = "11/26/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [289]
		{
			["gp"] = 0,
			["item"] = "Eskhandar's Collar",
			["date"] = "11/26/19",
			["itemLink"] = "|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
			["player"] = "Jezail",
		}, -- [290]
		{
			["player"] = "Starlight",
			["item"] = "Stormrage Cover",
			["date"] = "11/26/19",
			["itemLink"] = "|cffa335ee|Hitem:16900|h[Stormrage Cover]|h|r",
			["gp"] = 125,
		}, -- [291]
		{
			["player"] = "Cleaves",
			["item"] = "Empyrean Demolisher",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:17112|h[Empyrean Demolisher]|h|r",
			["gp"] = 300,
		}, -- [292]
		{
			["player"] = "Saccrilege",
			["item"] = "Cold Snap",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:19130|h[Cold Snap]|h|r",
			["gp"] = 100,
		}, -- [293]
		{
			["player"] = "Azuj",
			["item"] = "Head of Onyxia",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [294]
		{
			["player"] = "Odonn",
			["item"] = "Ring of Binding",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [295]
		{
			["player"] = "Nadrell",
			["item"] = "Judgement Crown",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16955|h[Judgement Crown]|h|r",
			["gp"] = 0,
		}, -- [296]
		{
			["player"] = "Cleaves",
			["item"] = "Head of Onyxia",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [297]
		{
			["gp"] = 0,
			["item"] = "Helm of Wrath",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
			["player"] = "Cleaves",
		}, -- [298]
		{
			["gp"] = 0,
			["item"] = "Sapphiron Drape",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["player"] = "Tikki",
		}, -- [299]
		{
			["player"] = "Zomby",
			["item"] = "Ancient Cornerstone Grimoire",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:17067|h[Ancient Cornerstone Grimoire]|h|r",
			["gp"] = 0,
		}, -- [300]
		{
			["player"] = "Oya",
			["item"] = "Head of Onyxia",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [301]
		{
			["player"] = "Saccrilege",
			["item"] = "Netherwind Crown",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r",
			["gp"] = 80,
		}, -- [302]
		{
			["player"] = "Frost",
			["item"] = "Stormrage Cover",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16900|h[Stormrage Cover]|h|r",
			["gp"] = 125,
		}, -- [303]
		{
			["player"] = "Tikki",
			["item"] = "Head of Onyxia",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [304]
		{
			["player"] = "Frostishot",
			["item"] = "Dragonstalker's Helm",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16939|h[Dragonstalker's Helm]|h|r",
			["gp"] = 250,
		}, -- [305]
		{
			["player"] = "Cleaves",
			["item"] = "Ring of Binding",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [306]
		{
			["gp"] = 0,
			["item"] = "Stormrage Cover",
			["date"] = "11/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16900|h[Stormrage Cover]|h|r",
			["player"] = "Friend",
		}, -- [307]
		{
			["player"] = "Bakedpancake",
			["item"] = "Leggings of Transcendence",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r",
			["gp"] = 200,
		}, -- [308]
		{
			["player"] = "Juicetea",
			["item"] = "Band of Accuria",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:17063|h[Band of Accuria]|h|r",
			["gp"] = 300,
		}, -- [309]
		{
			["player"] = "Groggy",
			["item"] = "Essence of the Pure Flame",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
			["gp"] = 0,
		}, -- [310]
		{
			["player"] = "Krustytop",
			["item"] = "Nemesis Leggings",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16930|h[Nemesis Leggings]|h|r",
			["gp"] = 250,
		}, -- [311]
		{
			["player"] = "Esconar",
			["item"] = "Bonereaver's Edge",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:17076|h[Bonereaver's Edge]|h|r",
			["gp"] = 300,
		}, -- [312]
		{
			["player"] = "Friend",
			["item"] = "Felheart Belt",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16806|h[Felheart Belt]|h|r",
			["gp"] = 0,
		}, -- [313]
		{
			["player"] = "Frostishot",
			["item"] = "Wristguards of True Flight",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:18812|h[Wristguards of True Flight]|h|r",
			["gp"] = 0,
		}, -- [314]
		{
			["player"] = "Zomby",
			["item"] = "Core Hound Tooth",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:18805|h[Core Hound Tooth]|h|r",
			["gp"] = 250,
		}, -- [315]
		{
			["player"] = "Sogy",
			["item"] = "Ancient Petrified Leaf",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:18703|h[Ancient Petrified Leaf]|h|r",
			["gp"] = 300,
		}, -- [316]
		{
			["gp"] = 0,
			["item"] = "Cenarion Vestments",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16833|h[Cenarion Vestments]|h|r",
			["player"] = "Klue",
		}, -- [317]
		{
			["player"] = "Coop",
			["item"] = "Blastershot Launcher",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
			["gp"] = 100,
		}, -- [318]
		{
			["player"] = "Marizol",
			["item"] = "Felheart Robes",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16809|h[Felheart Robes]|h|r",
			["gp"] = 0,
		}, -- [319]
		{
			["player"] = "Tikki",
			["item"] = "Pauldrons of Might",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r",
			["gp"] = 150,
		}, -- [320]
		{
			["player"] = "Klue",
			["item"] = "Cenarion Gloves",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16831|h[Cenarion Gloves]|h|r",
			["gp"] = 0,
		}, -- [321]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Boots",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16824|h[Nightslayer Boots]|h|r",
			["gp"] = 100,
		}, -- [322]
		{
			["gp"] = 0,
			["item"] = "Cenarion Spaulders",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16836|h[Cenarion Spaulders]|h|r",
			["player"] = "Klue",
		}, -- [323]
		{
			["player"] = "Groggy",
			["item"] = "Seal of the Archmagus",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [324]
		{
			["player"] = "Cleaves",
			["item"] = "Flamewaker Legplates",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r",
			["gp"] = 0,
		}, -- [325]
		{
			["player"] = "Bakedpancake",
			["item"] = "Circlet of Prophecy",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16813|h[Circlet of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [326]
		{
			["player"] = "Frostishot",
			["item"] = "Giantstalker's Boots",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16849|h[Giantstalker's Boots]|h|r",
			["gp"] = 150,
		}, -- [327]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Bracers",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16857|h[Lawbringer Bracers]|h|r",
			["gp"] = 0,
		}, -- [328]
		{
			["gp"] = 0,
			["item"] = "Legplates of Might",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
			["player"] = "Cleaves",
		}, -- [329]
		{
			["player"] = "Saccrilege",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [330]
		{
			["gp"] = 0,
			["item"] = "Lawbringer Boots",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16859|h[Lawbringer Boots]|h|r",
			["player"] = "Righteous",
		}, -- [331]
		{
			["player"] = "Klue",
			["item"] = "Fel Infused Leggings",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
			["gp"] = 300,
		}, -- [332]
		{
			["player"] = "Darknéss",
			["item"] = "Vambraces of Prophecy",
			["date"] = "11/19/19",
			["itemLink"] = "|cffa335ee|Hitem:16819|h[Vambraces of Prophecy]|h|r",
			["gp"] = 100,
		}, -- [333]
		{
			["player"] = "Klue",
			["item"] = "Eskhandar's Collar",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
			["gp"] = 0,
		}, -- [334]
		{
			["player"] = "Xane",
			["item"] = "Netherwind Crown",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r",
			["gp"] = 80,
		}, -- [335]
		{
			["player"] = "Jezail",
			["item"] = "Vis'kag the Bloodletter",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:17075|h[Vis'kag the Bloodletter]|h|r",
			["gp"] = 300,
		}, -- [336]
		{
			["player"] = "Frostishot",
			["item"] = "Head of Onyxia",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [337]
		{
			["player"] = "Righteous",
			["item"] = "Judgement Crown",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:16955|h[Judgement Crown]|h|r",
			["gp"] = 0,
		}, -- [338]
		{
			["player"] = "Zomby",
			["item"] = "Bloodfang Hood",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:16908|h[Bloodfang Hood]|h|r",
			["gp"] = 200,
		}, -- [339]
		{
			["player"] = "Zomby",
			["item"] = "Vis'kag the Bloodletter",
			["date"] = "11/14/19",
			["itemLink"] = "|cffa335ee|Hitem:17075|h[Vis'kag the Bloodletter]|h|r",
			["gp"] = 300,
		}, -- [340]
		{
			["player"] = "Klisk",
			["item"] = "Essence of the Pure Flame",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
			["gp"] = 0,
		}, -- [341]
		{
			["player"] = "Nadrell",
			["item"] = "Judgement Legplates",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16954|h[Judgement Legplates]|h|r",
			["gp"] = 0,
		}, -- [342]
		{
			["player"] = "Lunamar",
			["item"] = "Netherwind Pants",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16915|h[Netherwind Pants]|h|r",
			["gp"] = 250,
		}, -- [343]
		{
			["player"] = "Klisk",
			["item"] = "Dragon's Blood Cape",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r",
			["gp"] = 100,
		}, -- [344]
		{
			["player"] = "Xane",
			["item"] = "Gloves of the Hypnotic Flame",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:18808|h[Gloves of the Hypnotic Flame]|h|r",
			["gp"] = 0,
		}, -- [345]
		{
			["player"] = "Lago",
			["item"] = "The Eye of Divinity",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["gp"] = 300,
		}, -- [346]
		{
			["player"] = "Ezekkiel",
			["item"] = "Arcanist Robes",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16798|h[Arcanist Robes]|h|r",
			["gp"] = 0,
		}, -- [347]
		{
			["player"] = "Klue",
			["item"] = "Cenarion Vestments",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16833|h[Cenarion Vestments]|h|r",
			["gp"] = 0,
		}, -- [348]
		{
			["player"] = "Xane",
			["item"] = "Arcanist Gloves",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16801|h[Arcanist Gloves]|h|r",
			["gp"] = 0,
		}, -- [349]
		{
			["player"] = "Groggy",
			["item"] = "Magma Tempered Boots",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:18824|h[Magma Tempered Boots]|h|r",
			["gp"] = 0,
		}, -- [350]
		{
			["player"] = "Friend",
			["item"] = "Felheart Shoulder Pads",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16807|h[Felheart Shoulder Pads]|h|r",
			["gp"] = 0,
		}, -- [351]
		{
			["player"] = "Klisk",
			["item"] = "Drillborer Disk",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
			["gp"] = 100,
		}, -- [352]
		{
			["player"] = "Xane",
			["item"] = "Ring of Spell Power",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:19147|h[Ring of Spell Power]|h|r",
			["gp"] = 250,
		}, -- [353]
		{
			["player"] = "Frostishot",
			["item"] = "Giantstalker's Belt",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16851|h[Giantstalker's Belt]|h|r",
			["gp"] = 80,
		}, -- [354]
		{
			["player"] = "Lunamar",
			["item"] = "Choker of Enlightenment",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
			["gp"] = 60,
		}, -- [355]
		{
			["player"] = "Krustytop",
			["item"] = "Felheart Gloves",
			["date"] = "11/12/19",
			["itemLink"] = "|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r",
			["gp"] = 0,
		}, -- [356]
		{
			["player"] = "Zomby",
			["item"] = "Head of Onyxia",
			["date"] = "11/07/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [357]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Bracelets",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16825|h[Nightslayer Bracelets]|h|r",
			["gp"] = 0,
		}, -- [358]
		{
			["player"] = "Xan",
			["item"] = "Ring of Spell Power",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:19147|h[Ring of Spell Power]|h|r",
			["gp"] = 250,
		}, -- [359]
		{
			["player"] = "Tracer",
			["item"] = "Blastershot Launcher",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
			["gp"] = 100,
		}, -- [360]
		{
			["player"] = "Tracer",
			["item"] = "Medallion of Steadfast Might",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:17065|h[Medallion of Steadfast Might]|h|r",
			["gp"] = 150,
		}, -- [361]
		{
			["player"] = "Tikki",
			["item"] = "Dragon's Blood Cape",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r",
			["gp"] = 0,
		}, -- [362]
		{
			["player"] = "Soggybottom",
			["item"] = "Robes of Prophecy",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16815|h[Robes of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [363]
		{
			["player"] = "Soggybottom",
			["item"] = "Fire Runed Grimoire",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:19142|h[Fire Runed Grimoire]|h|r",
			["gp"] = 0,
		}, -- [364]
		{
			["player"] = "Righteous",
			["item"] = "Judgement Legplates",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16954|h[Judgement Legplates]|h|r",
			["gp"] = 0,
		}, -- [365]
		{
			["player"] = "Priestpimp",
			["item"] = "The Eye of Divinity",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["gp"] = 300,
		}, -- [366]
		{
			["player"] = "Priestpimp",
			["item"] = "Pants of Prophecy",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16814|h[Pants of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [367]
		{
			["player"] = "Darknéss",
			["item"] = "Seal of the Archmagus",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [368]
		{
			["player"] = "Marizol",
			["item"] = "Nemesis Leggings",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16930|h[Nemesis Leggings]|h|r",
			["gp"] = 250,
		}, -- [369]
		{
			["player"] = "Lago",
			["item"] = "Cauterizing Band",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:19140|h[Cauterizing Band]|h|r",
			["gp"] = 250,
		}, -- [370]
		{
			["player"] = "Krustytop",
			["item"] = "Felheart Slippers",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16803|h[Felheart Slippers]|h|r",
			["gp"] = 0,
		}, -- [371]
		{
			["player"] = "Klue",
			["item"] = "Cenarion Helm",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16834|h[Cenarion Helm]|h|r",
			["gp"] = 0,
		}, -- [372]
		{
			["player"] = "Klisk",
			["item"] = "Gauntlets of Might",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["gp"] = 100,
		}, -- [373]
		{
			["player"] = "Starlight",
			["item"] = "Choker of the Fire Lord",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18814|h[Choker of the Fire Lord]|h|r",
			["gp"] = 250,
		}, -- [374]
		{
			["player"] = "Groggy",
			["item"] = "Aurastone Hammer",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
			["gp"] = 50,
		}, -- [375]
		{
			["player"] = "Frostishot",
			["item"] = "Giantstalker's Breastplate",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16845|h[Giantstalker's Breastplate]|h|r",
			["gp"] = 150,
		}, -- [376]
		{
			["player"] = "Friend",
			["item"] = "Felheart Horns",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16808|h[Felheart Horns]|h|r",
			["gp"] = 0,
		}, -- [377]
		{
			["player"] = "Ezekkiel",
			["item"] = "Arcanist Gloves",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16801|h[Arcanist Gloves]|h|r",
			["gp"] = 0,
		}, -- [378]
		{
			["player"] = "Ezekkiel",
			["item"] = "Arcanist Boots",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16800|h[Arcanist Boots]|h|r",
			["gp"] = 150,
		}, -- [379]
		{
			["player"] = "Azuj",
			["item"] = "Core Hound Tooth",
			["date"] = "11/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18805|h[Core Hound Tooth]|h|r",
			["gp"] = 250,
		}, -- [380]
		{
			["player"] = "Marizol",
			["item"] = "Nemesis Skullcap",
			["date"] = "11/04/19",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["gp"] = 250,
		}, -- [381]
		{
			["player"] = "Lunamar",
			["item"] = "Sapphiron Drape",
			["date"] = "11/04/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [382]
		{
			["player"] = "Frostishot",
			["item"] = "Mature Black Dragon Sinew",
			["date"] = "11/04/19",
			["itemLink"] = "|cffa335ee|Hitem:18705|h[Mature Black Dragon Sinew]|h|r",
			["gp"] = 0,
		}, -- [383]
		{
			["player"] = "Coop",
			["item"] = "Head of Onyxia",
			["date"] = "11/04/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [384]
		{
			["player"] = "Azuj",
			["item"] = "Bloodfang Hood",
			["date"] = "11/04/19",
			["itemLink"] = "|cffa335ee|Hitem:16908|h[Bloodfang Hood]|h|r",
			["gp"] = 200,
		}, -- [385]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Belt",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16827|h[Nightslayer Belt]|h|r",
			["gp"] = 80,
		}, -- [386]
		{
			["player"] = "Tracer",
			["item"] = "Breastplate of Might",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16865|h[Breastplate of Might]|h|r",
			["gp"] = 150,
		}, -- [387]
		{
			["player"] = "Tikki",
			["item"] = "Essence of the Pure Flame",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
			["gp"] = 0,
		}, -- [388]
		{
			["player"] = "Tikki",
			["item"] = "Bindings of the Windseeker",
			["date"] = "10/29/19",
			["itemLink"] = "|cffff8000|Hitem:18563|h[Bindings of the Windseeker]|h|r",
			["gp"] = 0,
		}, -- [389]
		{
			["player"] = "Righteous",
			["item"] = "Cauterizing Band",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:19140|h[Cauterizing Band]|h|r",
			["gp"] = 250,
		}, -- [390]
		{
			["player"] = "Righteous",
			["item"] = "Aurastone Hammer",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
			["gp"] = 50,
		}, -- [391]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Gauntlets",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16860|h[Lawbringer Gauntlets]|h|r",
			["gp"] = 0,
		}, -- [392]
		{
			["player"] = "Darknéss",
			["item"] = "Mantle of Prophecy",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16816|h[Mantle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [393]
		{
			["player"] = "Nadrell",
			["item"] = "Lawbringer Boots",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16859|h[Lawbringer Boots]|h|r",
			["gp"] = 0,
		}, -- [394]
		{
			["player"] = "Marizol",
			["item"] = "Mana Igniting Cord",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
			["gp"] = 250,
		}, -- [395]
		{
			["player"] = "Lago",
			["item"] = "Shard of the Flame",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:17082|h[Shard of the Flame]|h|r",
			["gp"] = 0,
		}, -- [396]
		{
			["player"] = "Lago",
			["item"] = "Fireproof Cloak",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:18811|h[Fireproof Cloak]|h|r",
			["gp"] = 0,
		}, -- [397]
		{
			["player"] = "Lago",
			["item"] = "Robes of Prophecy",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16815|h[Robes of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [398]
		{
			["player"] = "Klisk",
			["item"] = "Sabatons of Might",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
			["gp"] = 150,
		}, -- [399]
		{
			["player"] = "Starlight",
			["item"] = "Felheart Horns",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16808|h[Felheart Horns]|h|r",
			["gp"] = 0,
		}, -- [400]
		{
			["player"] = "Frostishot",
			["item"] = "Ancient Petrified Leaf",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:18703|h[Ancient Petrified Leaf]|h|r",
			["gp"] = 0,
		}, -- [401]
		{
			["player"] = "Frostishot",
			["item"] = "Giantstalker's Helmet",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16846|h[Giantstalker's Helmet]|h|r",
			["gp"] = 0,
		}, -- [402]
		{
			["player"] = "Friend",
			["item"] = "Nemesis Leggings",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16930|h[Nemesis Leggings]|h|r",
			["gp"] = 250,
		}, -- [403]
		{
			["player"] = "Ezekkiel",
			["item"] = "Arcanist Mantle",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16797|h[Arcanist Mantle]|h|r",
			["gp"] = 0,
		}, -- [404]
		{
			["player"] = "Coop",
			["item"] = "Onslaught Girdle",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:19137|h[Onslaught Girdle]|h|r",
			["gp"] = 300,
		}, -- [405]
		{
			["player"] = "Saccrilege",
			["item"] = "Arcanist Belt",
			["date"] = "10/29/19",
			["itemLink"] = "|cffa335ee|Hitem:16802|h[Arcanist Belt]|h|r",
			["gp"] = 0,
		}, -- [406]
		{
			["player"] = "Xan",
			["item"] = "Ancient Cornerstone Grimoire",
			["date"] = "10/28/19",
			["itemLink"] = "|cffa335ee|Hitem:17067|h[Ancient Cornerstone Grimoire]|h|r",
			["gp"] = 0,
		}, -- [407]
		{
			["player"] = "Tracer",
			["item"] = "Helm of Wrath",
			["date"] = "10/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
			["gp"] = 250,
		}, -- [408]
		{
			["player"] = "Lunamar",
			["item"] = "Netherwind Crown",
			["date"] = "10/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r",
			["gp"] = 80,
		}, -- [409]
		{
			["player"] = "Lago",
			["item"] = "Shard of the Scale",
			["date"] = "10/28/19",
			["itemLink"] = "|cffa335ee|Hitem:17064|h[Shard of the Scale]|h|r",
			["gp"] = 200,
		}, -- [410]
		{
			["player"] = "Tracer",
			["item"] = "Cloak of the Shrouded Mists",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
			["gp"] = 100,
		}, -- [411]
		{
			["player"] = "Tikki",
			["item"] = "Helm of Wrath",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
			["gp"] = 250,
		}, -- [412]
		{
			["player"] = "Tikki",
			["item"] = "Flamewaker Legplates",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r",
			["gp"] = 0,
		}, -- [413]
		{
			["player"] = "Tikki",
			["item"] = "Drillborer Disk",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
			["gp"] = 100,
		}, -- [414]
		{
			["player"] = "Tikki",
			["item"] = "Breastplate of Might",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16865|h[Breastplate of Might]|h|r",
			["gp"] = 150,
		}, -- [415]
		{
			["player"] = "Soggybottom",
			["item"] = "Pants of Prophecy",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16814|h[Pants of Prophecy]|h|r",
			["gp"] = 30,
		}, -- [416]
		{
			["player"] = "Oya",
			["item"] = "Perdition's Blade",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:18816|h[Perdition's Blade]|h|r",
			["gp"] = 300,
		}, -- [417]
		{
			["player"] = "Nadrell",
			["item"] = "Lawbringer Legplates",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16855|h[Lawbringer Legplates]|h|r",
			["gp"] = 0,
		}, -- [418]
		{
			["player"] = "Lunamar",
			["item"] = "Gloves of the Hypnotic Flame",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:18808|h[Gloves of the Hypnotic Flame]|h|r",
			["gp"] = 0,
		}, -- [419]
		{
			["player"] = "Lago",
			["item"] = "Gloves of Prophecy",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r",
			["gp"] = 50,
		}, -- [420]
		{
			["player"] = "Klue",
			["item"] = "Robe of Volatile Power",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r",
			["gp"] = 300,
		}, -- [421]
		{
			["player"] = "Klisk",
			["item"] = "Eskhandar's Collar",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
			["gp"] = 30,
		}, -- [422]
		{
			["player"] = "Klisk",
			["item"] = "Bracers of Might",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["gp"] = 60,
		}, -- [423]
		{
			["player"] = "Juicetea",
			["item"] = "Head of Onyxia",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [424]
		{
			["player"] = "Jezail",
			["item"] = "Flameguard Gauntlets",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:19143|h[Flameguard Gauntlets]|h|r",
			["gp"] = 100,
		}, -- [425]
		{
			["player"] = "Groggy",
			["item"] = "Lawbringer Boots",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16859|h[Lawbringer Boots]|h|r",
			["gp"] = 30,
		}, -- [426]
		{
			["player"] = "Friend",
			["item"] = "Felheart Slippers",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16803|h[Felheart Slippers]|h|r",
			["gp"] = 0,
		}, -- [427]
		{
			["player"] = "Friend",
			["item"] = "Felheart Gloves",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r",
			["gp"] = 0,
		}, -- [428]
		{
			["player"] = "Esconar",
			["item"] = "Shadowstrike",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:17074|h[Shadowstrike]|h|r",
			["gp"] = 0,
		}, -- [429]
		{
			["player"] = "Coop",
			["item"] = "Gutgore Ripper",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:17071|h[Gutgore Ripper]|h|r",
			["gp"] = 0,
		}, -- [430]
		{
			["player"] = "Basherslice",
			["item"] = "Dragonstalker's Legguards",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16938|h[Dragonstalker's Legguards]|h|r",
			["gp"] = 250,
		}, -- [431]
		{
			["player"] = "Azuj",
			["item"] = "Bloodfang Pants",
			["date"] = "10/22/19",
			["itemLink"] = "|cffa335ee|Hitem:16909|h[Bloodfang Pants]|h|r",
			["gp"] = 200,
		}, -- [432]
		{
			["player"] = "Ezekkiel",
			["item"] = "Sapphiron Drape",
			["date"] = "10/17/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [433]
		{
			["player"] = "Xane",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [434]
		{
			["player"] = "Tracer",
			["item"] = "Legplates of Wrath",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["gp"] = 250,
		}, -- [435]
		{
			["player"] = "Tracer",
			["item"] = "Helm of Might",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16866|h[Helm of Might]|h|r",
			["gp"] = 150,
		}, -- [436]
		{
			["player"] = "Tracer",
			["item"] = "Flamewaker Legplates",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r",
			["gp"] = 0,
		}, -- [437]
		{
			["player"] = "Tracer",
			["item"] = "Bracers of Might",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["gp"] = 60,
		}, -- [438]
		{
			["player"] = "Tikki",
			["item"] = "Sabatons of Might",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
			["gp"] = 150,
		}, -- [439]
		{
			["player"] = "Tikki",
			["item"] = "Cloak of the Shrouded Mists",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
			["gp"] = 0,
		}, -- [440]
		{
			["player"] = "Tikki",
			["item"] = "Bracers of Might",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
			["gp"] = 60,
		}, -- [441]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Gauntlets",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16860|h[Lawbringer Gauntlets]|h|r",
			["gp"] = 0,
		}, -- [442]
		{
			["player"] = "Priestpimp",
			["item"] = "Girdle of Prophecy",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16817|h[Girdle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [443]
		{
			["player"] = "Oya",
			["item"] = "Striker's Mark",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:17069|h[Striker's Mark]|h|r",
			["gp"] = 100,
		}, -- [444]
		{
			["player"] = "Nadrell",
			["item"] = "Wild Growth Spaulders",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r",
			["gp"] = 300,
		}, -- [445]
		{
			["player"] = "Nadrell",
			["item"] = "Shard of the Scale",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:17064|h[Shard of the Scale]|h|r",
			["gp"] = 200,
		}, -- [446]
		{
			["player"] = "Klue",
			["item"] = "Felheart Robes",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16809|h[Felheart Robes]|h|r",
			["gp"] = 0,
		}, -- [447]
		{
			["player"] = "Klisk",
			["item"] = "Legplates of Wrath",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
			["gp"] = 250,
		}, -- [448]
		{
			["player"] = "Starlight",
			["item"] = "Felheart Belt",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16806|h[Felheart Belt]|h|r",
			["gp"] = 0,
		}, -- [449]
		{
			["player"] = "Esconar",
			["item"] = "Ring of Binding",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [450]
		{
			["player"] = "Esconar",
			["item"] = "Head of Onyxia",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [451]
		{
			["player"] = "Coop",
			["item"] = "Obsidian Edged Blade",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r",
			["gp"] = 0,
		}, -- [452]
		{
			["player"] = "Basherslice",
			["item"] = "Mature Black Dragon Sinew",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18705|h[Mature Black Dragon Sinew]|h|r",
			["gp"] = 0,
		}, -- [453]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Gloves",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16852|h[Giantstalker's Gloves]|h|r",
			["gp"] = 100,
		}, -- [454]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Epaulets",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:16848|h[Giantstalker's Epaulets]|h|r",
			["gp"] = 150,
		}, -- [455]
		{
			["player"] = "Bakedpancake",
			["item"] = "The Eye of Divinity",
			["date"] = "10/15/19",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["gp"] = 300,
		}, -- [456]
		{
			["player"] = "Xane",
			["item"] = "Arcanist Bindings",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16799|h[Arcanist Bindings]|h|r",
			["gp"] = 60,
		}, -- [457]
		{
			["player"] = "Tikki",
			["item"] = "Crown of Destruction",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18817|h[Crown of Destruction]|h|r",
			["gp"] = 0,
		}, -- [458]
		{
			["player"] = "Oya",
			["item"] = "Finkle's Lava Dredger",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18803|h[Finkle's Lava Dredger]|h|r",
			["gp"] = 0,
		}, -- [459]
		{
			["player"] = "Groggy",
			["item"] = "Wild Growth Spaulders",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r",
			["gp"] = 300,
		}, -- [460]
		{
			["player"] = "Cleaves",
			["item"] = "Bloodfang Pants",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:16909|h[Bloodfang Pants]|h|r",
			["gp"] = 200,
		}, -- [461]
		{
			["player"] = "Basherslice",
			["item"] = "Cloak of the Shrouded Mists",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
			["gp"] = 100,
		}, -- [462]
		{
			["player"] = "Basherslice",
			["item"] = "Ancient Petrified Leaf",
			["date"] = "10/10/19",
			["itemLink"] = "|cffa335ee|Hitem:18703|h[Ancient Petrified Leaf]|h|r",
			["gp"] = 300,
		}, -- [463]
		{
			["player"] = "Righteous",
			["item"] = "Lawbringer Spaulders",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16856|h[Lawbringer Spaulders]|h|r",
			["gp"] = 0,
		}, -- [464]
		{
			["player"] = "Oya",
			["item"] = "Brutality Blade",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:18832|h[Brutality Blade]|h|r",
			["gp"] = 300,
		}, -- [465]
		{
			["player"] = "Marizol",
			["item"] = "Felheart Bracers",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16804|h[Felheart Bracers]|h|r",
			["gp"] = 60,
		}, -- [466]
		{
			["player"] = "Lunamar",
			["item"] = "Seal of the Archmagus",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [467]
		{
			["player"] = "Lago",
			["item"] = "Boots of Prophecy",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16811|h[Boots of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [468]
		{
			["player"] = "Klisk",
			["item"] = "Helm of Wrath",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
			["gp"] = 250,
		}, -- [469]
		{
			["player"] = "Starlight",
			["item"] = "Sapphiron Drape",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [470]
		{
			["player"] = "Groggy",
			["item"] = "Obsidian Edged Blade",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r",
			["gp"] = 0,
		}, -- [471]
		{
			["player"] = "Friend",
			["item"] = "Choker of Enlightenment",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
			["gp"] = 60,
		}, -- [472]
		{
			["player"] = "Ezekkiel",
			["item"] = "Arcanist Leggings",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16796|h[Arcanist Leggings]|h|r",
			["gp"] = 0,
		}, -- [473]
		{
			["player"] = "Saccrilege",
			["item"] = "Sorcerous Dagger",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:18878|h[Sorcerous Dagger]|h|r",
			["gp"] = 30,
		}, -- [474]
		{
			["player"] = "Basherslice",
			["item"] = "Mature Black Dragon Sinew",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:18705|h[Mature Black Dragon Sinew]|h|r",
			["gp"] = 0,
		}, -- [475]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Helmet",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16846|h[Giantstalker's Helmet]|h|r",
			["gp"] = 150,
		}, -- [476]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Boots",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16849|h[Giantstalker's Boots]|h|r",
			["gp"] = 150,
		}, -- [477]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Gloves",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16826|h[Nightslayer Gloves]|h|r",
			["gp"] = 0,
		}, -- [478]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Bracelets",
			["date"] = "10/08/19",
			["itemLink"] = "|cffa335ee|Hitem:16825|h[Nightslayer Bracelets]|h|r",
			["gp"] = 0,
		}, -- [479]
		{
			["player"] = "Xane",
			["item"] = "Sorcerous Dagger",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18878|h[Sorcerous Dagger]|h|r",
			["gp"] = 30,
		}, -- [480]
		{
			["player"] = "Darknéss",
			["item"] = "The Eye of Divinity",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["gp"] = 300,
		}, -- [481]
		{
			["player"] = "Lago",
			["item"] = "Seal of the Archmagus",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
			["gp"] = 0,
		}, -- [482]
		{
			["player"] = "Klisk",
			["item"] = "Fireguard Shoulders",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:19139|h[Fireguard Shoulders]|h|r",
			["gp"] = 0,
		}, -- [483]
		{
			["player"] = "Friend",
			["item"] = "Sash of Whispered Secrets",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18809|h[Sash of Whispered Secrets]|h|r",
			["gp"] = 200,
		}, -- [484]
		{
			["player"] = "Ezekkiel",
			["item"] = "Staff of Dominance",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18842|h[Staff of Dominance]|h|r",
			["gp"] = 300,
		}, -- [485]
		{
			["player"] = "Cleaves",
			["item"] = "Perdition's Blade",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:18816|h[Perdition's Blade]|h|r",
			["gp"] = 300,
		}, -- [486]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Breastplate",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16845|h[Giantstalker's Breastplate]|h|r",
			["gp"] = 150,
		}, -- [487]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Shoulder Pads",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16823|h[Nightslayer Shoulder Pads]|h|r",
			["gp"] = 100,
		}, -- [488]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Chestpiece",
			["date"] = "10/05/19",
			["itemLink"] = "|cffa335ee|Hitem:16820|h[Nightslayer Chestpiece]|h|r",
			["gp"] = 100,
		}, -- [489]
		{
			["player"] = "Tracer",
			["item"] = "Legplates of Might",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
			["gp"] = 130,
		}, -- [490]
		{
			["player"] = "Tikki",
			["item"] = "Gauntlets of Might",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
			["gp"] = 100,
		}, -- [491]
		{
			["player"] = "Soggybottom",
			["item"] = "Gloves of Prophecy",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r",
			["gp"] = 50,
		}, -- [492]
		{
			["player"] = "Darknéss",
			["item"] = "Halo of Transcendence",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
			["gp"] = 250,
		}, -- [493]
		{
			["player"] = "Lago",
			["item"] = "Girdle of Prophecy",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16817|h[Girdle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [494]
		{
			["player"] = "Klisk",
			["item"] = "Ring of Binding",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
			["gp"] = 0,
		}, -- [495]
		{
			["player"] = "Klisk",
			["item"] = "Eskhandar's Right Claw",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18203|h[Eskhandar's Right Claw]|h|r",
			["gp"] = 0,
		}, -- [496]
		{
			["player"] = "Starlight",
			["item"] = "Nemesis Skullcap",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
			["gp"] = 250,
		}, -- [497]
		{
			["player"] = "Esconar",
			["item"] = "Deathbringer",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:17068|h[Deathbringer]|h|r",
			["gp"] = 0,
		}, -- [498]
		{
			["player"] = "Basherslice",
			["item"] = "Head of Onyxia",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [499]
		{
			["player"] = "Azuj",
			["item"] = "Nightslayer Cover",
			["date"] = "10/03/19",
			["itemLink"] = "|cffa335ee|Hitem:16821|h[Nightslayer Cover]|h|r",
			["gp"] = 0,
		}, -- [500]
		{
			["player"] = "Zomby",
			["item"] = "Nightslayer Boots",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16824|h[Nightslayer Boots]|h|r",
			["gp"] = 100,
		}, -- [501]
		{
			["player"] = "Xan",
			["item"] = "Sash of Whispered Secrets",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:18809|h[Sash of Whispered Secrets]|h|r",
			["gp"] = 200,
		}, -- [502]
		{
			["player"] = "Xan",
			["item"] = "Head of Onyxia",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
			["gp"] = 75,
		}, -- [503]
		{
			["player"] = "Tracer",
			["item"] = "Eskhandar's Right Claw",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:18203|h[Eskhandar's Right Claw]|h|r",
			["gp"] = 100,
		}, -- [504]
		{
			["player"] = "Tikki",
			["item"] = "Medallion of Steadfast Might",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:17065|h[Medallion of Steadfast Might]|h|r",
			["gp"] = 150,
		}, -- [505]
		{
			["player"] = "Soggybottom",
			["item"] = "The Eye of Divinity",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
			["gp"] = 300,
		}, -- [506]
		{
			["player"] = "Priestpimp",
			["item"] = "Sapphiron Drape",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
			["gp"] = 80,
		}, -- [507]
		{
			["player"] = "Priestpimp",
			["item"] = "Choker of Enlightenment",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
			["gp"] = 60,
		}, -- [508]
		{
			["player"] = "Marizol",
			["item"] = "Felheart Gloves",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r",
			["gp"] = 0,
		}, -- [509]
		{
			["player"] = "Lago",
			["item"] = "Pants of Prophecy",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16814|h[Pants of Prophecy]|h|r",
			["gp"] = 30,
		}, -- [510]
		{
			["player"] = "Juicetea",
			["item"] = "Brutality Blade",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:18832|h[Brutality Blade]|h|r",
			["gp"] = 300,
		}, -- [511]
		{
			["player"] = "Jezail",
			["item"] = "Onslaught Girdle",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:19137|h[Onslaught Girdle]|h|r",
			["gp"] = 300,
		}, -- [512]
		{
			["player"] = "Groggy",
			["item"] = "Judgement Legplates",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16954|h[Judgement Legplates]|h|r",
			["gp"] = 0,
		}, -- [513]
		{
			["player"] = "Groggy",
			["item"] = "Judgement Crown",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16955|h[Judgement Crown]|h|r",
			["gp"] = 0,
		}, -- [514]
		{
			["player"] = "Esconar",
			["item"] = "Obsidian Edged Blade",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r",
			["gp"] = 0,
		}, -- [515]
		{
			["player"] = "Saccrilege",
			["item"] = "Netherwind Pants",
			["date"] = "09/28/19",
			["itemLink"] = "|cffa335ee|Hitem:16915|h[Netherwind Pants]|h|r",
			["gp"] = 250,
		}, -- [516]
		{
			["player"] = "Tikki",
			["item"] = "Legplates of Might",
			["date"] = "09/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
			["gp"] = 130,
		}, -- [517]
		{
			["player"] = "Lunamar",
			["item"] = "Talisman of Ephemeral Power",
			["date"] = "09/21/19",
			["itemLink"] = "|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
			["gp"] = 300,
		}, -- [518]
		{
			["player"] = "Klue",
			["item"] = "Felheart Gloves",
			["date"] = "09/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r",
			["gp"] = 0,
		}, -- [519]
		{
			["player"] = "Groggy",
			["item"] = "Lawbringer Gauntlets",
			["date"] = "09/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16860|h[Lawbringer Gauntlets]|h|r",
			["gp"] = 0,
		}, -- [520]
		{
			["player"] = "Basherslice",
			["item"] = "Giantstalker's Bracers",
			["date"] = "09/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16850|h[Giantstalker's Bracers]|h|r",
			["gp"] = 60,
		}, -- [521]
		{
			["player"] = "Bakedpancake",
			["item"] = "Mantle of Prophecy",
			["date"] = "09/21/19",
			["itemLink"] = "|cffa335ee|Hitem:16816|h[Mantle of Prophecy]|h|r",
			["gp"] = 0,
		}, -- [522]
	},
	["itemValues"] = {
		{
			"Aged Core Leather Gloves", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:18823|h[Aged Core Leather Gloves]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Rogue", -- [2]
			},
		}, -- [1]
		{
			"Amberseal Keeper", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:17113|h[Amberseal Keeper]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [2]
		{
			"Ancient Cornerstone Grimoire", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17067|h[Ancient Cornerstone Grimoire]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [3]
		{
			"Ancient Petrified Leaf", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18703|h[Ancient Petrified Leaf]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [4]
		{
			"Arcanist Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16802|h[Arcanist Belt]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [5]
		{
			"Arcanist Bindings", -- [1]
			60, -- [2]
			"|cffa335ee|Hitem:16799|h[Arcanist Bindings]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [6]
		{
			"Arcanist Boots", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16800|h[Arcanist Boots]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [7]
		{
			"Arcanist Crown", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16795|h[Arcanist Crown]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [8]
		{
			"Arcanist Gloves", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16801|h[Arcanist Gloves]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [9]
		{
			"Arcanist Leggings", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16796|h[Arcanist Leggings]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [10]
		{
			"Arcanist Mantle", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16797|h[Arcanist Mantle]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [11]
		{
			"Arcanist Robes", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16798|h[Arcanist Robes]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [12]
		{
			"Aurastone Hammer", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [13]
		{
			"Azuresong Mageblade", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:17103|h[Azuresong Mageblade]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Paladin (Holy)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [14]
		{
			"Band of Accuria", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:17063|h[Band of Accuria]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Rogue", -- [2]
				"Tank", -- [3]
			},
		}, -- [15]
		{
			"Band of Sulfuras", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19138|h[Band of Sulfuras]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [16]
		{
			"Belt of Might", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16864|h[Belt of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [17]
		{
			"Blacklight Bracer", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19135|h[Blacklight Bracer]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [18]
		{
			"Blastershot Launcher", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Rogue", -- [2]
				"Tank", -- [3]
			},
		}, -- [19]
		{
			"Blazefury Medallion", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17111|h[Blazefury Medallion]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [20]
		{
			"Bloodfang Hood", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16908|h[Bloodfang Hood]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [21]
		{
			"Bloodfang Pants", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16909|h[Bloodfang Pants]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [22]
		{
			"Bonereaver's Edge", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:17076|h[Bonereaver's Edge]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Paladin (Ret)", -- [2]
			},
		}, -- [23]
		{
			"Boots of Prophecy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16811|h[Boots of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [24]
		{
			"Bracers of Might", -- [1]
			60, -- [2]
			"|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [25]
		{
			"Breastplate of Might", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16865|h[Breastplate of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [26]
		{
			"Brutality Blade", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18832|h[Brutality Blade]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"Metal Rogue", -- [2]
				"Rogue", -- [3]
			},
		}, -- [27]
		{
			"Cauterizing Band", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19140|h[Cauterizing Band]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [28]
		{
			"Cenarion Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16828|h[Cenarion Belt]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [29]
		{
			"Cenarion Boots", -- [1]
			125, -- [2]
			"|cffa335ee|Hitem:16829|h[Cenarion Boots]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [30]
		{
			"Cenarion Bracers", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16830|h[Cenarion Bracers]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [31]
		{
			"Cenarion Gloves", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16831|h[Cenarion Gloves]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [32]
		{
			"Cenarion Helm", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16834|h[Cenarion Helm]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [33]
		{
			"Cenarion Leggings", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16835|h[Cenarion Leggings]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [34]
		{
			"Cenarion Spaulders", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16836|h[Cenarion Spaulders]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [35]
		{
			"Cenarion Vestments", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16833|h[Cenarion Vestments]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [36]
		{
			"Choker of Enlightenment", -- [1]
			60, -- [2]
			"|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [37]
		{
			"Choker of the Fire Lord", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:18814|h[Choker of the Fire Lord]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [38]
		{
			"Circlet of Prophecy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16813|h[Circlet of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [39]
		{
			"Cloak of the Shrouded Mists", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"KAT4FITE", -- [2]
				"Tank", -- [3]
			},
		}, -- [40]
		{
			"Cold Snap", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19130|h[Cold Snap]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [41]
		{
			"Core Forged Greaves", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18806|h[Core Forged Greaves]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [42]
		{
			"Core Hound Tooth", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:18805|h[Core Hound Tooth]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"Rogue", -- [2]
			},
		}, -- [43]
		{
			"Crimson Shocker", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17077|h[Crimson Shocker]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [44]
		{
			"Crown of Destruction", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18817|h[Crown of Destruction]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [45]
		{
			"Crystal Adorned Crown", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19132|h[Crystal Adorned Crown]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [46]
		{
			"Deathbringer", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:17068|h[Deathbringer]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
			},
		}, -- [47]
		{
			"Deep Earth Spaulders", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18829|h[Deep Earth Spaulders]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [48]
		{
			"Doomhide Gauntlets", -- [1]
			75, -- [2]
			"|cffa335ee|Hitem:18544|h[Doomhide Gauntlets]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
				"Rogue", -- [3]
			},
		}, -- [49]
		{
			"Dragon's Blood Cape", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Tank", -- [2]
			},
		}, -- [50]
		{
			"Dragonstalker's Helm", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16939|h[Dragonstalker's Helm]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [51]
		{
			"Dragonstalker's Legguards", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16938|h[Dragonstalker's Legguards]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [52]
		{
			"Drape of Benediction", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:18208|h[Drape of Benediction]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [53]
		{
			"Drillborer Disk", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [54]
		{
			"Earthshaker", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17073|h[Earthshaker]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [55]
		{
			"Empyrean Demolisher", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:17112|h[Empyrean Demolisher]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
			},
		}, -- [56]
		{
			"Eskhandar's Collar", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Tank", -- [2]
			},
		}, -- [57]
		{
			"Eskhandar's Left Claw", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:18202|h[Eskhandar's Left Claw]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Rogue", -- [2]
				"Tank", -- [3]
			},
		}, -- [58]
		{
			"Eskhandar's Pelt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18204|h[Eskhandar's Pelt]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
				"Rogue", -- [3]
				"Tank", -- [4]
			},
		}, -- [59]
		{
			"Eskhandar's Right Claw", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:18203|h[Eskhandar's Right Claw]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [60]
		{
			"Essence of the Pure Flame", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [61]
		{
			"Fang of the Mystics", -- [1]
			320, -- [2]
			"|cffa335ee|Hitem:17070|h[Fang of the Mystics]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Warlock", -- [2]
			},
		}, -- [62]
		{
			"Fel Infused Leggings", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r", -- [3]
			["priority"] = {
				"Priest (Shadow)", -- [1]
				"Warlock", -- [2]
			},
		}, -- [63]
		{
			"Felheart Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16806|h[Felheart Belt]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [64]
		{
			"Felheart Bracers", -- [1]
			60, -- [2]
			"|cffa335ee|Hitem:16804|h[Felheart Bracers]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [65]
		{
			"Felheart Gloves", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [66]
		{
			"Felheart Horns", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16808|h[Felheart Horns]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [67]
		{
			"Felheart Pants", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16810|h[Felheart Pants]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [68]
		{
			"Felheart Robes", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16809|h[Felheart Robes]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [69]
		{
			"Felheart Shoulder Pads", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16807|h[Felheart Shoulder Pads]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [70]
		{
			"Felheart Slippers", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16803|h[Felheart Slippers]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [71]
		{
			"Finkle's Lava Dredger", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18803|h[Finkle's Lava Dredger]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [72]
		{
			"Fire Runed Grimoire", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19142|h[Fire Runed Grimoire]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [73]
		{
			"Fireguard Shoulders", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19139|h[Fireguard Shoulders]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Progression", -- [2]
			},
		}, -- [74]
		{
			"Fireproof Cloak", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18811|h[Fireproof Cloak]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [75]
		{
			"Flameguard Gauntlets", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19143|h[Flameguard Gauntlets]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Paladin (Ret)", -- [2]
			},
		}, -- [76]
		{
			"Flamewaker Legplates", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [77]
		{
			"Flayed Doomguard Belt", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:19134|h[Flayed Doomguard Belt]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [78]
		{
			"Gauntlets of Might", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [79]
		{
			"Giantstalker's Belt", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16851|h[Giantstalker's Belt]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [80]
		{
			"Giantstalker's Boots", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16849|h[Giantstalker's Boots]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [81]
		{
			"Giantstalker's Bracers", -- [1]
			60, -- [2]
			"|cffa335ee|Hitem:16850|h[Giantstalker's Bracers]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [82]
		{
			"Giantstalker's Breastplate", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16845|h[Giantstalker's Breastplate]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [83]
		{
			"Giantstalker's Epaulets", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16848|h[Giantstalker's Epaulets]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [84]
		{
			"Giantstalker's Gloves", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16852|h[Giantstalker's Gloves]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [85]
		{
			"Giantstalker's Helmet", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16846|h[Giantstalker's Helmet]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [86]
		{
			"Giantstalker's Leggings", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16847|h[Giantstalker's Leggings]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [87]
		{
			"Girdle of Prophecy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16817|h[Girdle of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [88]
		{
			"Gloves of Prophecy", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [89]
		{
			"Gloves of the Hypnotic Flame", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18808|h[Gloves of the Hypnotic Flame]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [90]
		{
			"Gutgore Ripper", -- [1]
			70, -- [2]
			"|cffa335ee|Hitem:17071|h[Gutgore Ripper]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [91]
		{
			"Halo of Transcendence", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [92]
		{
			"Head of Onyxia", -- [1]
			75, -- [2]
			"|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"KAT4FITE", -- [2]
				"Metal Rogue", -- [3]
				"Rogue", -- [4]
				"Tank", -- [5]
			},
		}, -- [93]
		{
			"Heavy Dark Iron Ring", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Tank", -- [2]
			},
		}, -- [94]
		{
			"Helm of Might", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16866|h[Helm of Might]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [95]
		{
			"Helm of Wrath", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [96]
		{
			"Helm of the Lifegiver", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:18870|h[Helm of the Lifegiver]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [97]
		{
			"Infernal Headcage", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18546|h[Infernal Headcage]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [98]
		{
			"Judgement Crown", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16955|h[Judgement Crown]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [99]
		{
			"Judgement Legplates", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16954|h[Judgement Legplates]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [100]
		{
			"Lawbringer Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16858|h[Lawbringer Belt]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [101]
		{
			"Lawbringer Boots", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:16859|h[Lawbringer Boots]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [102]
		{
			"Lawbringer Bracers", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16857|h[Lawbringer Bracers]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [103]
		{
			"Lawbringer Chestguard", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16853|h[Lawbringer Chestguard]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [104]
		{
			"Lawbringer Gauntlets", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16860|h[Lawbringer Gauntlets]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [105]
		{
			"Lawbringer Helm", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16854|h[Lawbringer Helm]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [106]
		{
			"Lawbringer Legplates", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16855|h[Lawbringer Legplates]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [107]
		{
			"Lawbringer Spaulders", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16856|h[Lawbringer Spaulders]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [108]
		{
			"Leggings of Arcane Supremacy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18545|h[Leggings of Arcane Supremacy]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [109]
		{
			"Leggings of Transcendence", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [110]
		{
			"Legplates of Might", -- [1]
			130, -- [2]
			"|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [111]
		{
			"Legplates of Wrath", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [112]
		{
			"Magma Tempered Boots", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18824|h[Magma Tempered Boots]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [113]
		{
			"Malistar's Defender", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:17106|h[Malistar's Defender]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [114]
		{
			"Mana Igniting Cord", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Warlock", -- [2]
			},
		}, -- [115]
		{
			"Manastorm Leggings", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18872|h[Manastorm Leggings]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [116]
		{
			"Mantle of Prophecy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16816|h[Mantle of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [117]
		{
			"Medallion of Steadfast Might", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:17065|h[Medallion of Steadfast Might]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Tank", -- [2]
			},
		}, -- [118]
		{
			"Nemesis Leggings", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16930|h[Nemesis Leggings]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [119]
		{
			"Nemesis Skullcap", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [120]
		{
			"Netherwind Crown", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [121]
		{
			"Netherwind Pants", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:16915|h[Netherwind Pants]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [122]
		{
			"Nightslayer Belt", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16827|h[Nightslayer Belt]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [123]
		{
			"Nightslayer Boots", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16824|h[Nightslayer Boots]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [124]
		{
			"Nightslayer Bracelets", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16825|h[Nightslayer Bracelets]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [125]
		{
			"Nightslayer Chestpiece", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16820|h[Nightslayer Chestpiece]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [126]
		{
			"Nightslayer Cover", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16821|h[Nightslayer Cover]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [127]
		{
			"Nightslayer Gloves", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16826|h[Nightslayer Gloves]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [128]
		{
			"Nightslayer Pants", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16822|h[Nightslayer Pants]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [129]
		{
			"Nightslayer Shoulder Pads", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16823|h[Nightslayer Shoulder Pads]|h|r", -- [3]
			["priority"] = {
				"Rogue", -- [1]
			},
		}, -- [130]
		{
			"Obsidian Edged Blade", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [131]
		{
			"Onslaught Girdle", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19137|h[Onslaught Girdle]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Paladin (Ret)", -- [2]
			},
		}, -- [132]
		{
			"Pants of Prophecy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16814|h[Pants of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [133]
		{
			"Pauldrons of Might", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [134]
		{
			"Perdition's Blade", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18816|h[Perdition's Blade]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Rogue", -- [2]
			},
		}, -- [135]
		{
			"Puissant Cape", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:18541|h[Puissant Cape]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
				"Rogue", -- [3]
			},
		}, -- [136]
		{
			"Quick Strike Ring", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:18821|h[Quick Strike Ring]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
				"Rogue", -- [3]
			},
		}, -- [137]
		{
			"Ring of Binding", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [138]
		{
			"Ring of Entropy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18543|h[Ring of Entropy]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Paladin (Holy)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [139]
		{
			"Ring of Spell Power", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19147|h[Ring of Spell Power]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [140]
		{
			"Robe of Volatile Power", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Paladin (Holy)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [141]
		{
			"Robes of Prophecy", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16815|h[Robes of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [142]
		{
			"Sabatons of Might", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [143]
		{
			"Sabatons of the Flamewalker", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19144|h[Sabatons of the Flamewalker]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [144]
		{
			"Salamander Scale Pants", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:18875|h[Salamander Scale Pants]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [145]
		{
			"Sapphiron Drape", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [146]
		{
			"Sash of Whispered Secrets", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:18809|h[Sash of Whispered Secrets]|h|r", -- [3]
			["priority"] = {
				"Priest (Shadow)", -- [1]
				"Warlock", -- [2]
			},
		}, -- [147]
		{
			"Seal of the Archmagus", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [148]
		{
			"Shadowstrike", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17074|h[Shadowstrike]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [149]
		{
			"Shard of the Flame", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:17082|h[Shard of the Flame]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [150]
		{
			"Shard of the Scale", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:17064|h[Shard of the Scale]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [151]
		{
			"Snowblind Shoes", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19131|h[Snowblind Shoes]|h|r", -- [3]
			["priority"] = {
				"Priest (Shadow)", -- [1]
			},
		}, -- [152]
		{
			"Sorcerous Dagger", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:18878|h[Sorcerous Dagger]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Warlock", -- [2]
			},
		}, -- [153]
		{
			"Spinal Reaper", -- [1]
			110, -- [2]
			"|cffa335ee|Hitem:17104|h[Spinal Reaper]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Paladin (Ret)", -- [2]
			},
		}, -- [154]
		{
			"Staff of Dominance", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18842|h[Staff of Dominance]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Mage", -- [2]
				"Warlock", -- [3]
			},
		}, -- [155]
		{
			"Stormrage Cover", -- [1]
			125, -- [2]
			"|cffa335ee|Hitem:16900|h[Stormrage Cover]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [156]
		{
			"Stormrage Legguards", -- [1]
			75, -- [2]
			"|cffa335ee|Hitem:16901|h[Stormrage Legguards]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [157]
		{
			"Striker's Mark", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:17069|h[Striker's Mark]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Rogue", -- [2]
			},
		}, -- [158]
		{
			"Talisman of Ephemeral Power", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [159]
		{
			"The Eye of Divinity", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
				"Priest (Shadow)", -- [2]
			},
		}, -- [160]
		{
			"Typhoon", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18542|h[Typhoon]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [161]
		{
			"Unmelting Ice Girdle", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:18547|h[Unmelting Ice Girdle]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [162]
		{
			"Vambraces of Prophecy", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16819|h[Vambraces of Prophecy]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [163]
		{
			"Vis'kag the Bloodletter", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:17075|h[Vis'kag the Bloodletter]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Rogue", -- [2]
			},
		}, -- [164]
		{
			"Wild Growth Spaulders", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [165]
		{
			"Wristguards of Stability", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19146|h[Wristguards of Stability]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
			},
		}, -- [166]
		{
			"Wristguards of True Flight", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:18812|h[Wristguards of True Flight]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [167]
	},
};
_G.ABGP_Data[ABGP.Phases.p3] = {
	["gpHistory"] = {
		{
			["player"] = "Oya",
			["item"] = "Head of Nefarian",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19003|h[Head of Nefarian]|h|r",
			["gp"] = 150,
		}, -- [1]
		{
			["player"] = "Klisk",
			["item"] = "Archimtiros' Ring of Reckoning",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19376|h[Archimtiros' Ring of Reckoning]|h|r",
			["gp"] = 125,
		}, -- [2]
		{
			["player"] = "Darknéss",
			["item"] = "Pure Elementium Band",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19382|h[Pure Elementium Band]|h|r",
			["gp"] = 200,
		}, -- [3]
		{
			["player"] = "Groggy",
			["item"] = "Judgement Breastplate",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16958|h[Judgement Breastplate]|h|r",
			["gp"] = 0,
		}, -- [4]
		{
			["player"] = "Covenus",
			["item"] = "Dragonstalker's Breastplate",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16942|h[Dragonstalker's Breastplate]|h|r",
			["gp"] = 200,
		}, -- [5]
		{
			["player"] = "Krustytop",
			["item"] = "Claw of Chromaggus",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19347|h[Claw of Chromaggus]|h|r",
			["gp"] = 300,
		}, -- [6]
		{
			["player"] = "Lunamar",
			["item"] = "Netherwind Mantle",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16917|h[Netherwind Mantle]|h|r",
			["gp"] = 80,
		}, -- [7]
		{
			["gp"] = 0,
			["item"] = "Taut Dragonhide Shoulderpads",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19389|h[Taut Dragonhide Shoulderpads]|h|r",
			["player"] = "Suzukagozen",
		}, -- [8]
		{
			["player"] = "Lago",
			["item"] = "Pauldrons of Transcendence",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16924|h[Pauldrons of Transcendence]|h|r",
			["gp"] = 150,
		}, -- [9]
		{
			["player"] = "Tikki",
			["item"] = "Styleen's Impeding Scarab",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19431|h[Styleen's Impeding Scarab]|h|r",
			["gp"] = 325,
		}, -- [10]
		{
			["gp"] = 0,
			["item"] = "Stormrage Handguards",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16899|h[Stormrage Handguards]|h|r",
			["player"] = "Quellia",
		}, -- [11]
		{
			["player"] = "Friend",
			["item"] = "Band of Forced Concentration",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19403|h[Band of Forced Concentration]|h|r",
			["gp"] = 250,
		}, -- [12]
		{
			["player"] = "Quellia",
			["item"] = "Taut Dragonhide Belt",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19396|h[Taut Dragonhide Belt]|h|r",
			["gp"] = 0,
		}, -- [13]
		{
			["player"] = "Esconar",
			["item"] = "Legguards of the Fallen Crusader",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19402|h[Legguards of the Fallen Crusader]|h|r",
			["gp"] = 100,
		}, -- [14]
		{
			["player"] = "Starlight",
			["item"] = "Stormrage Handguards",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16899|h[Stormrage Handguards]|h|r",
			["gp"] = 150,
		}, -- [15]
		{
			["player"] = "Tikki",
			["item"] = "Lifegiving Gem",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19341|h[Lifegiving Gem]|h|r",
			["gp"] = 200,
		}, -- [16]
		{
			["player"] = "Bakedpancake",
			["item"] = "Boots of Transcendence",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16919|h[Boots of Transcendence]|h|r",
			["gp"] = 50,
		}, -- [17]
		{
			["player"] = "Ezekkiel",
			["item"] = "Netherwind Boots",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16912|h[Netherwind Boots]|h|r",
			["gp"] = 50,
		}, -- [18]
		{
			["player"] = "Jezail",
			["item"] = "Cloak of Draconic Might",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19436|h[Cloak of Draconic Might]|h|r",
			["gp"] = 150,
		}, -- [19]
		{
			["player"] = "Quellia",
			["item"] = "Draconic Maul",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19358|h[Draconic Maul]|h|r",
			["gp"] = 300,
		}, -- [20]
		{
			["player"] = "Soggybottom",
			["item"] = "Pendant of the Fallen Dragon",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:19371|h[Pendant of the Fallen Dragon]|h|r",
			["gp"] = 100,
		}, -- [21]
		{
			["player"] = "Tracer",
			["item"] = "Waistband of Wrath",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16960|h[Waistband of Wrath]|h|r",
			["gp"] = 100,
		}, -- [22]
		{
			["player"] = "Yoink",
			["item"] = "Bloodfang Belt",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16910|h[Bloodfang Belt]|h|r",
			["gp"] = 100,
		}, -- [23]
		{
			["player"] = "Lago",
			["item"] = "Bindings of Transcendence",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16926|h[Bindings of Transcendence]|h|r",
			["gp"] = 100,
		}, -- [24]
		{
			["player"] = "Klue",
			["item"] = "Nemesis Bracers",
			["date"] = "03/03/20",
			["itemLink"] = "|cffa335ee|Hitem:16934|h[Nemesis Bracers]|h|r",
			["gp"] = 100,
		}, -- [25]
		{
			["player"] = "Tracer",
			["item"] = "Head of Nefarian",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19003|h[Head of Nefarian]|h|r",
			["gp"] = 150,
		}, -- [26]
		{
			["player"] = "Ezekkiel",
			["item"] = "Staff of the Shadow Flame",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19356|h[Staff of the Shadow Flame]|h|r",
			["gp"] = 450,
		}, -- [27]
		{
			["player"] = "Clem",
			["item"] = "Cloak of the Brood Lord",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19378|h[Cloak of the Brood Lord]|h|r",
			["gp"] = 200,
		}, -- [28]
		{
			["player"] = "Azuj",
			["item"] = "Bloodfang Chestpiece",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16905|h[Bloodfang Chestpiece]|h|r",
			["gp"] = 200,
		}, -- [29]
		{
			["player"] = "Huntingkabu",
			["item"] = "Dragonstalker's Breastplate",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16942|h[Dragonstalker's Breastplate]|h|r",
			["gp"] = 200,
		}, -- [30]
		{
			["player"] = "Starlight",
			["item"] = "Shimmering Geta",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19391|h[Shimmering Geta]|h|r",
			["gp"] = 100,
		}, -- [31]
		{
			["player"] = "Cleaves",
			["item"] = "Chromatic Boots",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19387|h[Chromatic Boots]|h|r",
			["gp"] = 250,
		}, -- [32]
		{
			["player"] = "Soggybottom",
			["item"] = "Pauldrons of Transcendence",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16924|h[Pauldrons of Transcendence]|h|r",
			["gp"] = 150,
		}, -- [33]
		{
			["player"] = "Sausage",
			["item"] = "Pauldrons of Transcendence",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16924|h[Pauldrons of Transcendence]|h|r",
			["gp"] = 150,
		}, -- [34]
		{
			["player"] = "Soggybottom",
			["item"] = "Dragon's Touch",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19367|h[Dragon's Touch]|h|r",
			["gp"] = 30,
		}, -- [35]
		{
			["player"] = "Yoink",
			["item"] = "Bloodfang Gloves",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16907|h[Bloodfang Gloves]|h|r",
			["gp"] = 0,
		}, -- [36]
		{
			["gp"] = 0,
			["item"] = "Bloodfang Gloves",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16907|h[Bloodfang Gloves]|h|r",
			["player"] = "Suzukagozen",
		}, -- [37]
		{
			["player"] = "Sausage",
			["item"] = "Aegis of Preservation",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19345|h[Aegis of Preservation]|h|r",
			["gp"] = 0,
		}, -- [38]
		{
			["gp"] = 0,
			["item"] = "Doom's Edge",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19362|h[Doom's Edge]|h|r",
			["player"] = "Tracer",
		}, -- [39]
		{
			["player"] = "Frostishot",
			["item"] = "Dragonstalker's Gauntlets",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16940|h[Dragonstalker's Gauntlets]|h|r",
			["gp"] = 150,
		}, -- [40]
		{
			["player"] = "Friend",
			["item"] = "Black Ash Robe",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19399|h[Black Ash Robe]|h|r",
			["gp"] = 0,
		}, -- [41]
		{
			["player"] = "Marizol",
			["item"] = "Nemesis Boots",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16927|h[Nemesis Boots]|h|r",
			["gp"] = 100,
		}, -- [42]
		{
			["player"] = "Friend",
			["item"] = "Nemesis Boots",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16927|h[Nemesis Boots]|h|r",
			["gp"] = 100,
		}, -- [43]
		{
			["player"] = "Coop",
			["item"] = "Cloak of Draconic Might",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19436|h[Cloak of Draconic Might]|h|r",
			["gp"] = 150,
		}, -- [44]
		{
			["player"] = "Oya",
			["item"] = "Cloak of Draconic Might",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19436|h[Cloak of Draconic Might]|h|r",
			["gp"] = 150,
		}, -- [45]
		{
			["player"] = "Righteous",
			["item"] = "Judgement Belt",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16952|h[Judgement Belt]|h|r",
			["gp"] = 0,
		}, -- [46]
		{
			["player"] = "Nadrell",
			["item"] = "Judgement Belt",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16952|h[Judgement Belt]|h|r",
			["gp"] = 0,
		}, -- [47]
		{
			["player"] = "Quellia",
			["item"] = "Rune of Metamorphosis",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19340|h[Rune of Metamorphosis]|h|r",
			["gp"] = 0,
		}, -- [48]
		{
			["gp"] = 0,
			["item"] = "Bracelets of Wrath",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16959|h[Bracelets of Wrath]|h|r",
			["player"] = "Cleaves",
		}, -- [49]
		{
			["gp"] = 0,
			["item"] = "Nemesis Bracers",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:16934|h[Nemesis Bracers]|h|r",
			["player"] = "Knutbag",
		}, -- [50]
		{
			["player"] = "Xan",
			["item"] = "Mantle of the Blackwing Cabal",
			["date"] = "02/25/20",
			["itemLink"] = "|cffa335ee|Hitem:19370|h[Mantle of the Blackwing Cabal]|h|r",
			["gp"] = 200,
		}, -- [51]
		{
			["player"] = "Yoink",
			["item"] = "Head of Nefarian",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19003|h[Head of Nefarian]|h|r",
			["gp"] = 150,
		}, -- [52]
		{
			["player"] = "Righteous",
			["item"] = "Judgement Breastplate",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16958|h[Judgement Breastplate]|h|r",
			["gp"] = 0,
		}, -- [53]
		{
			["player"] = "Tikki",
			["item"] = "Therazane's Link",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19380|h[Therazane's Link]|h|r",
			["gp"] = 0,
		}, -- [54]
		{
			["player"] = "Krustytop",
			["item"] = "Nemesis Robes",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16931|h[Nemesis Robes]|h|r",
			["gp"] = 175,
		}, -- [55]
		{
			["player"] = "Xanido",
			["item"] = "Cloak of the Brood Lord",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19378|h[Cloak of the Brood Lord]|h|r",
			["gp"] = 200,
		}, -- [56]
		{
			["player"] = "Jezail",
			["item"] = "Chromatic Boots",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19387|h[Chromatic Boots]|h|r",
			["gp"] = 250,
		}, -- [57]
		{
			["player"] = "Priestpimp",
			["item"] = "Pauldrons of Transcendence",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16924|h[Pauldrons of Transcendence]|h|r",
			["gp"] = 150,
		}, -- [58]
		{
			["player"] = "Xanido",
			["item"] = "Netherwind Mantle",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16917|h[Netherwind Mantle]|h|r",
			["gp"] = 80,
		}, -- [59]
		{
			["player"] = "Klisk",
			["item"] = "Styleen's Impeding Scarab",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19431|h[Styleen's Impeding Scarab]|h|r",
			["gp"] = 325,
		}, -- [60]
		{
			["player"] = "Groggy",
			["item"] = "Judgement Gauntlets",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16956|h[Judgement Gauntlets]|h|r",
			["gp"] = 0,
		}, -- [61]
		{
			["player"] = "Quellia",
			["item"] = "Malfurion's Blessed Bulwark",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19405|h[Malfurion's Blessed Bulwark]|h|r",
			["gp"] = 150,
		}, -- [62]
		{
			["player"] = "Juicetea",
			["item"] = "Bloodfang Gloves",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16907|h[Bloodfang Gloves]|h|r",
			["gp"] = 50,
		}, -- [63]
		{
			["gp"] = 0,
			["item"] = "Firemaw's Clutch",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19400|h[Firemaw's Clutch]|h|r",
			["player"] = "Lago",
		}, -- [64]
		{
			["player"] = "Xanido",
			["item"] = "Shadow Wing Focus Staff",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19355|h[Shadow Wing Focus Staff]|h|r",
			["gp"] = 70,
		}, -- [65]
		{
			["player"] = "Wardrust",
			["item"] = "Maladath, Runed Blade of the Black Flight",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19351|h[Maladath, Runed Blade of the Black Flight]|h|r",
			["gp"] = 200,
		}, -- [66]
		{
			["gp"] = 0,
			["item"] = "Sabatons of Wrath",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16965|h[Sabatons of Wrath]|h|r",
			["player"] = "Cleaves",
		}, -- [67]
		{
			["player"] = "Juicetea",
			["item"] = "Bloodfang Boots",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16906|h[Bloodfang Boots]|h|r",
			["gp"] = 50,
		}, -- [68]
		{
			["player"] = "Gyda",
			["item"] = "Dragonfang Blade",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19346|h[Dragonfang Blade]|h|r",
			["gp"] = 70,
		}, -- [69]
		{
			["player"] = "Bakedpancake",
			["item"] = "Belt of Transcendence",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16925|h[Belt of Transcendence]|h|r",
			["gp"] = 100,
		}, -- [70]
		{
			["player"] = "Juicetea",
			["item"] = "Bloodfang Belt",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16910|h[Bloodfang Belt]|h|r",
			["gp"] = 100,
		}, -- [71]
		{
			["player"] = "Friend",
			["item"] = "The Black Book",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:19337|h[The Black Book]|h|r",
			["gp"] = 0,
		}, -- [72]
		{
			["player"] = "Gyda",
			["item"] = "Bloodfang Bracers",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16911|h[Bloodfang Bracers]|h|r",
			["gp"] = 100,
		}, -- [73]
		{
			["player"] = "Clem",
			["item"] = "Netherwind Bindings",
			["date"] = "02/18/20",
			["itemLink"] = "|cffa335ee|Hitem:16918|h[Netherwind Bindings]|h|r",
			["gp"] = 100,
		}, -- [74]
		{
			["player"] = "Zomby",
			["item"] = "Head of Nefarian",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19003|h[Head of Nefarian]|h|r",
			["gp"] = 150,
		}, -- [75]
		{
			["player"] = "Lunamar",
			["item"] = "Neltharion's Tear",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19379|h[Neltharion's Tear]|h|r",
			["gp"] = 400,
		}, -- [76]
		{
			["player"] = "Krustytop",
			["item"] = "Cloak of the Brood Lord",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19378|h[Cloak of the Brood Lord]|h|r",
			["gp"] = 200,
		}, -- [77]
		{
			["player"] = "Lago",
			["item"] = "Robes of Transcendence",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16923|h[Robes of Transcendence]|h|r",
			["gp"] = 200,
		}, -- [78]
		{
			["player"] = "Frostishot",
			["item"] = "Dragonstalker's Breastplate",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16942|h[Dragonstalker's Breastplate]|h|r",
			["gp"] = 200,
		}, -- [79]
		{
			["player"] = "Quellia",
			["item"] = "Taut Dragonhide Shoulderpads",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19389|h[Taut Dragonhide Shoulderpads]|h|r",
			["gp"] = 100,
		}, -- [80]
		{
			["player"] = "Basherslice",
			["item"] = "Ashjre'thul, Crossbow of Smiting",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19361|h[Ashjre'thul, Crossbow of Smiting]|h|r",
			["gp"] = 400,
		}, -- [81]
		{
			["player"] = "Groggy",
			["item"] = "Judgement Spaulders",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16953|h[Judgement Spaulders]|h|r",
			["gp"] = 0,
		}, -- [82]
		{
			["player"] = "Tracer",
			["item"] = "Pauldrons of Wrath",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16961|h[Pauldrons of Wrath]|h|r",
			["gp"] = 200,
		}, -- [83]
		{
			["player"] = "Tikki",
			["item"] = "Drake Talon Pauldrons",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19394|h[Drake Talon Pauldrons]|h|r",
			["gp"] = 250,
		}, -- [84]
		{
			["player"] = "Nadrell",
			["item"] = "Judgement Gauntlets",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16956|h[Judgement Gauntlets]|h|r",
			["gp"] = 0,
		}, -- [85]
		{
			["player"] = "Marizol",
			["item"] = "Ebony Flame Gloves",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19407|h[Ebony Flame Gloves]|h|r",
			["gp"] = 150,
		}, -- [86]
		{
			["player"] = "Coop",
			["item"] = "Doom's Edge",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19362|h[Doom's Edge]|h|r",
			["gp"] = 100,
		}, -- [87]
		{
			["player"] = "Xan",
			["item"] = "Ring of Blackrock",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19397|h[Ring of Blackrock]|h|r",
			["gp"] = 100,
		}, -- [88]
		{
			["player"] = "Xan",
			["item"] = "Firemaw's Clutch",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19400|h[Firemaw's Clutch]|h|r",
			["gp"] = 100,
		}, -- [89]
		{
			["player"] = "Friend",
			["item"] = "Bracers of Arcane Accuracy",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19374|h[Bracers of Arcane Accuracy]|h|r",
			["gp"] = 200,
		}, -- [90]
		{
			["player"] = "Righteous",
			["item"] = "Judgement Sabatons",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16957|h[Judgement Sabatons]|h|r",
			["gp"] = 0,
		}, -- [91]
		{
			["player"] = "Klisk",
			["item"] = "Sabatons of Wrath",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16965|h[Sabatons of Wrath]|h|r",
			["gp"] = 150,
		}, -- [92]
		{
			["player"] = "Groggy",
			["item"] = "Red Dragonscale Protector",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:19348|h[Red Dragonscale Protector]|h|r",
			["gp"] = 0,
		}, -- [93]
		{
			["player"] = "Krustytop",
			["item"] = "Nemesis Belt",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16933|h[Nemesis Belt]|h|r",
			["gp"] = 0,
		}, -- [94]
		{
			["player"] = "Knutbag",
			["item"] = "Nemesis Belt",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16933|h[Nemesis Belt]|h|r",
			["gp"] = 0,
		}, -- [95]
		{
			["player"] = "Azuj",
			["item"] = "Bloodfang Bracers",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16911|h[Bloodfang Bracers]|h|r",
			["gp"] = 100,
		}, -- [96]
		{
			["player"] = "Klisk",
			["item"] = "Bracelets of Wrath",
			["date"] = "02/12/20",
			["itemLink"] = "|cffa335ee|Hitem:16959|h[Bracelets of Wrath]|h|r",
			["gp"] = 100,
		}, -- [97]
	},
	["itemValues"] = {
		{
			"Aegis of Preservation", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19345|h[Aegis of Preservation]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [1]
		{
			"Angelista's Grasp", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19388|h[Angelista's Grasp]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [2]
		{
			"Arcane Infused Gem", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19336|h[Arcane Infused Gem]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [3]
		{
			"Archimtiros' Ring of Reckoning", -- [1]
			125, -- [2]
			"|cffa335ee|Hitem:19376|h[Archimtiros' Ring of Reckoning]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Tank", -- [2]
			},
		}, -- [4]
		{
			"Ashjre'thul, Crossbow of Smiting", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19361|h[Ashjre'thul, Crossbow of Smiting]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [5]
		{
			"Ashkandi, Greatsword of the Brotherhood", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19364|h[Ashkandi, Greatsword of the Brotherhood]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [6]
		{
			"Band of Dark Dominion", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19434|h[Band of Dark Dominion]|h|r", -- [3]
			["priority"] = {
				"Priest (Shadow)", -- [1]
				"Warlock", -- [2]
			},
		}, -- [7]
		{
			"Band of Forced Concentration", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19403|h[Band of Forced Concentration]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [8]
		{
			"Belt of Transcendence", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16925|h[Belt of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [9]
		{
			"Bindings of Transcendence", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16926|h[Bindings of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [10]
		{
			"Black Ash Robe", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19399|h[Black Ash Robe]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [11]
		{
			"Black Brood Pauldrons", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19373|h[Black Brood Pauldrons]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [12]
		{
			"Bloodfang Belt", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16910|h[Bloodfang Belt]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
				"Stabby Rogue", -- [2]
			},
		}, -- [13]
		{
			"Bloodfang Boots", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16906|h[Bloodfang Boots]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
			},
		}, -- [14]
		{
			"Bloodfang Bracers", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16911|h[Bloodfang Bracers]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
				"Stabby Rogue", -- [2]
			},
		}, -- [15]
		{
			"Bloodfang Chestpiece", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16905|h[Bloodfang Chestpiece]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
				"Stabby Rogue", -- [2]
			},
		}, -- [16]
		{
			"Bloodfang Gloves", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16907|h[Bloodfang Gloves]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
			},
		}, -- [17]
		{
			"Bloodfang Spaulders", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16832|h[Bloodfang Spaulders]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
			},
		}, -- [18]
		{
			"Boots of Pure Thought", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19437|h[Boots of Pure Thought]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [19]
		{
			"Boots of Transcendence", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16919|h[Boots of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [20]
		{
			"Boots of the Shadow Flame", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19381|h[Boots of the Shadow Flame]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Stabby Rogue", -- [2]
			},
		}, -- [21]
		{
			"Bracelets of Wrath", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16959|h[Bracelets of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [22]
		{
			"Bracers of Arcane Accuracy", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19374|h[Bracers of Arcane Accuracy]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [23]
		{
			"Breastplate of Wrath", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16966|h[Breastplate of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [24]
		{
			"Chromatic Boots", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19387|h[Chromatic Boots]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
			},
		}, -- [25]
		{
			"Chromatically Tempered Sword", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19352|h[Chromatically Tempered Sword]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Slicey Rogue", -- [2]
			},
		}, -- [26]
		{
			"Circle of Applied Force", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19432|h[Circle of Applied Force]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
				"Slicey Rogue", -- [3]
				"Stabby Rogue", -- [4]
				"Tank", -- [5]
			},
		}, -- [27]
		{
			"Claw of Chromaggus", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19347|h[Claw of Chromaggus]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Warlock", -- [2]
			},
		}, -- [28]
		{
			"Claw of the Black Drake", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19365|h[Claw of the Black Drake]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [29]
		{
			"Cloak of Draconic Might", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19436|h[Cloak of Draconic Might]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
			},
		}, -- [30]
		{
			"Cloak of Firemaw", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19398|h[Cloak of Firemaw]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Slicey Rogue", -- [2]
				"Stabby Rogue", -- [3]
			},
		}, -- [31]
		{
			"Cloak of the Brood Lord", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19378|h[Cloak of the Brood Lord]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [32]
		{
			"Crul'shorukh, Edge of Chaos", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19363|h[Crul'shorukh, Edge of Chaos]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
			},
		}, -- [33]
		{
			"Doom's Edge", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19362|h[Doom's Edge]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"Metal Rogue", -- [2]
			},
		}, -- [34]
		{
			"Draconic Avenger", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19354|h[Draconic Avenger]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [35]
		{
			"Draconic Maul", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19358|h[Draconic Maul]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
			},
		}, -- [36]
		{
			"Dragon's Touch", -- [1]
			30, -- [2]
			"|cffa335ee|Hitem:19367|h[Dragon's Touch]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [37]
		{
			"Dragonbreath Hand Cannon", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19368|h[Dragonbreath Hand Cannon]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
				"Stabby Rogue", -- [2]
				"Tank", -- [3]
			},
		}, -- [38]
		{
			"Dragonfang Blade", -- [1]
			70, -- [2]
			"|cffa335ee|Hitem:19346|h[Dragonfang Blade]|h|r", -- [3]
			["notes"] = "Catch up Priority",
			["priority"] = {
				"Hunter", -- [1]
				"Stabby Rogue", -- [2]
				"Tank", -- [3]
			},
		}, -- [39]
		{
			"Dragonstalker's Belt", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16936|h[Dragonstalker's Belt]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [40]
		{
			"Dragonstalker's Bracers", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16935|h[Dragonstalker's Bracers]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [41]
		{
			"Dragonstalker's Breastplate", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16942|h[Dragonstalker's Breastplate]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [42]
		{
			"Dragonstalker's Gauntlets", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16940|h[Dragonstalker's Gauntlets]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [43]
		{
			"Dragonstalker's Greaves", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16941|h[Dragonstalker's Greaves]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [44]
		{
			"Dragonstalker's Spaulders", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16937|h[Dragonstalker's Spaulders]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
			},
		}, -- [45]
		{
			"Drake Fang Talisman", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19406|h[Drake Fang Talisman]|h|r", -- [3]
			["notes"] = "Feral Druid prio unlocks after 4 drops",
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
				"Slicey Rogue", -- [3]
				"Stabby Rogue", -- [4]
			},
		}, -- [46]
		{
			"Drake Talon Cleaver", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19353|h[Drake Talon Cleaver]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [47]
		{
			"Drake Talon Pauldrons", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19394|h[Drake Talon Pauldrons]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Tank", -- [2]
			},
		}, -- [48]
		{
			"Ebony Flame Gloves", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19407|h[Ebony Flame Gloves]|h|r", -- [3]
			["priority"] = {
				"Priest (Shadow)", -- [1]
				"Warlock", -- [2]
			},
		}, -- [49]
		{
			"Elementium Reinforced Bulwark", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19349|h[Elementium Reinforced Bulwark]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [50]
		{
			"Elementium Threaded Cloak", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19386|h[Elementium Threaded Cloak]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Tank", -- [2]
			},
		}, -- [51]
		{
			"Emberweave Leggings", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19433|h[Emberweave Leggings]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [52]
		{
			"Empowered Leggings", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19385|h[Empowered Leggings]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [53]
		{
			"Essence Gatherer", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19435|h[Essence Gatherer]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [54]
		{
			"Firemaw's Clutch", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19400|h[Firemaw's Clutch]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
			},
			["notes"] = "Shadow Priest Super Priority",
		}, -- [55]
		{
			"Gauntlets of Wrath", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16964|h[Gauntlets of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [56]
		{
			"Girdle of the Fallen Crusader", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19392|h[Girdle of the Fallen Crusader]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [57]
		{
			"Gloves of Rapid Evolution", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19369|h[Gloves of Rapid Evolution]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [58]
		{
			"Handguards of Transcendence", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16920|h[Handguards of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [59]
		{
			"Head of Nefarian", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19003|h[Head of Nefarian]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"KAT4FITE", -- [2]
				"Metal Rogue", -- [3]
				"Slicey Rogue", -- [4]
				"Stabby Rogue", -- [5]
				"Tank", -- [6]
			},
			["notes"] = "Casters with a BWL 1h also eligible",
		}, -- [60]
		{
			"Heartstriker", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19350|h[Heartstriker]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Slicey Rogue", -- [2]
				"Stabby Rogue", -- [3]
				"Tank", -- [4]
			},
		}, -- [61]
		{
			"Helm of Endless Rage", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19372|h[Helm of Endless Rage]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [62]
		{
			"Herald of Woe", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19357|h[Herald of Woe]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [63]
		{
			"Interlaced Shadow Jerkin", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19439|h[Interlaced Shadow Jerkin]|h|r", -- [3]
			["priority"] = {
				"Progression", -- [1]
			},
		}, -- [64]
		{
			"Judgement Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16952|h[Judgement Belt]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [65]
		{
			"Judgement Bindings", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16951|h[Judgement Bindings]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [66]
		{
			"Judgement Breastplate", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16958|h[Judgement Breastplate]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [67]
		{
			"Judgement Gauntlets", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16956|h[Judgement Gauntlets]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [68]
		{
			"Judgement Sabatons", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16957|h[Judgement Sabatons]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [69]
		{
			"Judgement Spaulders", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16953|h[Judgement Spaulders]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [70]
		{
			"Legguards of the Fallen Crusader", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19402|h[Legguards of the Fallen Crusader]|h|r", -- [3]
			["priority"] = {
				"Metal Rogue", -- [1]
				"Tank", -- [2]
			},
		}, -- [71]
		{
			"Lifegiving Gem", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19341|h[Lifegiving Gem]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [72]
		{
			"Lok'amir il Romathis", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19360|h[Lok'amir il Romathis]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [73]
		{
			"Maladath, Runed Blade of the Black Flight", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19351|h[Maladath, Runed Blade of the Black Flight]|h|r", -- [3]
			["notes"] = "Non-Human Rogues also",
			["priority"] = {
				"Metal Rogue", -- [1]
				"Tank", -- [2]
			},
		}, -- [74]
		{
			"Malfurion's Blessed Bulwark", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:19405|h[Malfurion's Blessed Bulwark]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
				"Metal Rogue", -- [2]
			},
			["notes"] = "Feral Druid Super Priority",
		}, -- [75]
		{
			"Mantle of the Blackwing Cabal", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19370|h[Mantle of the Blackwing Cabal]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Priest (Shadow)", -- [2]
			},
			["notes"] = "Shadow Priest Super Priority",
		}, -- [76]
		{
			"Mind Quickening Gem", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19339|h[Mind Quickening Gem]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [77]
		{
			"Mish'undare, Circlet of the Mind Flayer", -- [1]
			300, -- [2]
			"|cffa335ee|Hitem:19375|h[Mish'undare, Circlet of the Mind Flayer]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Paladin (Holy)", -- [2]
				"Warlock", -- [3]
			},
		}, -- [78]
		{
			"Neltharion's Tear", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19379|h[Neltharion's Tear]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Warlock", -- [2]
			},
			["notes"] = "Shadow Priest Prio Unlocks after 4 drops",
		}, -- [79]
		{
			"Nemesis Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16933|h[Nemesis Belt]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [80]
		{
			"Nemesis Boots", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16927|h[Nemesis Boots]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [81]
		{
			"Nemesis Bracers", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16934|h[Nemesis Bracers]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [82]
		{
			"Nemesis Gloves", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16928|h[Nemesis Gloves]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [83]
		{
			"Nemesis Robes", -- [1]
			175, -- [2]
			"|cffa335ee|Hitem:16931|h[Nemesis Robes]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [84]
		{
			"Nemesis Spaulders", -- [1]
			125, -- [2]
			"|cffa335ee|Hitem:16932|h[Nemesis Spaulders]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [85]
		{
			"Netherwind Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16818|h[Netherwind Belt]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [86]
		{
			"Netherwind Bindings", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16918|h[Netherwind Bindings]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [87]
		{
			"Netherwind Boots", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16912|h[Netherwind Boots]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [88]
		{
			"Netherwind Gloves", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16913|h[Netherwind Gloves]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [89]
		{
			"Netherwind Mantle", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:16917|h[Netherwind Mantle]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [90]
		{
			"Netherwind Robes", -- [1]
			175, -- [2]
			"|cffa335ee|Hitem:16916|h[Netherwind Robes]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [91]
		{
			"Pauldrons of Transcendence", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16924|h[Pauldrons of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [92]
		{
			"Pauldrons of Wrath", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16961|h[Pauldrons of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [93]
		{
			"Pendant of the Fallen Dragon", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19371|h[Pendant of the Fallen Dragon]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [94]
		{
			"Prestor's Talisman of Connivery", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19377|h[Prestor's Talisman of Connivery]|h|r", -- [3]
			["priority"] = {
				"Hunter", -- [1]
				"KAT4FITE", -- [2]
				"Slicey Rogue", -- [3]
				"Stabby Rogue", -- [4]
			},
		}, -- [95]
		{
			"Primalist's Linked Legguards", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19401|h[Primalist's Linked Legguards]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [96]
		{
			"Primalist's Linked Legguards", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19401|h[Primalist's Linked Legguards]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [97]
		{
			"Pure Elementium Band", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19382|h[Pure Elementium Band]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [98]
		{
			"Red Dragonscale Protector", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19348|h[Red Dragonscale Protector]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [99]
		{
			"Rejuvenating Gem", -- [1]
			400, -- [2]
			"|cffa335ee|Hitem:19395|h[Rejuvenating Gem]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [100]
		{
			"Ring of Blackrock", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19397|h[Ring of Blackrock]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
				"Priest (Shadow)", -- [4]
			},
		}, -- [101]
		{
			"Ringo's Blizzard Boots", -- [1]
			250, -- [2]
			"|cffa335ee|Hitem:19438|h[Ringo's Blizzard Boots]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
			},
		}, -- [102]
		{
			"Robes of Transcendence", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:16923|h[Robes of Transcendence]|h|r", -- [3]
			["priority"] = {
				"Priest (Heal)", -- [1]
			},
		}, -- [103]
		{
			"Rune of Metamorphosis", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19340|h[Rune of Metamorphosis]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [104]
		{
			"Sabatons of Wrath", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16965|h[Sabatons of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [105]
		{
			"Scrolls of Blinding Light", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19343|h[Scrolls of Blinding Light]|h|r", -- [3]
			["priority"] = {
				"Paladin (Holy)", -- [1]
			},
		}, -- [106]
		{
			"Shadow Wing Focus Staff", -- [1]
			70, -- [2]
			"|cffa335ee|Hitem:19355|h[Shadow Wing Focus Staff]|h|r", -- [3]
			["notes"] = "Catch up Priority",
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Mage", -- [2]
				"Warlock", -- [3]
			},
		}, -- [107]
		{
			"Shimmering Geta", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19391|h[Shimmering Geta]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [108]
		{
			"Shroud of Pure Thought", -- [1]
			200, -- [2]
			"|cffa335ee|Hitem:19430|h[Shroud of Pure Thought]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
				"Priest (Heal)", -- [3]
			},
		}, -- [109]
		{
			"Spineshatter", -- [1]
			70, -- [2]
			"|cffa335ee|Hitem:19335|h[Spineshatter]|h|r", -- [3]
			["notes"] = "Catch up Priority",
			["priority"] = {
				"Metal Rogue", -- [1]
				"Slicey Rogue", -- [2]
				"Stabby Rogue", -- [3]
				"Tank", -- [4]
			},
		}, -- [110]
		{
			"Staff of the Shadow Flame", -- [1]
			450, -- [2]
			"|cffa335ee|Hitem:19356|h[Staff of the Shadow Flame]|h|r", -- [3]
			["priority"] = {
				"Mage", -- [1]
				"Warlock", -- [2]
			},
		}, -- [111]
		{
			"Stormrage Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16903|h[Stormrage Belt]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [112]
		{
			"Stormrage Boots", -- [1]
			50, -- [2]
			"|cffa335ee|Hitem:16898|h[Stormrage Boots]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [113]
		{
			"Stormrage Bracers", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16904|h[Stormrage Bracers]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [114]
		{
			"Stormrage Chestguard", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16897|h[Stormrage Chestguard]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [115]
		{
			"Stormrage Handguards", -- [1]
			150, -- [2]
			"|cffa335ee|Hitem:16899|h[Stormrage Handguards]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [116]
		{
			"Stormrage Pauldrons", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:16902|h[Stormrage Pauldrons]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
			},
		}, -- [117]
		{
			"Styleen's Impeding Scarab", -- [1]
			325, -- [2]
			"|cffa335ee|Hitem:19431|h[Styleen's Impeding Scarab]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [118]
		{
			"Taut Dragonhide Belt", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19396|h[Taut Dragonhide Belt]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [119]
		{
			"Taut Dragonhide Gloves", -- [1]
			80, -- [2]
			"|cffa335ee|Hitem:19390|h[Taut Dragonhide Gloves]|h|r", -- [3]
			["priority"] = {
				"Druid (Heal)", -- [1]
				"Paladin (Holy)", -- [2]
			},
		}, -- [120]
		{
			"Taut Dragonhide Shoulderpads", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:19389|h[Taut Dragonhide Shoulderpads]|h|r", -- [3]
			["priority"] = {
				"KAT4FITE", -- [1]
			},
		}, -- [121]
		{
			"The Black Book", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19337|h[The Black Book]|h|r", -- [3]
			["priority"] = {
				"Warlock", -- [1]
			},
		}, -- [122]
		{
			"The Untamed Blade", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19334|h[The Untamed Blade]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [123]
		{
			"Therazane's Link", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19380|h[Therazane's Link]|h|r", -- [3]
			["priority"] = {
				"Garbage", -- [1]
			},
		}, -- [124]
		{
			"Venomous Totem", -- [1]
			0, -- [2]
			"|cffa335ee|Hitem:19342|h[Venomous Totem]|h|r", -- [3]
			["priority"] = {
				"Slicey Rogue", -- [1]
				"Stabby Rogue", -- [2]
			},
		}, -- [125]
		{
			"Waistband of Wrath", -- [1]
			100, -- [2]
			"|cffa335ee|Hitem:16960|h[Waistband of Wrath]|h|r", -- [3]
			["priority"] = {
				"Tank", -- [1]
			},
		}, -- [126]
	},
}

--
-- END copy from SavedVariables
--
local initialData = {
    timestamp = 1583640491, -- https://www.epochconverter.com/ or GetServerTime() ingame
    ABGP_Data = ABGP_Data,
};

function ABGP:CheckHardcodedData()
    if _G.ABGP_DataTimestamp == nil or _G.ABGP_DataTimestamp < initialData.timestamp then
        _G.ABGP_DataTimestamp = initialData.timestamp;
        _G.ABGP_Data = initialData.ABGP_Data;
    end
end
