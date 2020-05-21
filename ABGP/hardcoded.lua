local _G = _G;
local ABGP = _G.ABGP;

local pairs = pairs;
local type = type;

_G.ABGP_Data = {};

ABGP.initialData = {
	itemValues = {
		timestamp = 1587944770, -- https://www.epochconverter.com/ or GetServerTime() ingame
		[ABGP.PhasesAll.p1] = {
			{
				"Aged Core Leather Gloves",
				200,
				"|cffa335ee|Hitem:18823|h[Aged Core Leather Gloves]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Amberseal Keeper",
				150,
				"|cffa335ee|Hitem:17113|h[Amberseal Keeper]|h|r",
				"Kazzak",
				{
					"Druid (Heal)",
					"Mage",
					"Warlock",
				},
			},
			{
				"Ancient Cornerstone Grimoire",
				0,
				"|cffa335ee|Hitem:17067|h[Ancient Cornerstone Grimoire]|h|r",
				"Onyxia",
				{
					"Garbage",
				},
			},
			{
				"Ancient Petrified Leaf",
				300,
				"|cffa335ee|Hitem:18703|h[Ancient Petrified Leaf]|h|r",
				"Majordomo Executus",
				{
					"Hunter",
				},
			},
			{
				"Arcanist Belt",
				0,
				"|cffa335ee|Hitem:16802|h[Arcanist Belt]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Arcanist Bindings",
				60,
				"|cffa335ee|Hitem:16799|h[Arcanist Bindings]|h|r",
				"Tier 1 Sets",
				{
					"Mage",
				},
			},
			{
				"Arcanist Boots",
				150,
				"|cffa335ee|Hitem:16800|h[Arcanist Boots]|h|r",
				"Tier 1 Sets",
				{
					"Mage",
				},
			},
			{
				"Arcanist Crown",
				200,
				"|cffa335ee|Hitem:16795|h[Arcanist Crown]|h|r",
				"Tier 1 Sets",
				{
					"Mage",
				},
			},
			{
				"Arcanist Gloves",
				0,
				"|cffa335ee|Hitem:16801|h[Arcanist Gloves]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Arcanist Leggings",
				80,
				"|cffa335ee|Hitem:16796|h[Arcanist Leggings]|h|r",
				"Tier 1 Sets",
				{
					"Mage",
				},
			},
			{
				"Arcanist Mantle",
				0,
				"|cffa335ee|Hitem:16797|h[Arcanist Mantle]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Arcanist Robes",
				0,
				"|cffa335ee|Hitem:16798|h[Arcanist Robes]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Aurastone Hammer",
				50,
				"|cffa335ee|Hitem:17105|h[Aurastone Hammer]|h|r",
				"Garr",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Azuresong Mageblade",
				300,
				"|cffa335ee|Hitem:17103|h[Azuresong Mageblade]|h|r",
				"Golemagg",
				{
					"Mage",
					"Warlock",
				},
			},
			{
				"Band of Accuria",
				300,
				"|cffa335ee|Hitem:17063|h[Band of Accuria]|h|r",
				"Ragnaros",
				{
					"KAT4FITE",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
				"Tank Super Prio, Red Reserved",
			},
			{
				"Band of Sulfuras",
				0,
				"|cffa335ee|Hitem:19138|h[Band of Sulfuras]|h|r",
				"Ragnaros",
				{
					"Garbage",
				},
			},
			{
				"Belt of Might",
				80,
				"|cffa335ee|Hitem:16864|h[Belt of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Blacklight Bracer",
				0,
				"|cffa335ee|Hitem:19135|h[Blacklight Bracer]|h|r",
				"Kazzak",
				{
					"Garbage",
				},
			},
			{
				"Blastershot Launcher",
				100,
				"|cffa335ee|Hitem:17072|h[Blastershot Launcher]|h|r",
				"Golemagg",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Blazefury Medallion",
				0,
				"|cffa335ee|Hitem:17111|h[Blazefury Medallion]|h|r",
				"Kazzak",
				{
					"Garbage",
				},
			},
			{
				"Bloodfang Hood",
				200,
				"|cffa335ee|Hitem:16908|h[Bloodfang Hood]|h|r",
				"Tier 2 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Bloodfang Pants",
				200,
				"|cffa335ee|Hitem:16909|h[Bloodfang Pants]|h|r",
				"Tier 2 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Bonereaver's Edge",
				300,
				"|cffa335ee|Hitem:17076|h[Bonereaver's Edge]|h|r",
				"Ragnaros",
				{
					"Metal Rogue",
					"Paladin (Ret)",
				},
			},
			{
				"Boots of Prophecy",
				0,
				"|cffa335ee|Hitem:16811|h[Boots of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Bracers of Might",
				60,
				"|cffa335ee|Hitem:16861|h[Bracers of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Breastplate of Might",
				150,
				"|cffa335ee|Hitem:16865|h[Breastplate of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Brutality Blade",
				300,
				"|cffa335ee|Hitem:18832|h[Brutality Blade]|h|r",
				"Garr",
				{
					"Hunter",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Cauterizing Band",
				250,
				"|cffa335ee|Hitem:19140|h[Cauterizing Band]|h|r",
				"Majordomo Executus",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Cenarion Belt",
				0,
				"|cffa335ee|Hitem:16828|h[Cenarion Belt]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cenarion Boots",
				125,
				"|cffa335ee|Hitem:16829|h[Cenarion Boots]|h|r",
				"Tier 1 Sets",
				{
					"Druid (Heal)",
				},
			},
			{
				"Cenarion Bracers",
				0,
				"|cffa335ee|Hitem:16830|h[Cenarion Bracers]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cenarion Gloves",
				0,
				"|cffa335ee|Hitem:16831|h[Cenarion Gloves]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cenarion Helm",
				0,
				"|cffa335ee|Hitem:16834|h[Cenarion Helm]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cenarion Leggings",
				0,
				"|cffa335ee|Hitem:16835|h[Cenarion Leggings]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cenarion Spaulders",
				0,
				"|cffa335ee|Hitem:16836|h[Cenarion Spaulders]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cenarion Vestments",
				0,
				"|cffa335ee|Hitem:16833|h[Cenarion Vestments]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Choker of Enlightenment",
				60,
				"|cffa335ee|Hitem:17109|h[Choker of Enlightenment]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Choker of the Fire Lord",
				250,
				"|cffa335ee|Hitem:18814|h[Choker of the Fire Lord]|h|r",
				"Ragnaros",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
				"Red Reserved",
			},
			{
				"Circlet of Prophecy",
				0,
				"|cffa335ee|Hitem:16813|h[Circlet of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Cloak of the Shrouded Mists",
				100,
				"|cffa335ee|Hitem:17102|h[Cloak of the Shrouded Mists]|h|r",
				"Ragnaros",
				{
					"Hunter",
					"KAT4FITE",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Cold Snap",
				100,
				"|cffa335ee|Hitem:19130|h[Cold Snap]|h|r",
				"Azuregos",
				{
					"Mage",
				},
			},
			{
				"Core Forged Greaves",
				0,
				"|cffa335ee|Hitem:18806|h[Core Forged Greaves]|h|r",
				"Majordomo Executus",
				{
					"Progression",
				},
			},
			{
				"Core Hound Tooth",
				250,
				"|cffa335ee|Hitem:18805|h[Core Hound Tooth]|h|r",
				"Majordomo Executus",
				{
					"Hunter",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Crimson Shocker",
				0,
				"|cffa335ee|Hitem:17077|h[Crimson Shocker]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Progression",
				},
			},
			{
				"Crown of Destruction",
				0,
				"|cffa335ee|Hitem:18817|h[Crown of Destruction]|h|r",
				"Ragnaros",
				{
					"Garbage",
				},
			},
			{
				"Crystal Adorned Crown",
				300,
				"|cffa335ee|Hitem:19132|h[Crystal Adorned Crown]|h|r",
				"Azuregos",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Deathbringer",
				200,
				"|cffa335ee|Hitem:17068|h[Deathbringer]|h|r",
				"Onyxia",
				{
					"Metal Rogue",
				},
			},
			{
				"Deep Earth Spaulders",
				0,
				"|cffa335ee|Hitem:18829|h[Deep Earth Spaulders]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Garbage",
				},
			},
			{
				"Doomhide Gauntlets",
				75,
				"|cffa335ee|Hitem:18544|h[Doomhide Gauntlets]|h|r",
				"Kazzak",
				{
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Dragon's Blood Cape",
				100,
				"|cffa335ee|Hitem:17107|h[Dragon's Blood Cape]|h|r",
				"Ragnaros",
				{
					"KAT4FITE",
					"Tank",
				},
			},
			{
				"Dragonstalker's Helm",
				250,
				"|cffa335ee|Hitem:16939|h[Dragonstalker's Helm]|h|r",
				"Tier 2 Sets",
				{
					"Hunter",
				},
			},
			{
				"Dragonstalker's Legguards",
				250,
				"|cffa335ee|Hitem:16938|h[Dragonstalker's Legguards]|h|r",
				"Tier 2 Sets",
				{
					"Hunter",
				},
			},
			{
				"Drape of Benediction",
				50,
				"|cffa335ee|Hitem:18208|h[Drape of Benediction]|h|r",
				"Azuregos",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Drillborer Disk",
				100,
				"|cffa335ee|Hitem:17066|h[Drillborer Disk]|h|r",
				"Garr",
				{
					"Tank",
				},
			},
			{
				"Earthshaker",
				0,
				"|cffa335ee|Hitem:17073|h[Earthshaker]|h|r",
				"Magmadar",
				{
					"Garbage",
				},
			},
			{
				"Empyrean Demolisher",
				300,
				"|cffa335ee|Hitem:17112|h[Empyrean Demolisher]|h|r",
				"Kazzak",
				{
					"Metal Rogue",
				},
			},
			{
				"Eskhandar's Collar",
				30,
				"|cffa335ee|Hitem:18205|h[Eskhandar's Collar]|h|r",
				"Onyxia",
				{
					"KAT4FITE",
					"Tank",
				},
			},
			{
				"Eskhandar's Left Claw",
				50,
				"|cffa335ee|Hitem:18202|h[Eskhandar's Left Claw]|h|r",
				"Azuregos",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Eskhandar's Pelt",
				0,
				"|cffa335ee|Hitem:18204|h[Eskhandar's Pelt]|h|r",
				"Kazzak",
				{
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Eskhandar's Right Claw",
				100,
				"|cffa335ee|Hitem:18203|h[Eskhandar's Right Claw]|h|r",
				"Magmadar",
				{
					"Tank",
				},
			},
			{
				"Essence of the Pure Flame",
				0,
				"|cffa335ee|Hitem:18815|h[Essence of the Pure Flame]|h|r",
				"Ragnaros",
				{
					"Garbage",
				},
			},
			{
				"Fang of the Mystics",
				320,
				"|cffa335ee|Hitem:17070|h[Fang of the Mystics]|h|r",
				"Azuregos",
				{
					"Mage",
					"Warlock",
				},
			},
			{
				"Fel Infused Leggings",
				300,
				"|cffa335ee|Hitem:19133|h[Fel Infused Leggings]|h|r",
				"Kazzak",
				{
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Felheart Belt",
				0,
				"|cffa335ee|Hitem:16806|h[Felheart Belt]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Felheart Bracers",
				60,
				"|cffa335ee|Hitem:16804|h[Felheart Bracers]|h|r",
				"Tier 1 Sets",
				{
					"Warlock",
				},
			},
			{
				"Felheart Gloves",
				0,
				"|cffa335ee|Hitem:16805|h[Felheart Gloves]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Felheart Horns",
				0,
				"|cffa335ee|Hitem:16808|h[Felheart Horns]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Felheart Pants",
				0,
				"|cffa335ee|Hitem:16810|h[Felheart Pants]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Felheart Robes",
				0,
				"|cffa335ee|Hitem:16809|h[Felheart Robes]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Felheart Shoulder Pads",
				0,
				"|cffa335ee|Hitem:16807|h[Felheart Shoulder Pads]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Felheart Slippers",
				0,
				"|cffa335ee|Hitem:16803|h[Felheart Slippers]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Finkle's Lava Dredger",
				0,
				"|cffa335ee|Hitem:18803|h[Finkle's Lava Dredger]|h|r",
				"Majordomo Executus",
				{
					"Progression",
				},
			},
			{
				"Fire Runed Grimoire",
				0,
				"|cffa335ee|Hitem:19142|h[Fire Runed Grimoire]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Garbage",
				},
			},
			{
				"Fireguard Shoulders",
				0,
				"|cffa335ee|Hitem:19139|h[Fireguard Shoulders]|h|r",
				"Majordomo Executus",
				{
					"KAT4FITE",
					"Progression",
				},
			},
			{
				"Fireproof Cloak",
				0,
				"|cffa335ee|Hitem:18811|h[Fireproof Cloak]|h|r",
				"Majordomo Executus",
				{
					"Progression",
				},
			},
			{
				"Flameguard Gauntlets",
				100,
				"|cffa335ee|Hitem:19143|h[Flameguard Gauntlets]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Metal Rogue",
					"Paladin (Ret)",
				},
			},
			{
				"Flamewaker Legplates",
				0,
				"|cffa335ee|Hitem:18861|h[Flamewaker Legplates]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Progression",
				},
			},
			{
				"Flayed Doomguard Belt",
				30,
				"|cffa335ee|Hitem:19134|h[Flayed Doomguard Belt]|h|r",
				"Kazzak",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Gauntlets of Might",
				100,
				"|cffa335ee|Hitem:16863|h[Gauntlets of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Giantstalker's Belt",
				80,
				"|cffa335ee|Hitem:16851|h[Giantstalker's Belt]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Boots",
				150,
				"|cffa335ee|Hitem:16849|h[Giantstalker's Boots]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Bracers",
				60,
				"|cffa335ee|Hitem:16850|h[Giantstalker's Bracers]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Breastplate",
				150,
				"|cffa335ee|Hitem:16845|h[Giantstalker's Breastplate]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Epaulets",
				150,
				"|cffa335ee|Hitem:16848|h[Giantstalker's Epaulets]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Gloves",
				100,
				"|cffa335ee|Hitem:16852|h[Giantstalker's Gloves]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Helmet",
				150,
				"|cffa335ee|Hitem:16846|h[Giantstalker's Helmet]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Giantstalker's Leggings",
				150,
				"|cffa335ee|Hitem:16847|h[Giantstalker's Leggings]|h|r",
				"Tier 1 Sets",
				{
					"Hunter",
				},
			},
			{
				"Girdle of Prophecy",
				0,
				"|cffa335ee|Hitem:16817|h[Girdle of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Gloves of Prophecy",
				50,
				"|cffa335ee|Hitem:16812|h[Gloves of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Priest (Heal)",
				},
			},
			{
				"Gloves of the Hypnotic Flame",
				0,
				"|cffa335ee|Hitem:18808|h[Gloves of the Hypnotic Flame]|h|r",
				"Majordomo Executus",
				{
					"Garbage",
				},
			},
			{
				"Gutgore Ripper",
				70,
				"|cffa335ee|Hitem:17071|h[Gutgore Ripper]|h|r",
				"Garr",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Halo of Transcendence",
				250,
				"|cffa335ee|Hitem:16921|h[Halo of Transcendence]|h|r",
				"Tier 2 Sets",
				{
					"Priest (Heal)",
				},
			},
			{
				"Head of Onyxia",
				75,
				"|cffa335ee|Hitem:18423|h[Head of Onyxia]|h|r",
				"Onyxia",
				{
					"Hunter",
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Heavy Dark Iron Ring",
				100,
				"|cffa335ee|Hitem:18879|h[Heavy Dark Iron Ring]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"KAT4FITE",
					"Tank",
				},
			},
			{
				"Helm of Might",
				0,
				"|cffa335ee|Hitem:16866|h[Helm of Might]|h|r",
				"Tier 1 Sets",
				{
					"Progression",
				},
			},
			{
				"Helm of the Lifegiver",
				30,
				"|cffa335ee|Hitem:18870|h[Helm of the Lifegiver]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Helm of Wrath",
				250,
				"|cffa335ee|Hitem:16963|h[Helm of Wrath]|h|r",
				"Tier 2 Sets",
				{
					"Tank",
				},
			},
			{
				"Infernal Headcage",
				0,
				"|cffa335ee|Hitem:18546|h[Infernal Headcage]|h|r",
				"Kazzak",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Judgement Crown",
				0,
				"|cffa335ee|Hitem:16955|h[Judgement Crown]|h|r",
				"Tier 2 Sets",
				{
					"Progression",
				},
			},
			{
				"Judgement Legplates",
				0,
				"|cffa335ee|Hitem:16954|h[Judgement Legplates]|h|r",
				"Tier 2 Sets",
				{
					"Progression",
				},
			},
			{
				"Lawbringer Belt",
				0,
				"|cffa335ee|Hitem:16858|h[Lawbringer Belt]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Lawbringer Boots",
				30,
				"|cffa335ee|Hitem:16859|h[Lawbringer Boots]|h|r",
				"Tier 1 Sets",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Lawbringer Bracers",
				0,
				"|cffa335ee|Hitem:16857|h[Lawbringer Bracers]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Lawbringer Chestguard",
				0,
				"|cffa335ee|Hitem:16853|h[Lawbringer Chestguard]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Lawbringer Gauntlets",
				0,
				"|cffa335ee|Hitem:16860|h[Lawbringer Gauntlets]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Lawbringer Helm",
				0,
				"|cffa335ee|Hitem:16854|h[Lawbringer Helm]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Lawbringer Legplates",
				0,
				"|cffa335ee|Hitem:16855|h[Lawbringer Legplates]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Lawbringer Spaulders",
				0,
				"|cffa335ee|Hitem:16856|h[Lawbringer Spaulders]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Leggings of Arcane Supremacy",
				0,
				"|cffa335ee|Hitem:18545|h[Leggings of Arcane Supremacy]|h|r",
				"Azuregos",
				{
					"Mage",
				},
			},
			{
				"Leggings of Transcendence",
				200,
				"|cffa335ee|Hitem:16922|h[Leggings of Transcendence]|h|r",
				"Tier 2 Sets",
				{
					"Priest (Heal)",
				},
			},
			{
				"Legplates of Might",
				130,
				"|cffa335ee|Hitem:16867|h[Legplates of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Legplates of Wrath",
				250,
				"|cffa335ee|Hitem:16962|h[Legplates of Wrath]|h|r",
				"Tier 2 Sets",
				{
					"Tank",
				},
			},
			{
				"Magma Tempered Boots",
				0,
				"|cffa335ee|Hitem:18824|h[Magma Tempered Boots]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Progression",
				},
			},
			{
				"Malistar's Defender",
				30,
				"|cffa335ee|Hitem:17106|h[Malistar's Defender]|h|r",
				"Ragnaros",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Mana Igniting Cord",
				250,
				"|cffa335ee|Hitem:19136|h[Mana Igniting Cord]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Mage",
				},
			},
			{
				"Manastorm Leggings",
				0,
				"|cffa335ee|Hitem:18872|h[Manastorm Leggings]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Garbage",
				},
			},
			{
				"Mantle of Prophecy",
				0,
				"|cffa335ee|Hitem:16816|h[Mantle of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Medallion of Steadfast Might",
				150,
				"|cffa335ee|Hitem:17065|h[Medallion of Steadfast Might]|h|r",
				"Magmadar",
				{
					"KAT4FITE",
					"Tank",
				},
			},
			{
				"Nemesis Leggings",
				250,
				"|cffa335ee|Hitem:16930|h[Nemesis Leggings]|h|r",
				"Tier 2 Sets",
				{
					"Warlock",
				},
			},
			{
				"Nemesis Skullcap",
				250,
				"|cffa335ee|Hitem:16929|h[Nemesis Skullcap]|h|r",
				"Tier 2 Sets",
				{
					"Warlock",
				},
			},
			{
				"Netherwind Crown",
				80,
				"|cffa335ee|Hitem:16914|h[Netherwind Crown]|h|r",
				"Tier 2 Sets",
				{
					"Mage",
				},
			},
			{
				"Netherwind Pants",
				250,
				"|cffa335ee|Hitem:16915|h[Netherwind Pants]|h|r",
				"Tier 2 Sets",
				{
					"Mage",
				},
			},
			{
				"Nightslayer Belt",
				80,
				"|cffa335ee|Hitem:16827|h[Nightslayer Belt]|h|r",
				"Tier 1 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Nightslayer Boots",
				100,
				"|cffa335ee|Hitem:16824|h[Nightslayer Boots]|h|r",
				"Tier 1 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Nightslayer Bracelets",
				0,
				"|cffa335ee|Hitem:16825|h[Nightslayer Bracelets]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Nightslayer Chestpiece",
				100,
				"|cffa335ee|Hitem:16820|h[Nightslayer Chestpiece]|h|r",
				"Tier 1 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Nightslayer Cover",
				0,
				"|cffa335ee|Hitem:16821|h[Nightslayer Cover]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Nightslayer Gloves",
				0,
				"|cffa335ee|Hitem:16826|h[Nightslayer Gloves]|h|r",
				"Tier 1 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Nightslayer Pants",
				0,
				"|cffa335ee|Hitem:16822|h[Nightslayer Pants]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Nightslayer Shoulder Pads",
				100,
				"|cffa335ee|Hitem:16823|h[Nightslayer Shoulder Pads]|h|r",
				"Tier 1 Sets",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Obsidian Edged Blade",
				0,
				"|cffa335ee|Hitem:18822|h[Obsidian Edged Blade]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Garbage",
				},
			},
			{
				"Onslaught Girdle",
				300,
				"|cffa335ee|Hitem:19137|h[Onslaught Girdle]|h|r",
				"Ragnaros",
				{
					"Metal Rogue",
					"Paladin (Ret)",
				},
				"Red Reserved",
			},
			{
				"Pants of Prophecy",
				0,
				"|cffa335ee|Hitem:16814|h[Pants of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Priest (Heal)",
				},
			},
			{
				"Pauldrons of Might",
				150,
				"|cffa335ee|Hitem:16868|h[Pauldrons of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Perdition's Blade",
				300,
				"|cffa335ee|Hitem:18816|h[Perdition's Blade]|h|r",
				"Ragnaros",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Shard of the Flame",
				0,
				"|cffa335ee|Hitem:17082|h[Shard of the Flame]|h|r",
				"Ragnaros",
				{
					"Garbage",
				},
			},
			{
				"Puissant Cape",
				150,
				"|cffa335ee|Hitem:18541|h[Puissant Cape]|h|r",
				"Azuregos",
				{
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Quick Strike Ring",
				200,
				"|cffa335ee|Hitem:18821|h[Quick Strike Ring]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Metal Rogue",
				},
				"Red Reserved",
			},
			{
				"Ring of Binding",
				0,
				"|cffa335ee|Hitem:18813|h[Ring of Binding]|h|r",
				"Onyxia",
				{
					"Progression",
				},
			},
			{
				"Ring of Entropy",
				0,
				"|cffa335ee|Hitem:18543|h[Ring of Entropy]|h|r",
				"Kazzak",
				{
					"Mage",
					"Paladin (Holy)",
					"Warlock",
				},
			},
			{
				"Ring of Spell Power",
				250,
				"|cffa335ee|Hitem:19147|h[Ring of Spell Power]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Robe of Volatile Power",
				300,
				"|cffa335ee|Hitem:19145|h[Robe of Volatile Power]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Mage",
					"Paladin (Holy)",
					"Warlock",
				},
			},
			{
				"Robes of Prophecy",
				0,
				"|cffa335ee|Hitem:16815|h[Robes of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Garbage",
				},
			},
			{
				"Sabatons of Might",
				150,
				"|cffa335ee|Hitem:16862|h[Sabatons of Might]|h|r",
				"Tier 1 Sets",
				{
					"Tank",
				},
			},
			{
				"Sabatons of the Flamewalker",
				0,
				"|cffa335ee|Hitem:19144|h[Sabatons of the Flamewalker]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Garbage",
				},
			},
			{
				"Salamander Scale Pants",
				100,
				"|cffa335ee|Hitem:18875|h[Salamander Scale Pants]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Sapphiron Drape",
				80,
				"|cffa335ee|Hitem:17078|h[Sapphiron Drape]|h|r",
				"Onyxia",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Sash of Whispered Secrets",
				200,
				"|cffa335ee|Hitem:18809|h[Sash of Whispered Secrets]|h|r",
				"Majordomo Executus",
				{
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Seal of the Archmagus",
				0,
				"|cffa335ee|Hitem:17110|h[Seal of the Archmagus]|h|r",
				"Baron Geddon",
				{
					"Progression",
				},
			},
			{
				"Shadowstrike",
				0,
				"|cffa335ee|Hitem:17074|h[Shadowstrike]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Garbage",
				},
			},
			{
				"Shard of the Scale",
				200,
				"|cffa335ee|Hitem:17064|h[Shard of the Scale]|h|r",
				"Onyxia",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Snowblind Shoes",
				150,
				"|cffa335ee|Hitem:19131|h[Snowblind Shoes]|h|r",
				"Azuregos",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
				"Shadow Priest Super Prio",
			},
			{
				"Sorcerous Dagger",
				30,
				"|cffa335ee|Hitem:18878|h[Sorcerous Dagger]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"Mage",
					"Warlock",
				},
			},
			{
				"Spinal Reaper",
				110,
				"|cffa335ee|Hitem:17104|h[Spinal Reaper]|h|r",
				"Ragnaros",
				{
					"Metal Rogue",
					"Paladin (Ret)",
				},
			},
			{
				"Staff of Dominance",
				300,
				"|cffa335ee|Hitem:18842|h[Staff of Dominance]|h|r",
				"Golemagg",
				{
					"Druid (Heal)",
					"Mage",
					"Warlock",
				},
			},
			{
				"Stormrage Cover",
				125,
				"|cffa335ee|Hitem:16900|h[Stormrage Cover]|h|r",
				"Tier 2 Sets",
				{
					"Druid (Heal)",
				},
			},
			{
				"Stormrage Legguards",
				75,
				"|cffa335ee|Hitem:16901|h[Stormrage Legguards]|h|r",
				"Tier 2 Sets",
				{
					"Druid (Heal)",
				},
			},
			{
				"Striker's Mark",
				100,
				"|cffa335ee|Hitem:17069|h[Striker's Mark]|h|r",
				"Magmadar",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Talisman of Ephemeral Power",
				300,
				"|cffa335ee|Hitem:18820|h[Talisman of Ephemeral Power]|h|r",
				"Magmadar, Garr, Baron Geddon, Golemagg",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"The Eye of Divinity",
				300,
				"|cffa335ee|Hitem:18646|h[The Eye of Divinity]|h|r",
				"Majordomo Executus",
				{
					"Priest (Heal)",
					"Priest (Shadow)",
				},
			},
			{
				"Typhoon",
				0,
				"|cffa335ee|Hitem:18542|h[Typhoon]|h|r",
				"Azuregos",
				{
					"Garbage",
				},
			},
			{
				"Unmelting Ice Girdle",
				0,
				"|cffa335ee|Hitem:18547|h[Unmelting Ice Girdle]|h|r",
				"Azuregos",
				{
					"Progression",
				},
				"Red Reserved",
			},
			{
				"Vambraces of Prophecy",
				100,
				"|cffa335ee|Hitem:16819|h[Vambraces of Prophecy]|h|r",
				"Tier 1 Sets",
				{
					"Priest (Heal)",
				},
			},
			{
				"Vis'kag the Bloodletter",
				300,
				"|cffa335ee|Hitem:17075|h[Vis'kag the Bloodletter]|h|r",
				"Onyxia",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Wild Growth Spaulders",
				300,
				"|cffa335ee|Hitem:18810|h[Wild Growth Spaulders]|h|r",
				"Majordomo Executus",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Wristguards of Stability",
				150,
				"|cffa335ee|Hitem:19146|h[Wristguards of Stability]|h|r",
				"Lucifron, Gehennas, Shazzrah, Sulfuron",
				{
					"KAT4FITE",
					"Metal Rogue",
				},
			},
			{
				"Wristguards of True Flight",
				30,
				"|cffa335ee|Hitem:18812|h[Wristguards of True Flight]|h|r",
				"Majordomo Executus",
				{
					"Tank",
				},
			},
		},
		[ABGP.PhasesAll.p3] = {
			{
				"Bindings of Transcendence",
				100,
				"|cffa335ee|Hitem:16926|h[Bindings of Transcendence]|h|r",
				"Razorgore the Untamed",
				{
					"Priest (Heal)",
				},
			},
			{
				"Netherwind Bindings",
				100,
				"|cffa335ee|Hitem:16918|h[Netherwind Bindings]|h|r",
				"Razorgore the Untamed",
				{
					"Mage",
				},
			},
			{
				"Nemesis Bracers",
				100,
				"|cffa335ee|Hitem:16934|h[Nemesis Bracers]|h|r",
				"Razorgore the Untamed",
				{
					"Warlock",
				},
			},
			{
				"Bloodfang Bracers",
				100,
				"|cffa335ee|Hitem:16911|h[Bloodfang Bracers]|h|r",
				"Razorgore the Untamed",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Stormrage Bracers",
				100,
				"|cffa335ee|Hitem:16904|h[Stormrage Bracers]|h|r",
				"Razorgore the Untamed",
				{
					"Druid (Heal)",
				},
			},
			{
				"Dragonstalker's Bracers",
				100,
				"|cffa335ee|Hitem:16935|h[Dragonstalker's Bracers]|h|r",
				"Razorgore the Untamed",
				{
					"Hunter",
				},
			},
			{
				"Judgement Bindings",
				0,
				"|cffa335ee|Hitem:16951|h[Judgement Bindings]|h|r",
				"Razorgore the Untamed",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Bracelets of Wrath",
				100,
				"|cffa335ee|Hitem:16959|h[Bracelets of Wrath]|h|r",
				"Razorgore the Untamed",
				{
					"Tank",
				},
			},
			{
				"Arcane Infused Gem",
				0,
				"|cffa335ee|Hitem:19336|h[Arcane Infused Gem]|h|r",
				"Razorgore the Untamed",
				{
					"Hunter",
				},
			},
			{
				"The Black Book",
				0,
				"|cffa335ee|Hitem:19337|h[The Black Book]|h|r",
				"Razorgore the Untamed",
				{
					"Warlock",
				},
			},
			{
				"Mantle of the Blackwing Cabal",
				200,
				"|cffa335ee|Hitem:19370|h[Mantle of the Blackwing Cabal]|h|r",
				"Razorgore the Untamed",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
				"Shadow Priest Super Priority",
			},
			{
				"Gloves of Rapid Evolution",
				0,
				"|cffa335ee|Hitem:19369|h[Gloves of Rapid Evolution]|h|r",
				"Razorgore the Untamed",
				{
					"Garbage",
				},
			},
			{
				"Spineshatter",
				70,
				"|cffa335ee|Hitem:19335|h[Spineshatter]|h|r",
				"Razorgore the Untamed",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
				"Catch up Priority",
			},
			{
				"The Untamed Blade",
				0,
				"|cffa335ee|Hitem:19334|h[The Untamed Blade]|h|r",
				"Razorgore the Untamed",
				{
					"Garbage",
				},
			},
			{
				"Belt of Transcendence",
				100,
				"|cffa335ee|Hitem:16925|h[Belt of Transcendence]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Priest (Heal)",
				},
			},
			{
				"Netherwind Belt",
				0,
				"|cffa335ee|Hitem:16818|h[Netherwind Belt]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Mage",
				},
			},
			{
				"Nemesis Belt",
				0,
				"|cffa335ee|Hitem:16933|h[Nemesis Belt]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Warlock",
				},
			},
			{
				"Bloodfang Belt",
				100,
				"|cffa335ee|Hitem:16910|h[Bloodfang Belt]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Stormrage Belt",
				0,
				"|cffa335ee|Hitem:16903|h[Stormrage Belt]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Druid (Heal)",
				},
			},
			{
				"Dragonstalker's Belt",
				100,
				"|cffa335ee|Hitem:16936|h[Dragonstalker's Belt]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Hunter",
				},
			},
			{
				"Judgement Belt",
				0,
				"|cffa335ee|Hitem:16952|h[Judgement Belt]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Waistband of Wrath",
				100,
				"|cffa335ee|Hitem:16960|h[Waistband of Wrath]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Tank",
				},
			},
			{
				"Mind Quickening Gem",
				100,
				"|cffa335ee|Hitem:19339|h[Mind Quickening Gem]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Mage",
				},
			},
			{
				"Rune of Metamorphosis",
				0,
				"|cffa335ee|Hitem:19340|h[Rune of Metamorphosis]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Druid (Heal)",
				},
			},
			{
				"Helm of Endless Rage",
				150,
				"|cffa335ee|Hitem:19372|h[Helm of Endless Rage]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Tank",
				},
			},
			{
				"Pendant of the Fallen Dragon",
				100,
				"|cffa335ee|Hitem:19371|h[Pendant of the Fallen Dragon]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Red Dragonscale Protector",
				0,
				"|cffa335ee|Hitem:19348|h[Red Dragonscale Protector]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Dragonfang Blade",
				70,
				"|cffa335ee|Hitem:19346|h[Dragonfang Blade]|h|r",
				"Vaelastraz the Corrupt",
				{
					"Hunter",
					"Stabby Rogue",
					"Tank",
				},
				"Catch up Priority",
			},
			{
				"Boots of Transcendence",
				50,
				"|cffa335ee|Hitem:16919|h[Boots of Transcendence]|h|r",
				"Broodlord Lashlayer",
				{
					"Priest (Heal)",
				},
			},
			{
				"Nemesis Boots",
				0,
				"|cffa335ee|Hitem:16927|h[Nemesis Boots]|h|r",
				"Broodlord Lashlayer",
				{
					"Warlock",
				},
			},
			{
				"Netherwind Boots",
				0,
				"|cffa335ee|Hitem:16912|h[Netherwind Boots]|h|r",
				"Broodlord Lashlayer",
				{
					"Mage",
				},
			},
			{
				"Bloodfang Boots",
				50,
				"|cffa335ee|Hitem:16906|h[Bloodfang Boots]|h|r",
				"Broodlord Lashlayer",
				{
					"Slicey Rogue",
				},
			},
			{
				"Stormrage Boots",
				50,
				"|cffa335ee|Hitem:16898|h[Stormrage Boots]|h|r",
				"Broodlord Lashlayer",
				{
					"Druid (Heal)",
				},
			},
			{
				"Dragonstalker's Greaves",
				150,
				"|cffa335ee|Hitem:16941|h[Dragonstalker's Greaves]|h|r",
				"Broodlord Lashlayer",
				{
					"Hunter",
				},
			},
			{
				"Judgement Sabatons",
				0,
				"|cffa335ee|Hitem:16957|h[Judgement Sabatons]|h|r",
				"Broodlord Lashlayer",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Sabatons of Wrath",
				150,
				"|cffa335ee|Hitem:16965|h[Sabatons of Wrath]|h|r",
				"Broodlord Lashlayer",
				{
					"Tank",
				},
			},
			{
				"Lifegiving Gem",
				200,
				"|cffa335ee|Hitem:19341|h[Lifegiving Gem]|h|r",
				"Broodlord Lashlayer",
				{
					"Tank",
				},
			},
			{
				"Venomous Totem",
				0,
				"|cffa335ee|Hitem:19342|h[Venomous Totem]|h|r",
				"Broodlord Lashlayer",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Black Brood Pauldrons",
				0,
				"|cffa335ee|Hitem:19373|h[Black Brood Pauldrons]|h|r",
				"Broodlord Lashlayer",
				{
					"Garbage",
				},
			},
			{
				"Bracers of Arcane Accuracy",
				200,
				"|cffa335ee|Hitem:19374|h[Bracers of Arcane Accuracy]|h|r",
				"Broodlord Lashlayer",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Heartstriker",
				100,
				"|cffa335ee|Hitem:19350|h[Heartstriker]|h|r",
				"Broodlord Lashlayer",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Maladath, Runed Blade of the Black Flight",
				200,
				"|cffa335ee|Hitem:19351|h[Maladath, Runed Blade of the Black Flight]|h|r",
				"Broodlord Lashlayer",
				{
					"Metal Rogue",
					"Tank",
				},
				"Non-Human Rogues also",
			},
			{
				"Handguards of Transcendence",
				80,
				"|cffa335ee|Hitem:16920|h[Handguards of Transcendence]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Priest (Heal)",
				},
			},
			{
				"Netherwind Gloves",
				0,
				"|cffa335ee|Hitem:16913|h[Netherwind Gloves]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Mage",
				},
			},
			{
				"Nemesis Gloves",
				0,
				"|cffa335ee|Hitem:16928|h[Nemesis Gloves]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Warlock",
				},
			},
			{
				"Bloodfang Gloves",
				50,
				"|cffa335ee|Hitem:16907|h[Bloodfang Gloves]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Slicey Rogue",
				},
			},
			{
				"Stormrage Handguards",
				150,
				"|cffa335ee|Hitem:16899|h[Stormrage Handguards]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Druid (Heal)",
				},
			},
			{
				"Dragonstalker's Gauntlets",
				150,
				"|cffa335ee|Hitem:16940|h[Dragonstalker's Gauntlets]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Hunter",
				},
			},
			{
				"Judgement Gauntlets",
				0,
				"|cffa335ee|Hitem:16956|h[Judgement Gauntlets]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Gauntlets of Wrath",
				150,
				"|cffa335ee|Hitem:16964|h[Gauntlets of Wrath]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Tank",
				},
			},
			{
				"Scrolls of Blinding Light",
				0,
				"|cffa335ee|Hitem:19343|h[Scrolls of Blinding Light]|h|r",
				"Firemaw",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Drake Talon Pauldrons",
				250,
				"|cffa335ee|Hitem:19394|h[Drake Talon Pauldrons]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Metal Rogue",
					"Tank",
				},
			},
			{
				"Cloak of Firemaw",
				150,
				"|cffa335ee|Hitem:19398|h[Cloak of Firemaw]|h|r",
				"Firemaw",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Black Ash Robe",
				0,
				"|cffa335ee|Hitem:19399|h[Black Ash Robe]|h|r",
				"Firemaw",
				{
					"Progression",
				},
			},
			{
				"Firemaw's Clutch",
				200,
				"|cffa335ee|Hitem:19400|h[Firemaw's Clutch]|h|r",
				"Firemaw",
				{
					"Mage",
					"Priest (Shadow)",
				},
				"Shadow Priest Super Priority",
			},
			{
				"Taut Dragonhide Belt",
				0,
				"|cffa335ee|Hitem:19396|h[Taut Dragonhide Belt]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Garbage",
				},
			},
			{
				"Primalist's Linked Legguards",
				0,
				"|cffa335ee|Hitem:19401|h[Primalist's Linked Legguards]|h|r",
				"Firemaw",
				{
					"Garbage",
				},
			},
			{
				"Legguards of the Fallen Crusader",
				100,
				"|cffa335ee|Hitem:19402|h[Legguards of the Fallen Crusader]|h|r",
				"Firemaw",
				{
					"Metal Rogue",
					"Tank",
				},
			},
			{
				"Claw of the Black Drake",
				0,
				"|cffa335ee|Hitem:19365|h[Claw of the Black Drake]|h|r",
				"Firemaw",
				{
					"Garbage",
				},
			},
			{
				"Drake Talon Cleaver",
				0,
				"|cffa335ee|Hitem:19353|h[Drake Talon Cleaver]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Garbage",
				},
			},
			{
				"Shadow Wing Focus Staff",
				70,
				"|cffa335ee|Hitem:19355|h[Shadow Wing Focus Staff]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Druid (Heal)",
					"Mage",
					"Warlock",
				},
				"Catch up Priority",
			},
			{
				"Ring of Blackrock",
				100,
				"|cffa335ee|Hitem:19397|h[Ring of Blackrock]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
					"Priest (Shadow)",
				},
			},
			{
				"Rejuvenating Gem",
				400,
				"|cffa335ee|Hitem:19395|h[Rejuvenating Gem]|h|r",
				"Firemaw, Ebonroc, Flamegor",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Ebony Flame Gloves",
				200,
				"|cffa335ee|Hitem:19407|h[Ebony Flame Gloves]|h|r",
				"Ebonroc",
				{
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Malfurion's Blessed Bulwark",
				150,
				"|cffa335ee|Hitem:19405|h[Malfurion's Blessed Bulwark]|h|r",
				"Ebonroc",
				{
					"KAT4FITE",
					"Metal Rogue",
				},
				"Feral Druid Super Priority",
			},
			{
				"Dragonbreath Hand Cannon",
				100,
				"|cffa335ee|Hitem:19368|h[Dragonbreath Hand Cannon]|h|r",
				"Ebonroc",
				{
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Band of Forced Concentration",
				250,
				"|cffa335ee|Hitem:19403|h[Band of Forced Concentration]|h|r",
				"Ebonroc",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Aegis of Preservation",
				0,
				"|cffa335ee|Hitem:19345|h[Aegis of Preservation]|h|r",
				"Ebonroc",
				{
					"Priest (Heal)",
				},
			},
			{
				"Drake Fang Talisman",
				400,
				"|cffa335ee|Hitem:19406|h[Drake Fang Talisman]|h|r",
				"Ebonroc",
				{
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
				},
				"Feral Druid prio unlocks after 4 drops",
			},
			{
				"Shroud of Pure Thought",
				200,
				"|cffa335ee|Hitem:19430|h[Shroud of Pure Thought]|h|r",
				"Flamegor",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Emberweave Leggings",
				0,
				"|cffa335ee|Hitem:19433|h[Emberweave Leggings]|h|r",
				"Flamegor",
				{
					"Progression",
				},
			},
			{
				"Dragon's Touch",
				0,
				"|cffa335ee|Hitem:19367|h[Dragon's Touch]|h|r",
				"Flamegor",
				{
					"Garbage",
				},
			},
			{
				"Herald of Woe",
				0,
				"|cffa335ee|Hitem:19357|h[Herald of Woe]|h|r",
				"Flamegor",
				{
					"Garbage",
				},
			},
			{
				"Circle of Applied Force",
				100,
				"|cffa335ee|Hitem:19432|h[Circle of Applied Force]|h|r",
				"Flamegor",
				{
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
			},
			{
				"Styleen's Impeding Scarab",
				325,
				"|cffa335ee|Hitem:19431|h[Styleen's Impeding Scarab]|h|r",
				"Flamegor",
				{
					"Tank",
				},
			},
			{
				"Pauldrons of Transcendence",
				150,
				"|cffa335ee|Hitem:16924|h[Pauldrons of Transcendence]|h|r",
				"Chromaggus",
				{
					"Priest (Heal)",
				},
			},
			{
				"Netherwind Mantle",
				80,
				"|cffa335ee|Hitem:16917|h[Netherwind Mantle]|h|r",
				"Chromaggus",
				{
					"Mage",
				},
			},
			{
				"Nemesis Spaulders",
				125,
				"|cffa335ee|Hitem:16932|h[Nemesis Spaulders]|h|r",
				"Chromaggus",
				{
					"Warlock",
				},
			},
			{
				"Bloodfang Spaulders",
				50,
				"|cffa335ee|Hitem:16832|h[Bloodfang Spaulders]|h|r",
				"Chromaggus",
				{
					"Slicey Rogue",
				},
			},
			{
				"Stormrage Pauldrons",
				0,
				"|cffa335ee|Hitem:16902|h[Stormrage Pauldrons]|h|r",
				"Chromaggus",
				{
					"Druid (Heal)",
				},
			},
			{
				"Dragonstalker's Spaulders",
				200,
				"|cffa335ee|Hitem:16937|h[Dragonstalker's Spaulders]|h|r",
				"Chromaggus",
				{
					"Hunter",
				},
			},
			{
				"Judgement Spaulders",
				0,
				"|cffa335ee|Hitem:16953|h[Judgement Spaulders]|h|r",
				"Chromaggus",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Pauldrons of Wrath",
				200,
				"|cffa335ee|Hitem:16961|h[Pauldrons of Wrath]|h|r",
				"Chromaggus",
				{
					"Tank",
				},
			},
			{
				"Taut Dragonhide Shoulderpads",
				100,
				"|cffa335ee|Hitem:19389|h[Taut Dragonhide Shoulderpads]|h|r",
				"Chromaggus",
				{
					"KAT4FITE",
				},
			},
			{
				"Elementium Threaded Cloak",
				150,
				"|cffa335ee|Hitem:19386|h[Elementium Threaded Cloak]|h|r",
				"Chromaggus",
				{
					"KAT4FITE",
					"Tank",
				},
			},
			{
				"Taut Dragonhide Gloves",
				80,
				"|cffa335ee|Hitem:19390|h[Taut Dragonhide Gloves]|h|r",
				"Chromaggus",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Angelista's Grasp",
				0,
				"|cffa335ee|Hitem:19388|h[Angelista's Grasp]|h|r",
				"Chromaggus",
				{
					"Garbage",
				},
			},
			{
				"Girdle of the Fallen Crusader",
				0,
				"|cffa335ee|Hitem:19392|h[Girdle of the Fallen Crusader]|h|r",
				"Chromaggus",
				{
					"Garbage",
				},
			},
			{
				"Empowered Leggings",
				200,
				"|cffa335ee|Hitem:19385|h[Empowered Leggings]|h|r",
				"Chromaggus",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Shimmering Geta",
				100,
				"|cffa335ee|Hitem:19391|h[Shimmering Geta]|h|r",
				"Chromaggus",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Chromatic Boots",
				250,
				"|cffa335ee|Hitem:19387|h[Chromatic Boots]|h|r",
				"Chromaggus",
				{
					"Metal Rogue",
				},
			},
			{
				"Ashjre'thul, Crossbow of Smiting",
				400,
				"|cffa335ee|Hitem:19361|h[Ashjre'thul, Crossbow of Smiting]|h|r",
				"Chromaggus",
				{
					"Hunter",
				},
			},
			{
				"Elementium Reinforced Bulwark",
				250,
				"|cffa335ee|Hitem:19349|h[Elementium Reinforced Bulwark]|h|r",
				"Chromaggus",
				{
					"Tank",
				},
			},
			{
				"Claw of Chromaggus",
				300,
				"|cffa335ee|Hitem:19347|h[Claw of Chromaggus]|h|r",
				"Chromaggus",
				{
					"Mage",
					"Warlock",
				},
			},
			{
				"Chromatically Tempered Sword",
				400,
				"|cffa335ee|Hitem:19352|h[Chromatically Tempered Sword]|h|r",
				"Chromaggus",
				{
					"Metal Rogue",
					"Slicey Rogue",
				},
			},
			{
				"Robes of Transcendence",
				200,
				"|cffa335ee|Hitem:16923|h[Robes of Transcendence]|h|r",
				"Nefarian",
				{
					"Priest (Heal)",
				},
			},
			{
				"Netherwind Robes",
				0,
				"|cffa335ee|Hitem:16916|h[Netherwind Robes]|h|r",
				"Nefarian",
				{
					"Mage",
				},
			},
			{
				"Nemesis Robes",
				0,
				"|cffa335ee|Hitem:16931|h[Nemesis Robes]|h|r",
				"Nefarian",
				{
					"Warlock",
				},
			},
			{
				"Bloodfang Chestpiece",
				200,
				"|cffa335ee|Hitem:16905|h[Bloodfang Chestpiece]|h|r",
				"Nefarian",
				{
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Stormrage Chestguard",
				0,
				"|cffa335ee|Hitem:16897|h[Stormrage Chestguard]|h|r",
				"Nefarian",
				{
					"Druid (Heal)",
				},
			},
			{
				"Dragonstalker's Breastplate",
				200,
				"|cffa335ee|Hitem:16942|h[Dragonstalker's Breastplate]|h|r",
				"Nefarian",
				{
					"Hunter",
				},
			},
			{
				"Judgement Breastplate",
				0,
				"|cffa335ee|Hitem:16958|h[Judgement Breastplate]|h|r",
				"Nefarian",
				{
					"Paladin (Holy)",
				},
			},
			{
				"Breastplate of Wrath",
				200,
				"|cffa335ee|Hitem:16966|h[Breastplate of Wrath]|h|r",
				"Nefarian",
				{
					"Tank",
				},
			},
			{
				"Head of Nefarian",
				150,
				"|cffa335ee|Hitem:19003|h[Head of Nefarian]|h|r",
				"Nefarian",
				{
					"Hunter",
					"KAT4FITE",
					"Metal Rogue",
					"Slicey Rogue",
					"Stabby Rogue",
					"Tank",
				},
				"Casters with a BWL 1h also eligible",
			},
			{
				"Lok'amir il Romathis",
				400,
				"|cffa335ee|Hitem:19360|h[Lok'amir il Romathis]|h|r",
				"Nefarian",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Crul'shorukh, Edge of Chaos",
				400,
				"|cffa335ee|Hitem:19363|h[Crul'shorukh, Edge of Chaos]|h|r",
				"Nefarian",
				{
					"Metal Rogue",
				},
			},
			{
				"Ashkandi, Greatsword of the Brotherhood",
				0,
				"|cffa335ee|Hitem:19364|h[Ashkandi, Greatsword of the Brotherhood]|h|r",
				"Nefarian",
				{
					"Garbage",
				},
			},
			{
				"Staff of the Shadow Flame",
				450,
				"|cffa335ee|Hitem:19356|h[Staff of the Shadow Flame]|h|r",
				"Nefarian",
				{
					"Mage",
					"Warlock",
				},
			},
			{
				"Mish'undare, Circlet of the Mind Flayer",
				300,
				"|cffa335ee|Hitem:19375|h[Mish'undare, Circlet of the Mind Flayer]|h|r",
				"Nefarian",
				{
					"Mage",
					"Paladin (Holy)",
					"Warlock",
				},
			},
			{
				"Prestor's Talisman of Connivery",
				200,
				"|cffa335ee|Hitem:19377|h[Prestor's Talisman of Connivery]|h|r",
				"Nefarian",
				{
					"Hunter",
					"KAT4FITE",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Cloak of the Brood Lord",
				0,
				"|cffa335ee|Hitem:19378|h[Cloak of the Brood Lord]|h|r",
				"Nefarian",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Therazane's Link",
				0,
				"|cffa335ee|Hitem:19380|h[Therazane's Link]|h|r",
				"Nefarian",
				{
					"Garbage",
				},
			},
			{
				"Boots of the Shadow Flame",
				200,
				"|cffa335ee|Hitem:19381|h[Boots of the Shadow Flame]|h|r",
				"Nefarian",
				{
					"KAT4FITE",
					"Stabby Rogue",
				},
			},
			{
				"Archimtiros' Ring of Reckoning",
				125,
				"|cffa335ee|Hitem:19376|h[Archimtiros' Ring of Reckoning]|h|r",
				"Nefarian",
				{
					"KAT4FITE",
					"Tank",
				},
			},
			{
				"Pure Elementium Band",
				200,
				"|cffa335ee|Hitem:19382|h[Pure Elementium Band]|h|r",
				"Nefarian",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Neltharion's Tear",
				400,
				"|cffa335ee|Hitem:19379|h[Neltharion's Tear]|h|r",
				"Nefarian",
				{
					"Mage",
					"Warlock",
				},
				"Shadow Priest Prio Unlocks after 4 drops",
			},
			{
				"Cloak of Draconic Might",
				150,
				"|cffa335ee|Hitem:19436|h[Cloak of Draconic Might]|h|r",
				"Trash",
				{
					"KAT4FITE",
					"Metal Rogue",
				},
			},
			{
				"Interlaced Shadow Jerkin",
				0,
				"|cffa335ee|Hitem:19439|h[Interlaced Shadow Jerkin]|h|r",
				"Trash",
				{
					"Progression",
				},
			},
			{
				"Boots of Pure Thought",
				200,
				"|cffa335ee|Hitem:19437|h[Boots of Pure Thought]|h|r",
				"Trash",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Ringo's Blizzard Boots",
				250,
				"|cffa335ee|Hitem:19438|h[Ringo's Blizzard Boots]|h|r",
				"Trash",
				{
					"Mage",
				},
			},
			{
				"Band of Dark Dominion",
				200,
				"|cffa335ee|Hitem:19434|h[Band of Dark Dominion]|h|r",
				"Trash",
				{
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Essence Gatherer",
				100,
				"|cffa335ee|Hitem:19435|h[Essence Gatherer]|h|r",
				"Trash",
				{
					"Priest (Heal)",
				},
			},
			{
				"Doom's Edge",
				100,
				"|cffa335ee|Hitem:19362|h[Doom's Edge]|h|r",
				"Trash",
				{
					"Hunter",
					"Metal Rogue",
				},
			},
			{
				"Draconic Avenger",
				0,
				"|cffa335ee|Hitem:19354|h[Draconic Avenger]|h|r",
				"Trash",
				{
					"Garbage",
				},
			},
			{
				"Draconic Maul",
				300,
				"|cffa335ee|Hitem:19358|h[Draconic Maul]|h|r",
				"Trash",
				{
					"KAT4FITE",
				},
			},
			{
				"Green Dragonskin Cloak",
				0,
				"|cffa335ee|Hitem:20579|h[Green Dragonskin Cloak]|h|r",
				"Green Dragons (Shared)",
				{
					"Progression",
				},
			},
			{
				"Dragonspur Wraps",
				0,
				"|cffa335ee|Hitem:20615|h[Dragonspur Wraps]|h|r",
				"Green Dragons (Shared)",
				{
					"Progression",
				},
			},
			{
				"Dragonbone Wristguards",
				0,
				"|cffa335ee|Hitem:20616|h[Dragonbone Wristguards]|h|r",
				"Green Dragons (Shared)",
				{
					"Garbage",
				},
			},
			{
				"Gloves of Delusional Power",
				0,
				"|cffa335ee|Hitem:20618|h[Gloves of Delusional Power]|h|r",
				"Green Dragons (Shared)",
				{
					"Garbage",
				},
			},
			{
				"Ancient Corroded Leggings",
				0,
				"|cffa335ee|Hitem:20617|h[Ancient Corroded Leggings]|h|r",
				"Green Dragons (Shared)",
				{
					"Garbage",
				},
			},
			{
				"Acid Inscribed Greaves",
				0,
				"|cffa335ee|Hitem:20619|h[Acid Inscribed Greaves]|h|r",
				"Green Dragons (Shared)",
				{
					"Progression",
				},
			},
			{
				"Trance Stone",
				80,
				"|cffa335ee|Hitem:20582|h[Trance Stone]|h|r",
				"Green Dragons (Shared)",
				{
					"Druid (Heal)",
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Hammer of Bestial Fury",
				250,
				"|cffa335ee|Hitem:20580|h[Hammer of Bestial Fury]|h|r",
				"Green Dragons (Shared)",
				{
					"KAT4FITE",
				},
			},
			{
				"Staff of Rampant Growth",
				0,
				"|cffa335ee|Hitem:20581|h[Staff of Rampant Growth]|h|r",
				"Green Dragons (Shared)",
				{
					"Progression",
				},
			},
			{
				"Malfurion's Signet Ring",
				0,
				"|cffa335ee|Hitem:20600|h[Malfurion's Signet Ring]|h|r",
				"Green Dragons (Shared)",
				{
					"Progression",
				},
			},
			{
				"Deviate Growth Cap",
				300,
				"|cffa335ee|Hitem:20628|h[Deviate Growth Cap]|h|r",
				"Lethon",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Black Bark Wristbands",
				100,
				"|cffa335ee|Hitem:20626|h[Black Bark Wristbands]|h|r",
				"Lethon",
				{
					"Mage",
					"Priest (Shadow)",
					"Warlock",
				},
			},
			{
				"Gauntlets of the Shining Light",
				0,
				"|cffa335ee|Hitem:20630|h[Gauntlets of the Shining Light]|h|r",
				"Lethon",
				{
					"Garbage",
				},
			},
			{
				"Belt of the Dark Bog",
				0,
				"|cffa335ee|Hitem:20625|h[Belt of the Dark Bog]|h|r",
				"Lethon",
				{
					"Progression",
				},
			},
			{
				"Dark Heart Pants",
				150,
				"|cffa335ee|Hitem:20627|h[Dark Heart Pants]|h|r",
				"Lethon",
				{
					"KAT4FITE",
					"Metal Rogue",
				},
			},
			{
				"Malignant Footguards",
				0,
				"|cffa335ee|Hitem:20629|h[Malignant Footguards]|h|r",
				"Lethon",
				{
					"Garbage",
				},
			},
			{
				"Circlet of Restless Dreams",
				150,
				"|cffa335ee|Hitem:20623|h[Circlet of Restless Dreams]|h|r",
				"Emeriss",
				{
					"Stabby Rogue",
				},
			},
			{
				"Dragonheart Necklace",
				0,
				"|cffa335ee|Hitem:20622|h[Dragonheart Necklace]|h|r",
				"Emeriss",
				{
					"Garbage",
				},
			},
			{
				"Ring of the Unliving",
				80,
				"|cffa335ee|Hitem:20624|h[Ring of the Unliving]|h|r",
				"Emeriss",
				{
					"Hunter",
					"KAT4FITE",
					"Slicey Rogue",
					"Stabby Rogue",
				},
			},
			{
				"Boots of the Endless Moor",
				0,
				"|cffa335ee|Hitem:20621|h[Boots of the Endless Moor]|h|r",
				"Emeriss",
				{
					"Progression",
				},
			},
			{
				"Polished Ironwood Crossbow",
				0,
				"|cffa335ee|Hitem:20599|h[Polished Ironwood Crossbow]|h|r",
				"Emeriss",
				{
					"Progression",
				},
			},
			{
				"Unnatural Leather Spaulders",
				0,
				"|cffa335ee|Hitem:20633|h[Unnatural Leather Spaulders]|h|r",
				"Taerar",
				{
					"Progression",
				},
			},
			{
				"Mendicant's Slippers",
				80,
				"|cffa335ee|Hitem:20631|h[Mendicant's Slippers]|h|r",
				"Taerar",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Boots of Fright",
				80,
				"|cffa335ee|Hitem:20634|h[Boots of Fright]|h|r",
				"Taerar",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
				},
			},
			{
				"Mindtear Band",
				250,
				"|cffa335ee|Hitem:20632|h[Mindtear Band]|h|r",
				"Taerar",
				{
					"Mage",
					"Warlock",
				},
			},
			{
				"Nightmare Blade",
				150,
				"|cffa335ee|Hitem:20577|h[Nightmare Blade]|h|r",
				"Taerar",
				{
					"Metal Rogue",
					"Slicey Rogue",
					"Tank",
				},
			},
			{
				"Acid Inscribed Pauldrons",
				0,
				"|cffa335ee|Hitem:20637|h[Acid Inscribed Pauldrons]|h|r",
				"Ysondre",
				{
					"Progression",
				},
			},
			{
				"Jade Inlaid Vestments",
				0,
				"|cffa335ee|Hitem:20635|h[Jade Inlaid Vestments]|h|r",
				"Ysondre",
				{
					"Garbage",
				},
			},
			{
				"Leggings of the Demented Mind",
				0,
				"|cffa335ee|Hitem:20638|h[Leggings of the Demented Mind]|h|r",
				"Ysondre",
				{
					"Garbage",
				},
			},
			{
				"Strangely Glyphed Legplates",
				0,
				"|cffa335ee|Hitem:20639|h[Strangely Glyphed Legplates]|h|r",
				"Ysondre",
				{
					"Garbage",
				},
			},
			{
				"Hibernation Crystal",
				150,
				"|cffa335ee|Hitem:20636|h[Hibernation Crystal]|h|r",
				"Ysondre",
				{
					"Druid (Heal)",
					"Paladin (Holy)",
					"Priest (Heal)",
				},
			},
			{
				"Emerald Dragonfang",
				100,
				"|cffa335ee|Hitem:20578|h[Emerald Dragonfang]|h|r",
				"Ysondre",
				{
					"Stabby Rogue",
				},
			},
		},
		[ABGP.PhasesAll.p5] = {
			{
				"Barrage Shoulders",
				0,
				"|cffa335ee|Hitem:21699|h[Barrage Shoulders]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Breastplate of Annihilation",
				0,
				"|cffa335ee|Hitem:21814|h[Breastplate of Annihilation]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Beetle Scaled Wristguards",
				0,
				"|cffa335ee|Hitem:21708|h[Beetle Scaled Wristguards]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Leggings of Immersion",
				0,
				"|cffa335ee|Hitem:21698|h[Leggings of Immersion]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Boots of the Fallen Prophet",
				0,
				"|cffa335ee|Hitem:21705|h[Boots of the Fallen Prophet]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Boots of the Redeemed Prophecy",
				0,
				"|cffa335ee|Hitem:21704|h[Boots of the Redeemed Prophecy]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Boots of the Unwavering Will",
				0,
				"|cffa335ee|Hitem:21706|h[Boots of the Unwavering Will]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Amulet of Foul Warding",
				0,
				"|cffa335ee|Hitem:21702|h[Amulet of Foul Warding]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Pendant of the Qiraji Guardian",
				0,
				"|cffa335ee|Hitem:21700|h[Pendant of the Qiraji Guardian]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Cloak of Concentrated Hatred",
				0,
				"|cffa335ee|Hitem:21701|h[Cloak of Concentrated Hatred]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Ring of Swarming Thought",
				0,
				"|cffa335ee|Hitem:21707|h[Ring of Swarming Thought]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Hammer of Ji'zhi",
				0,
				"|cffa335ee|Hitem:21703|h[Hammer of Ji'zhi]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Staff of the Qiraji Prophets",
				0,
				"|cffa335ee|Hitem:21128|h[Staff of the Qiraji Prophets]|h|r",
				"The Prophet Skeram",
				{
				},
			},
			{
				"Guise of the Devourer",
				0,
				"|cffa335ee|Hitem:21693|h[Guise of the Devourer]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Ternary Mantle",
				0,
				"|cffa335ee|Hitem:21694|h[Ternary Mantle]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Cape of the Trinity",
				0,
				"|cffa335ee|Hitem:21697|h[Cape of the Trinity]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Robes of the Triumvirate",
				0,
				"|cffa335ee|Hitem:21696|h[Robes of the Triumvirate]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Triad Girdle",
				0,
				"|cffa335ee|Hitem:21692|h[Triad Girdle]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Angelista's Touch",
				0,
				"|cffa335ee|Hitem:21695|h[Angelista's Touch]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Vest of Swift Execution",
				0,
				"|cffa335ee|Hitem:21680|h[Vest of Swift Execution]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Ring of the Devoured",
				0,
				"|cffa335ee|Hitem:21681|h[Ring of the Devoured]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Petrified Scarab",
				0,
				"|cffa335ee|Hitem:21685|h[Petrified Scarab]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Wand of Qiraji Nobility",
				0,
				"|cffa335ee|Hitem:21603|h[Wand of Qiraji Nobility]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Angelista's Charm",
				0,
				"|cffa335ee|Hitem:21690|h[Angelista's Charm]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Gloves of Ebru",
				0,
				"|cffa335ee|Hitem:21689|h[Gloves of Ebru]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Ooze-ridden Gauntlets",
				0,
				"|cffa335ee|Hitem:21691|h[Ooze-ridden Gauntlets]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Boots of the Fallen Hero",
				0,
				"|cffa335ee|Hitem:21688|h[Boots of the Fallen Hero]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Mantle of Phrenic Power",
				0,
				"|cffa335ee|Hitem:21686|h[Mantle of Phrenic Power]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Mantle of the Desert's Fury",
				0,
				"|cffa335ee|Hitem:21684|h[Mantle of the Desert's Fury]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Mantle of the Desert Crusade",
				0,
				"|cffa335ee|Hitem:21683|h[Mantle of the Desert Crusade]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Bile-Covered Gauntlets",
				0,
				"|cffa335ee|Hitem:21682|h[Bile-Covered Gauntlets]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Ukko's Ring of Darkness",
				0,
				"|cffa335ee|Hitem:21687|h[Ukko's Ring of Darkness]|h|r",
				"Bug Trio",
				{
				},
			},
			{
				"Creeping Vine Helm",
				0,
				"|cffa335ee|Hitem:21669|h[Creeping Vine Helm]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Necklace of Purity",
				0,
				"|cffa335ee|Hitem:21678|h[Necklace of Purity]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Robes of the Battleguard",
				0,
				"|cffa335ee|Hitem:21671|h[Robes of the Battleguard]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Gloves of Enforcement",
				0,
				"|cffa335ee|Hitem:21672|h[Gloves of Enforcement]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Gauntlets of Steadfast Determination",
				0,
				"|cffa335ee|Hitem:21674|h[Gauntlets of Steadfast Determination]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Thick Qirajihide Belt",
				0,
				"|cffa335ee|Hitem:21675|h[Thick Qirajihide Belt]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Leggings of the Festering Swarm",
				0,
				"|cffa335ee|Hitem:21676|h[Leggings of the Festering Swarm]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Scaled Leggings of Qiraji Fury",
				0,
				"|cffa335ee|Hitem:21668|h[Scaled Leggings of Qiraji Fury]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Legplates of Blazing Light",
				0,
				"|cffa335ee|Hitem:21667|h[Legplates of Blazing Light]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Recomposed Boots",
				0,
				"|cffa335ee|Hitem:21648|h[Recomposed Boots]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Badge of the Swarmguard",
				0,
				"|cffa335ee|Hitem:21670|h[Badge of the Swarmguard]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Sartura's Might",
				0,
				"|cffa335ee|Hitem:21666|h[Sartura's Might]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Silithid Claw",
				0,
				"|cffa335ee|Hitem:21673|h[Silithid Claw]|h|r",
				"Battleguard Sartura",
				{
				},
			},
			{
				"Mantle of Wicked Revenge",
				0,
				"|cffa335ee|Hitem:21665|h[Mantle of Wicked Revenge]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Pauldrons of the Unrelenting",
				0,
				"|cffa335ee|Hitem:21639|h[Pauldrons of the Unrelenting]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Cloak of Untold Secrets",
				0,
				"|cffa335ee|Hitem:21627|h[Cloak of Untold Secrets]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Robes of the Guardian Saint",
				0,
				"|cffa335ee|Hitem:21663|h[Robes of the Guardian Saint]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Silithid Carapace Chestguard",
				0,
				"|cffa335ee|Hitem:21652|h[Silithid Carapace Chestguard]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Scaled Sand Reaver Leggings",
				0,
				"|cffa335ee|Hitem:21651|h[Scaled Sand Reaver Leggings]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Hive Tunneler's Boots",
				0,
				"|cffa335ee|Hitem:21645|h[Hive Tunneler's Boots]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Ancient Qiraji Ripper",
				0,
				"|cffa335ee|Hitem:21650|h[Ancient Qiraji Ripper]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Barb of the Sand Reaver",
				0,
				"|cffa335ee|Hitem:21635|h[Barb of the Sand Reaver]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Barbed Choker",
				0,
				"|cffa335ee|Hitem:21664|h[Barbed Choker]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Fetish of the Sand Reaver",
				0,
				"|cffa335ee|Hitem:21647|h[Fetish of the Sand Reaver]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Libram of Grace",
				0,
				"|cffa335ee|Hitem:22402|h[Libram of Grace]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Totem of Life",
				0,
				"|cffa335ee|Hitem:22396|h[Totem of Life]|h|r",
				"Fankriss the Unyielding",
				{
				},
			},
			{
				"Gauntlets of Kalimdor",
				0,
				"|cffa335ee|Hitem:21624|h[Gauntlets of Kalimdor]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Gauntlets of the Righteous Champion",
				0,
				"|cffa335ee|Hitem:21623|h[Gauntlets of the Righteous Champion]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Slime-coated Leggings",
				0,
				"|cffa335ee|Hitem:21626|h[Slime-coated Leggings]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Sharpened Silithid Femur",
				0,
				"|cffa335ee|Hitem:21622|h[Sharpened Silithid Femur]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Ring of the Qiraji Fury",
				0,
				"|cffa335ee|Hitem:21677|h[Ring of the Qiraji Fury]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Scarab Brooch",
				0,
				"|cffa335ee|Hitem:21625|h[Scarab Brooch]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Idol of Health",
				0,
				"|cffa335ee|Hitem:22399|h[Idol of Health]|h|r",
				"Viscidus",
				{
				},
			},
			{
				"Qiraji Bindings of Command",
				0,
				"|cffa335ee|Hitem:20928|h[Qiraji Bindings of Command]|h|r",
				"Viscidus, Princess Huhuran",
				{
				},
			},
			{
				"Qiraji Bindings of Dominance",
				0,
				"|cffa335ee|Hitem:20932|h[Qiraji Bindings of Dominance]|h|r",
				"Viscidus, Princess Huhuran",
				{
				},
			},
			{
				"Cloak of the Golden Hive",
				0,
				"|cffa335ee|Hitem:21621|h[Cloak of the Golden Hive]|h|r",
				"Princess Huhuran",
				{
				},
			},
			{
				"Hive Defiler Wristguards",
				0,
				"|cffa335ee|Hitem:21618|h[Hive Defiler Wristguards]|h|r",
				"Princess Huhuran",
				{
				},
			},
			{
				"Gloves of the Messiah",
				0,
				"|cffa335ee|Hitem:21619|h[Gloves of the Messiah]|h|r",
				"Princess Huhuran",
				{
				},
			},
			{
				"Wasphide Gauntlets",
				0,
				"|cffa335ee|Hitem:21617|h[Wasphide Gauntlets]|h|r",
				"Princess Huhuran",
				{
				},
			},
			{
				"Ring of the Martyr",
				0,
				"|cffa335ee|Hitem:21620|h[Ring of the Martyr]|h|r",
				"Princess Huhuran",
				{
				},
			},
			{
				"Huhuran's Stinger",
				0,
				"|cffa335ee|Hitem:21616|h[Huhuran's Stinger]|h|r",
				"Princess Huhuran",
				{
				},
			},
			{
				"Vek'lor's Diadem",
				0,
				"|cffa335ee|Hitem:20930|h[Vek'lor's Diadem]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Qiraji Execution Bracers",
				0,
				"|cffa335ee|Hitem:21602|h[Qiraji Execution Bracers]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Vek'lor's Gloves of Devastation",
				0,
				"|cffa335ee|Hitem:21599|h[Vek'lor's Gloves of Devastation]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Royal Qiraji Belt",
				0,
				"|cffa335ee|Hitem:21598|h[Royal Qiraji Belt]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Boots of Epiphany",
				0,
				"|cffa335ee|Hitem:21600|h[Boots of Epiphany]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Ring of Emperor Vek'lor",
				0,
				"|cffa335ee|Hitem:21601|h[Ring of Emperor Vek'lor]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Royal Scepter of Vek'lor",
				0,
				"|cffa335ee|Hitem:21597|h[Royal Scepter of Vek'lor]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Vek'nilash's Circlet",
				0,
				"|cffa335ee|Hitem:20926|h[Vek'nilash's Circlet]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Amulet of Vek'nilash",
				0,
				"|cffa335ee|Hitem:21608|h[Amulet of Vek'nilash]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Bracelets of Royal Redemption",
				0,
				"|cffa335ee|Hitem:21604|h[Bracelets of Royal Redemption]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Gloves of the Hidden Temple",
				0,
				"|cffa335ee|Hitem:21605|h[Gloves of the Hidden Temple]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Regenerating Belt of Vek'nilash",
				0,
				"|cffa335ee|Hitem:21609|h[Regenerating Belt of Vek'nilash]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Grasp of the Fallen Emperor",
				0,
				"|cffa335ee|Hitem:21607|h[Grasp of the Fallen Emperor]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Belt of the Fallen Emperor",
				0,
				"|cffa335ee|Hitem:21606|h[Belt of the Fallen Emperor]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Kalimdor's Revenge",
				0,
				"|cffa335ee|Hitem:21679|h[Kalimdor's Revenge]|h|r",
				"Twin Emperors",
				{
				},
			},
			{
				"Don Rigoberto's Lost Hat",
				0,
				"|cffa335ee|Hitem:21615|h[Don Rigoberto's Lost Hat]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Burrower Bracers",
				0,
				"|cffa335ee|Hitem:21611|h[Burrower Bracers]|h|r",
				"Ouro",
				{
				},
			},
			{
				"The Burrower's Shell",
				0,
				"|cffa335ee|Hitem:23558|h[The Burrower's Shell]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Jom Gabbar",
				0,
				"|cffa335ee|Hitem:23570|h[Jom Gabbar]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Wormscale Blocker",
				0,
				"|cffa335ee|Hitem:21610|h[Wormscale Blocker]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Larvae of the Great Worm",
				0,
				"|cffa335ee|Hitem:23557|h[Larvae of the Great Worm]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Ouro's Intact Hide",
				0,
				"|cffa335ee|Hitem:20927|h[Ouro's Intact Hide]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Skin of the Great Sandworm",
				0,
				"|cffa335ee|Hitem:20931|h[Skin of the Great Sandworm]|h|r",
				"Ouro",
				{
				},
			},
			{
				"Mark of C'Thun",
				0,
				"|cffa335ee|Hitem:22732|h[Mark of C'Thun]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Cloak of Clarity",
				0,
				"|cffa335ee|Hitem:21583|h[Cloak of Clarity]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Cloak of the Devoured",
				0,
				"|cffa335ee|Hitem:22731|h[Cloak of the Devoured]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Eyestalk Waist Cord",
				0,
				"|cffa335ee|Hitem:22730|h[Eyestalk Waist Cord]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Grasp of the Old God",
				0,
				"|cffa335ee|Hitem:21582|h[Grasp of the Old God]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Belt of Never-ending Agony",
				0,
				"|cffa335ee|Hitem:21586|h[Belt of Never-ending Agony]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Dark Storm Gauntlets",
				0,
				"|cffa335ee|Hitem:21585|h[Dark Storm Gauntlets]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Gauntlets of Annihilation",
				0,
				"|cffa335ee|Hitem:21581|h[Gauntlets of Annihilation]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Ring of the Godslayer",
				0,
				"|cffa335ee|Hitem:21596|h[Ring of the Godslayer]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Vanquished Tentacle of C'Thun",
				0,
				"|cffa335ee|Hitem:21579|h[Vanquished Tentacle of C'Thun]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Scepter of the False Prophet",
				0,
				"|cffa335ee|Hitem:21839|h[Scepter of the False Prophet]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Death's Sting",
				0,
				"|cffa335ee|Hitem:21126|h[Death's Sting]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Dark Edge of Insanity",
				0,
				"|cffa335ee|Hitem:21134|h[Dark Edge of Insanity]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Carapace of the Old God",
				0,
				"|cffa335ee|Hitem:20929|h[Carapace of the Old God]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Husk of the Old God",
				0,
				"|cffa335ee|Hitem:20933|h[Husk of the Old God]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Eye of C'Thun",
				0,
				"|cffa335ee|Hitem:21221|h[Eye of C'Thun]|h|r",
				"C'Thun",
				{
				},
			},
			{
				"Garb of Royal Ascension",
				0,
				"|cffa335ee|Hitem:21838|h[Garb of Royal Ascension]|h|r",
				"Trash",
				{
				},
			},
			{
				"Gloves of the Immortal",
				0,
				"|cffa335ee|Hitem:21888|h[Gloves of the Immortal]|h|r",
				"Trash",
				{
				},
			},
			{
				"Gloves of the Redeemed Prophecy",
				0,
				"|cffa335ee|Hitem:21889|h[Gloves of the Redeemed Prophecy]|h|r",
				"Trash",
				{
				},
			},
			{
				"Neretzek, The Blood Drinker",
				0,
				"|cffa335ee|Hitem:21856|h[Neretzek, The Blood Drinker]|h|r",
				"Trash",
				{
				},
			},
			{
				"Anubisath Warhammer",
				0,
				"|cffa335ee|Hitem:21837|h[Anubisath Warhammer]|h|r",
				"Trash",
				{
				},
			},
			{
				"Ritssyn's Ring of Chaos",
				0,
				"|cffa335ee|Hitem:21836|h[Ritssyn's Ring of Chaos]|h|r",
				"Trash",
				{
				},
			},
			{
				"Shard of the Fallen Star",
				0,
				"|cffa335ee|Hitem:21891|h[Shard of the Fallen Star]|h|r",
				"Trash",
				{
				},
			},
			{
				"Imperial Qiraji Regalia",
				0,
				"|cffa335ee|Hitem:21237|h[Imperial Qiraji Regalia]|h|r",
				"Shared",
				{
				},
			},
			{
				"Imperial Qiraji Armaments",
				0,
				"|cffa335ee|Hitem:21232|h[Imperial Qiraji Armaments]|h|r",
				"Shared",
				{
				},
			},
		},
	},
	gpHistory = {
		timestamp = 1589673091, -- https://www.epochconverter.com/ or GetServerTime() ingame
		[ABGP.PhasesAll.p1] = {},
		[ABGP.PhasesAll.p3] = {},
		[ABGP.PhasesAll.p5] = {},
	},
};

function ABGP:CheckHardcodedData()
	-- _G.ABGP_DataTimestamp was previously a flat number, converted later to a table.
	if _G.ABGP_DataTimestamp == nil then
		_G.ABGP_DataTimestamp = { itemValues = 0, gpHistory = 0 };
	elseif type(_G.ABGP_DataTimestamp) == "number" then
		_G.ABGP_DataTimestamp = { itemValues = _G.ABGP_DataTimestamp, gpHistory = 0 };
	end

	for key, initialData in pairs(self.initialData) do
		local updateBaseline = false;
		if _G.ABGP_DataTimestamp[key] < initialData.timestamp then
			_G.ABGP_DataTimestamp[key] = initialData.timestamp;
			updateBaseline = true;
		end

		for phase in pairs(ABGP.PhasesAll) do
			_G.ABGP_Data[phase] = _G.ABGP_Data[phase] or {};
			_G.ABGP_Data[phase][key] = _G.ABGP_Data[phase][key] or {};
			if updateBaseline then
				_G.ABGP_Data[phase][key] = initialData[phase];
			end
		end
	end
end
