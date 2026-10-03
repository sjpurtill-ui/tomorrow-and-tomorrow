extends RefCounted
## Words no generated name may be (people_language.gd): real places, real
## peoples, real historical, sacred and legendary figures (docs: alternative
## history; real history is calibration only), and plain English words that
## would read as a word, not a name ("Mine", "Tone"). OFFENSIVE holds strings
## no name may contain anywhere. Lower case, separated by spaces or lines.

const PLACES:="""
aarhus aberdeen abidjan abudhabi abuja acapulco accra addis adelaide aden afghanistan africa agadir agra akkad aksum alaska albania aleppo alexandria
algeria algiers allahabad almaty alps amarna amazon america amman amritsar amsterdam anatolia andes andorra angkor angola ankara antalya antananarivo
antarctica antioch anuradhapura anyang aotearoa apia arabia ararat arctic arequipa argentina argos armenia ashgabat asia asmara assyria astana
asuncion aswan athens athina atlas auckland australia austria avalon axum ayodhya ayutthaya azerbaijan babylon babylonia bactria bagan baghdad bahamas
bahrain baku balkh bamako bamiyan bandung bangalore bangkok bangladesh bangor barbados barcelona basra batavia battambang batumi beijing beirut bejaia
belarus belfast belgium belgrade belize benares bengaluru benghazi benin beograd bergen berlin bern bhopal bhutan birka bishkek bogor bogota bolivia
bologna bombay bonampak bordeaux bosnia boston botswana brazil brazzaville bremen brest brisbane britannia brno brunei brussels bucharest bucuresti
budapest buenosaires bukhara bulawayo bulgaria burkina burma bursa burundi busan byblos byzantium cairo cajamarca calakmul calcutta calicut cambodia
camelot cameroon canaan canada canberra canton capetown caracas cardiff carnac carthage casablanca cebu chad changan changsha chapultepec chengdu
chennai chiangmai chicago chichen chile china chios cholula chongqing cilicia cluj coba cochabamba cochin coimbatore coimbra cologne colombia colombo
comoros conakry congo constantinople copan copenhagen cordoba corinth cork cotonou coyoacan crete croatia cuba cuernavaca cusco cuzco cyprus czechia
dacia daegu daejeon dakar dakota dalian damascus danang danube darwin datong davao debrecen delft delhi delphi denmark derry dhaka djenne djibouti
dodoma doha dominica douala dubai dublin dundee dunhuang durban dushanbe ecbatana ecuador edinburgh edo egypt ephesus eritrea espoo estonia eswatini
ethiopia etruria euphrates europe everest fes fez fiji finland firenze florence france freetown fukuoka fuzhou gabon gaborone galilee galway gambia
ganges gao gaul gdansk geneva genoa genova georgia germany ghana ghardaia giza glasgow goa gondar goteborg granada greece grenada groningen guangzhou
guatemala guinea guiyang guyana gwangju gyeongju haarlem haifa haiti hakodate hamadan hamburg hampi hangzhou hanoi harar harare harbin havana hawaii
hebron hedeby hefei helsinki herat hilo himalaya hiroshima hispania hobart hohhot holland honduras hongkong honolulu huancayo hue hungary hyderabad
iasi ibadan iberia iceland idaho igloolik illyria iloilo ilulissat imlil incheon india indonesia indore indus iowa iqaluit iran iraq ireland isfahan
islamabad israel istanbul italy ithaca izmir jaffa jaipur jakarta jamaica japan jeddah jeonju jericho jerusalem jinan jodhpur johannesburg jordan
judah judea kabul kaesong kagoshima kaifeng kairouan kakadu kamakura kampala kanazawa kanchipuram kandahar kandy kangerlussuaq kano kanpur kaohsiung
karachi karnak kashgar kathmandu kauai kavala kawasaki kazakhstan kazan kenya kerman khartoum khiva kiev kigali kilimanjaro kilkenny kilwa kinshasa
kiribati knossos kobe kochi kolkata koln kona konya korea kos kosovo kotzebue kozhikode krakow kriti kualalumpur kumamoto kumasi kunming kuopio
kurdistan kush kutaisi kuwait kyiv kyoto kyrgyzstan lagos lahore lahti lalibela lanai lanzhou laos lapaz larissa latvia lebanon leiden leningrad
lesotho lesvos lhasa liberia libreville libya liechtenstein lima limerick lisboa lisbon lithuania ljubljana lome london luanda luangprabang lucknow
lund luoyang lusaka luxembourg luxor lviv lydia lyon macau macedonia machupicchu madagascar madras madrid madurai makassar makkah malacca malang
malawi malaysia maldives male mali malmo malta manama mandalay manila maputo marrakesh marseille maseru mashhad mathura matsuyama maui mauritania
mauritius mayapan mazatlan mbabane mecca medan media medina melaka melbourne memphis merv mesopotamia mexico michigan micronesia milan milano
milwaukee minsk mississippi missouri mitla mogadishu moldova molokai mombasa monaco mongolia monrovia montealban montenegro montevideo montreal
morocco moscow moskva mosul mozambique mtskheta multan mumbai munchen munich muscat myanmar mycenae mysore mysuru nagasaki nagoya nagpur nairobi
namibia nanchang nanjing nanking nanning nantes naples napoli nara narva nauru naxos nepal netherlands newyork niamey nicaragua nice niger nigeria
niigata nikko nile norway novgorod nubia nukualofa numidia nunavut nuuk oahu oaxaca oceania odense odesa ohio okayama okinawa ollantaytambo olympia
olympus oman omsk oran oruro osaka oslo ottawa ouagadougou ouarzazate oulu pagan pakistan palau palenque palermo palestine panama papua paraguay paris
parnu paros parramatta parthia pasargadae pataliputra patna patra pecs peking penang penzance pergamon persepolis persia perth peru peshawar petra
petrograd philippines phnompenh phoenicia phrygia phuket pisa pisac poland popocatepetl pori porto portugal potosi poznan prague praha prayag pretoria
pskov puebla pune puno punt pusan pyongyang qaanaaq qatar qingdao quebec quimper quito qusqu rabat rangoon rapanui rennes rhine rhodes riga riyadh
roma romania rome roskilde rotorua rotterdam russia rwanda ryazan sacsayhuaman sahara sahel saigon samaria samarkand samoa samos sanaa santiago
sapporo sarajevo saskatoon scythia seine semarang sendai senegal seoul serbia sevilla seville seychelles shanghai shenyang shenzhen shijiazhuang
shiraz shizuoka siberia sidon siemreap siena sinai singapore skopje slovakia slovenia smolensk smyrna sofia sogdia somalia soweto spain sparta
stalingrad stavanger stockholm sucre sudan sukhothai sumer surabaya surat suriname susa suva suwon suzdal suzhou swansea sweden switzerland sydney
syria szeged tabriz tahiti taipei taiwan taiyuan tajikistan takamatsu tallinn tamanrasset tampere tangier tanzania tara taroudant tartu tashkent taupo
tauranga taxila tbilisi tehran tenerife tenochtitlan teotihuacan tepoztlan texas texcoco thailand thames thanjavur thebes thessaloniki thimphu thrace
tianjin tiber tibet tigris tikal timbuktu tinghir tintagel tiwanaku tiznit tlatelolco tlaxcala togo tokyo toledo tollan tomsk tonga toowoomba torino
toronto toulouse trinidad tripoli troia trondheim troy truro tula tulum tunis tunisia turin turkey turkmenistan turku tuvalu tver tyre udaipur uganda
ujjain ukraine ulsan uluru uppsala uruguay urumqi utah utqiagvik utrecht uxmal uzbekistan valencia valparaiso vannes vantaa vanuatu varanasi venezia
venezuela venice veracruz verona vienna vientiane vietnam vilnius visby vladimir volga volgograd volos waikiki warsaw warszawa wellington wien
windhoek winnipeg wollongong wuhan xiamen xian xining xochimilco yangon yangtze yaounde yaxchilan yazd yemen yerevan yogyakarta yokohama yukon zagreb
zambezi zambia zanzibar zhengzhou zimbabwe zurich
"""
const PROVINCES:="""
shanxi shaanxi hunan hubei henan hebei yunnan sichuan guangdong guangxi fujian jiangsu zhejiang anhui jiangxi shandong gansu qinghai hainan xinjiang ningxia liaoning jilin heilongjiang guizhou
gyeonggi gangwon chungcheong jeolla gyeongsang jeju hokkaido honshu kyushu shikoku aomori iwate miyagi akita yamagata fukushima ibaraki tochigi gunma saitama chiba kanagawa toyama ishikawa fukui yamanashi nagano gifu aichi mie shiga hyogo wakayama tottori shimane yamaguchi tokushima kagawa ehime saga oita miyazaki
bihar kerala assam punjab gujarat rajasthan odisha orissa bengal sikkim manipur tripura mizoram nagaland haryana jharkhand andhra telangana karnataka maharashtra kashmir ladakh sindh balochistan
bavaria saxony prussia silesia bohemia moravia galicia castile aragon navarre catalonia andalusia tuscany lombardy sicily sardinia corsica provence normandy brittany burgundy flanders wallonia frisia jutland scania lapland karelia livonia courland
kakheti imereti svaneti guria adjara abkhazia kartli samegrelo
yucatan chiapas sonora sinaloa jalisco michoacan guerrero tabasco campeche quintanaroo
"""
const PEOPLES:="""
achaean afar ainu akan aleut algonquin amazigh amhara anangu angle angles anishinaabe apache arab arabs aramaic armenian arrernte asante ashanti
assyrian avar aymara aztec aztecs baganda bakongo baloch bambara bashkir bengali berber bretons briton bugis bulgar buryat celt celts chaldean
cherokee cheyenne chleuh comanche cree croat czech dakota dene dine dinka dorian edo eora estonian etruscan ewe fijian finn finns fon frank franks
fula fulani gadigal gael gaels ganda georgian goth goths greek greeks guarani gujarati hakka han hausa hawaiian hebrew hellene hellenes hindi hopi
huastec hun huns igbo ijaw imazighen inca incas inuit inuk inupiat ionian irish iroquois israelite japanese javanese jew jews kabyle kalmyk kannada
karelian kartuli kartveli kazakh khalkha khazar khmer kiche kikuyu kinh kongo koori korean kurd kurds kyrgyz lakota lao latin lombard luba lunda luo
maasai magyar malagasy malay malayalam manchu mande mandinka maori mapuche marathi masai maya mayan mexica mixtec moana mohawk mon mongol mongols
murri navaho navajo ndebele noongar norse nubian nuer nupe oirat ojibwa ojibwe olmec oromo parthian pashtun persian phoenician pitjantjatjara polish
pueblo punjabi quechua quiche riffian roman romans rus russian saami sakha sami samoan saxon saxons scots serb shona shoshone sinhala sioux slav slavs
slovak somali sotho sundanese swahili tagalog tahitian tajik tamil tarascan tatar telugu thai tibetan tigray tigrinya tiv toltec tongan totonac tswana
tuareg turk turkmen turks uyghur uzbek vandal viet viking vikings visayan visigoth warlpiri welsh wiradjuri wolof xhosa yakut yamato yolngu yoruba
yupik zapotec zulu zuni
"""
const FIGURES:="""
abraham achilles adam agamemnon agni ahmad ahuizotl aisha ajax akbar akechi akhenaten alexander ali allah amaru amaterasu amon amun anu anubis
aphrodite apollo ares ariadne aristotle arjun arjuna artaxerxes artemis arthur ashikaga ashoka ashurbanipal askia atahualpa aten athena athene attila
augustus aurangzeb axayacatl babur baldur bastet batu baybars beowulf borte brahma buddha caesar caligula cambyses canute catherine cetshwayo chaak
chandragupta chinggis christ cicero cleopatra cnut coatlicue confucius cuauhtemoc cyrus darius david demeter dihya dionysus draco durga electra enki
enkidu enlil eve ezana fatima freya freyja frigg fujiwara ganesh ganesha gautama genghis gilgamesh gitchi guinevere gwanggaeto hades hadrian haile
hamilcar hammurabi hannibal hanuman harald hasan hathor hatshepsut hector heimdall helen hephaestus hera herakles hercules hermes hideyoshi hitler
hojo homer horus huangdi huascar huaynacapac huitzilopochtli humayun hussein ieyasu igor imhotep inanna indra inti isaac ishtar isis itzamna itzcoatl
ivan ixchel izanagi izanami jacob jebe jehovah jesus jimmu joseph juba jughashvili jugurtha jumong kahina kali kamehameha kangxi khadija khufu knut
kongzi krishna kublai kukulkan kusaila lakshmi lalibela lancelot laotzu laozi lenin leonidas liliuokalani loki lucifer malinche manco mani manitou
mansa mao marcus marduk mary maryam masinissa maui medusa mehmed mencius menelaus menelik menes merlin minamoto miyamoto moctezuma mohamed mohammed
mongke montezuma moses muhammad musa musashi nanabozho nanabush nanook narmer nazi nebuchadnezzar nefertiti nero nezahualcoyotl noah nobunaga odin
odysseus ogedei olaf oleg omar orhan osiris osman ovid pachacutec pachacuti pachamama pakal papa paris parvati pele penelope pericles persephone
perseus peter philip plato poseidon ptah ptolemy qianlong qin quetzalcoatl ra ragnar rama rameses ramesses ramses rangi re rostam rurik rustam
rustaveli saladin sanada sargon satan scipio sedna sejong sekhmet selassie set seth shaka shihuang shimazu shiva shivaji shota shun siavash siddhartha
sigurd sita socrates solomon solon spartacus stalin subutai suleiman sundiata sunjata suntzu sunzi surya susanoo svyatoslav taejo taira taizong takeda
tamar tamerlane tane tangaroa tariq temujin tenoch tezcatlipoca theseus thor thoth thutmose tiglath timur tinhinan tizoc tlaloc tokugawa tolui
toyotomi trajan tupac tutankhamun tyr uesugi umar uthman vakhtang viracocha virgil vishnu vladimir wanggeon wisakedjak wudi xerxes xipe yahweh yamato
yao yaroslav yupanqui zarathustra zedong zeus zhou zoroaster
"""
const ENGLISH:="""
able after again also and anna another ant area army away baba baby back bad bale ball banana band bane bank bark base bat bate bath bean bear beat
bed bee been before bell belt bent best big bile bill bird bit bite blow blue boat bobo bode body bolt bond bone book bore born boss both bowl bull
bunk busy but caca cake call calm came camp can cane cap cape car card care case cash cat cave cell chat chin chip city clay club coal coat coca code
coke cola cold coma come cone cook cool cope copy core corn cost could cove cow crew crop cube cure cut cute dada dale dame dare dark data date dawn
deal dear debt deep deer den dent desk did diet dig dim dime dine dip dire dirt dish diva dive dodo dog dole dome done door dope dose dot dote down
draw drop drum duck dug dune dupe dusk dust duty each earn east easy edge either else even ever every exam face fact fade fair fake fall fame fan fare
farm fast fat fate fear fed feed feel feet fell felt file film fin find fine fire firm fish fit five fix flag flat flow food foot for fore fork form
fort four fox free frog from fuel full fume fun fund fuse gain gale game gap gape gas gate gave gift girl give glad glue goal goat god gold gone good
gore got grab gray grey grow gulf gum gun gut had hair hale half hall halo ham hand hang hard hare harm has hat hate have head heal heap hear heat
heel held hell help hen herb here hero hid hide high hike hill him hint hip hire his hit hold hole holy home hone hook hope horn hose host hot hour
hug huge hunt hut idea into iron item jade jail jam jar jet jog join joke jot jug jump june jury just kaka kale keep kick kid kilo kin kind king kiss
kit kite knee knew knot know lab lace lack lad lade lady lag laid lake lamb lame lamp land lane lap last late lava lawn lazy lead leaf lean led left
leg lend less let lid life lift like lime line link lip list lit live load loan lobe lock lode log lone long look loop lord lore lose loss lost lot
loud love low luck lulu lung lure lute mad made mail main make male mall mama man mane mango many map mare maria mark mask mass mat mate maze meal
mean meat meet melt memo men menu mess mete mice might mike mile milk mill mime mind mine mini mint mire miss mob mode mole mom monk moon mop mope
more most move much mud mug mule muse must mute nail name nana nap nape navy near neat neck need neither net news next nice nine nod node none nose
not note nut okay once only onto open oral other ours over owl pace pack pad page pain pair pale palm pan pane papa papaya pare park pass past pasta
pat path pave peak pen pet pick pig pike pile pin pine pink pipe pit pita pizza plan play plot plus pod poem poet poke pole polo pond pool poor pope
pore port pose post pot potato pull puma pump pun punk pup pure push put quit race rag rage rain rake ram ran rank rap rat rate rave read real red
rent rest rib rice rich rid ride rife rim ring rip ripe rise risk rite road rob robe rock rod rode role roof room root rope rose rot rote rub rude rug
rule run ruse rush sad safe sage sail sake sale salsa salt same sand sane sat save seat seed seek seem seen self sell send set shall ship shoe shop
shot should show shut sick side sign silk sin sine sink sip sit site six size skin slip slow snow soap sob sod soda sofa soft soil sold sole solo some
son song sore soul soup spot star stay step stop such suit sum sun sure swim tab taco tag tail take tale talk tall tame tan tank tap tape tar task
taxi team tear tell ten tent term test text than that the them then there they thin this tide tidy tile time tin tiny tip tire titi told toll tomato
ton tone tool top tore tote tour town tree trip true tub tuba tube tug tuna tune turn tutu type under unit upon used user vale van vane vase vast vat
very vet view vile vine visit vote wade wag wage wait wake walk wall wane want war ware warm wash wave wax weak wear web wed week well went were west
wet what when where which while who whom whose wide wife wig wild will win wind wine wipe wire wise wish wit with woke wolf wood word work would yam
yard yarn year yes yet yoga yoke your yours yoyo zero zip zone
"""
const OFFENSIVE:="""
anal anus arse bastard bitch boob butt chink clit cock coon cracker cum cunt dago darkie dead dick dyke fag fart fuck fuk gook gypsy hitler homo honky
incest jap jizz kaffir kafir kike kill lesb merd molest murder naked nazi negro nigg nigr nude orgy paki pedo penis piss poop porn puta puto queer
rape retard satan semen sex shit slut spaz spic tits tranny turd twat vagin wank whore wog
"""

const BREAK:="\n"
static var _words:Dictionary={}
static var _offensive:PackedStringArray=[]

## Every whole word a name may not be, lower case.
static func words()->Dictionary:
	if _words.is_empty():
		for text:String in [PLACES,PROVINCES,PEOPLES,FIGURES,ENGLISH]:
			for word in text.replace(BREAK," ").split(" ",false):_words[String(word)]=true
	return _words

## The strings no name may contain.
static func offensive()->PackedStringArray:
	if _offensive.is_empty():_offensive=OFFENSIVE.replace(BREAK," ").split(" ",false)
	return _offensive

## True when a lower-case word (or any word of it) may not be a name.
static func blocks(word:String)->bool:
	var lower:=word.to_lower()
	var whole:=lower.replace(" ","")
	var listed:=words()
	if listed.has(whole):return true
	for part in lower.split(" ",false):
		if listed.has(String(part)):return true
	for bad in offensive():
		if whole.contains(bad):return true
	return false
