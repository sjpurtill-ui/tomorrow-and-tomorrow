extends RefCounted
## Words no generated name may be (people_language.gd): real places, real
## peoples, real historical, sacred and legendary figures (docs: alternative
## history; real history is calibration only), brands, common English words,
## English words and names a probe of every tongue turned up, borrowed words
## that would make a name a joke ("Sushi", "Sumo"), and short offensive or
## silly words. OFFENSIVE holds strings no name may contain anywhere,
## OFFENSIVE_START strings no word of a name may begin with. Lower case,
## separated by spaces or lines.

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
## Common English words: a name that is one reads as a word, not a name.
const COMMON_ENGLISH:="""
ability able about above abs academic accept access according account achieve across act action active activities activity actual adapt add addition
additional address adjust admin adult adv advantage advice affect afford after again against age agency ago agree ahead air align all allow almost
alone along already alright also although always amazing amazon among amount anal analysis and another answer ant any anybody anymore anyone anything
anyway anywhere app appear apple apply appreciate approach arch architect are area arm around arr art article ask asked aspect ass assess assign
assist attach attack attempt attend attention attract audience audio austral auth author avail available average avoid aware away awesome baby back
background bad bag balance ball ban band bank bar bas base basic basically basis batter battle beaut beautiful became because become becoming bed been
before began begin beginning behavior behind being belie believe below ben benefit best bet better between beyond big bigger biggest bill billion
birth bit black block blog blood blue board body bond book books born both bottom bought bound box boy bra brain brand break brief bright bring bro
broad brought bud budget build building built bull bunch bur bus business but button buy cal call called calling calls cam came camera camp campaign
campus can cannot cap capacity capital capt car card care career carry case cash cat catch category cause cell cent center central century cert
certain chain challenge chance change changed changing channel char character charge chart chat check chem child children chin china choice choose
church cir city claim class classroom clean clear click client climate close closer cloth cloud coach code coffee col cold coll collect collection
college color com comb come comes comfort coming comm command comment commit common community comp company complete complex computer con concept
concern condition conditions conduct connect connected connection cons consider considered consist consult cont contact contain content continue
contract control cook cool cop copy cor core corner correct cost could count country couple course court cover covered crazy create creative cred
credit critical cross cry crypt cult culture cur curious current currently custom customer cut dad daily dam damage dan danger dark data database date
day dead deal dealing death deb debt decide decided decision decisions deep def default definitely deg degree del dele deli deliver demand demon
department depend deploy design detect deter dev develop developed device did die diff difference different difficult dig digital dire direct
direction directly director dis disc disco discuss discussion display dist div dive doctor document does dog doing doll don done door double down
download drag draw dream drink drive drop drug dry due during each ear early earth easier easily easy eat economic economy edge educ education eff
effect effective efficient effort eight either elect electric element else email emotion employ enc encourage end energy engage engagement engine
enjoy enough ensure enter entire environ episode equal equipment equity err essential est establish estate eth euro even event ever every everybody
everyone everything evidence exact exactly exam example excited exciting excl exec exercise exist exp expand expect expected expensive experience
experiment expert explain explore ext extra extreme eye face fact factor faculty fail fair faith fall familiar family fan fantastic far farm fast
father favor favorite fear feature federal feed feedback feel feeling feet felt few field fig fight figure file fill film fin final financial find
finding fine finish finished fire firm first fish fit five fix flex floor flow focus focused fol fold folks follow following food foot for force fore
forget form format forth forward found four frame free fresh friend from front full fully fun function fund fundament funding funny fur further fut
future gain game gas gave gen general generate generation get getting girl give given giving glass global goal god goes going gold gone gonna goo good
google got gotta gotten govern government grab grad grand grant graph great green ground group grow growing growth guess guest guide gun guy had hair
half hand handle hands hang happen happening happy hard have haven head health healthy hear heard hearing heart heat heavy held hello help helpful
helping her here hey high highlight him himself his hist history hit hold holding home hon honest hop hope hosp hospital host hot hour house housing
how however huge hum human hundred ice icon idea identify identity ill image imagine imp impact implement import important improve inc inch incl
include income increase increasing incredible ind individual industry inf inform initial innovation input inside inst install instance instead
instruct insurance int inter interact interest interested intern internal internet interview intro introduce invent invest investment involved issue
item itself japan job john join journey jump just keep keeping kept key keyword kick kid kill kind kinda kinds king knew know knowing knowledge known
lab labor lack land language large last lat late later launch law lay layer lead leader leadership leading learn learned learning least leave left leg
legal length less let letter level library life light like likely limit limited line lines link list listen liter little live lived lives living load
local location lock log long longer look looked looking lord lose loss lost lot love loved low lower luck mach machine made mag main major make making
man manage management manager many map mar mark market marketing mass massive master match mater material matt matter max maxim may maybe mean meaning
meant meas measure mech media medic medical meet meeting member memory men mental mention mentioned menu mess message met meth method micro mid middle
might mil military mill million mind mine minim minute miss mission mist mix mob mobile mod mode model modern mom moment money month months more
morning most mot mother mount move moved movement movie moving much multi multiple mus music must myself name named national natural nature near
necessary need needed neg negative neigh net network never new news next nice night nine nobody non norm normal north not note nothing notice now
number numbers nut object occur off offer office often oil okay old once one online onto open opinion opp opt option order organ origin original other
our ourselves out output outside over overall own pack page paid pain pan pandemic panel paper par parent part particular partner party pass passed
passion past pat path patient patter pattern pay paying peace pen people per percent perfect perform perhaps period person personal personally phone
phys physical pick picture pie piece place places plan planet planning plant platform play playing please plug plus pod podcast point pol police
policy political poor pop popular population port position positive poss possible post pot potential pow power powerful practice pray pre predict
prefer prem prep prepared pres present president press pressure pretty prevent previous price prim primary print prior private pro probably problem
process produce product production prof profession profit program progress project prom prompt prop proper property protect proud prov provide
provided psych pub public publish pull purchase purpose push put putting quality quant quarter quest question questions quick quite quote race rad
raise ran random range rate rather reach react read reading ready real reality realize realized reason rec receive recent recognize record red reduce
ref refer reflect reg regard region regular rel related relative release relevant rem remember remind rent rep report reports represent request
require research resist resource resp respect respond response rest result ret return rev review rich rid right risk road rob rock role roll room
round rout rule run running safe safety said same sat save saving saw say saying scale scene sch schedule school sci science score screen script
search season sec second secret section security see seeing seem seen select self sell send sense sent separate series serious serve server service
session set sets setting seven sever several sex shall shape share she shift shop short shot should show showing shown side sign sim similar simple
simply since sing single sit site sitting situation six size skill skin sleep slide slight slow small smart social society soft software sol sold
solid solution solve some somebody someone something somewhere son song soon sorry sort sound source south space speak spec special specific speed
spend spending spent spirit spot spread square staff stage stand standard star start stat state statement states status stay step steps stick still
stock stop store story straight strategy stream strength stress strong structure stud student study stuff style sub subject subscribe success
successful such sudden suggest sum summer sun super supp supply support supposed sure surface sustain switch syn system tab table take taken takes
taking talk tar target task tax teach teacher teaching team tech technical technology tell telling temper ten tend term terr test text than thank that
the their them themselves then theory there therefore these they thing think third this those though thought thousand threat three through throughout
throw tick time times tips tit title tod today tog together told tom ton too took tool top topic tot total touch tough tour town track trad trade
traffic train training trans transact transfer transform transition transl travel treat treatment tree trick tried true truly trump trust truth try
trying turn two type ult under understand unique unit university unless until update upload upon use used useful user using vac val valid valuable
value values var variety various version versus very video view viol virtual vis vision visit visual voice vol wait waiting walk walking wall wanna
want wanted war was watch water way wealth wear web website wee week weight weird welcome well went were west what whatever when where whether which
while white who whole why wide wife wild will willing win wind window wish with within without woman women won wonder wonderful wood word work working
works world worry worth would wow write writing written wrong wrote yeah year yes yet york you young your yourself zero
"""

## English words and names a probe of every tongue (over a million names)
## turned up: dictionary words, famous people, places and brands, and names
## that read as English. Name-like syllables shared with real tongues
## ("Kana", "Ling", "Yang") are left out.
const FOUND_ENGLISH:="""
aachen aah abash abashing abate abaya abayas abe abed abel abele aber abergwili abet abets abide abos abrin abut aby acas ace aces ache achebe achene
aches aching achoo acini acyl adage adami adan adana adar adas added adder adel adela adele adios adit adman ado adobe adoral adur adze aelia aero
aery aes aga agama agamas agana agar agars agas agates agba agden age aged ager ages agey agile aging agio aglet agnes agnus ago agog agora aha ahab
ahas ahaz ahem aid aida aide aidos ail aim airman ait ajar ajman aka akasha akee akees akin akira akitas akmal akron alamo alamosa alan alana alar
alas alate alaw alba alban album aldan alden alder aldo aldus ale alec alee ales alex alga algal alger algoma alias aligarh alike aline alisa alisha
aliso alison alito alkali alkham allan allay allee allen aller allie allier allies allis ally almar almer alofi aloha alone along alt alters altham
alto alum alun alves alway alyth amado amanda amaral amaro amati amato amaze amazes amber ambush amen amens amer ames amgen amid amide amigas amihai
amino amir amis amish amit ammo amnia amoco amok among amos amotz amparo amu amur amuse amway amy amyl anabel anaheim anakin anatta ancho anchos
andaman anded anders anele anew angara angel angela angels anger angers anges angina anglo angolan angora angular anichi anima anime animus anion
anita anmer annam annan annas annes annie annika anno anoka anon ans ansi anson ante antero antes anti antin antis anton antone anvil anzac aol aotea
aoyama apas ape apes apion apis apish apron apus aqua arabis araby arago aral arame aranui arash archon arden ardent ardern are arena aria arian arias
arid ariel aril ariz ark arlen armor arno aroma aron aros arose arran aruba arum arvan aryan aryl asama asana asanas asap asbos ascher ash ashed ashen
ashens ashes ashing ashlar ashow asian aside asif asir askam askari asked asoka aspen assan assen assent asser assert asses assets asters aston astor
asus atapi atari atatu atbash ate ates athan atl atman atoka atom atonal atone atop atria attala attar attest aura auras aurei auroa aurora auto aux
ave avenge aver aves avian avila aviram avis avon awakens awash awe awes awning awoke awol axe axel axes axil axle axles axon ayah ayala aydin aye
ayer ayes ayot ayr azad azadi azam azana azanian azar aziz azor azov azusa baa baal baars baas baasha babas babe babel babes babi babis babist baboon
bach bache bached bachet baching bacon baddy bade baden bader badoo baez baffin baged baging bagot bah bahai bahama bahia baidu baikal bail bailing
bain bait baiting baize bajan bake baked baker bakes baking balaban balaj balata balatas bald balda baldon baler bales balgay balkan balla ballard
ballela ballina bally balne balog balsa balsas balti baltis balun bambi bamboo bamboos ban bananas banda bandana bandar banding baned banes bang
bangui banham baning banish banking banos bans banter banting banton bantu banyan bap bar barash barbadian barbara barbon barby barchan bard barden
bardi bare bared bares barge bargy barham barkan barkham barman barn barnard barned barnet baroda baron barone barr barra barri bars barsham bart bas
basal baseed basel baser bases bash bashar bashed bashing basho basie basil basilar basin basing basis baskets basle basmati basso bast baste basten
baster bastes bastin bastion baston bated bater bates bathe bathed bathos batik batiks batman baton bator bats batten baum baur bavant bay bayed bayer
baying bayou bays bazooka bea beach bead beal beast bec bedale bede beded bedew bedim bedon beebe befog befool beg begat begin beging begot behan
behar beheld behest beige beith bel belabor belate belay belays belem bella belle bellini belong bely belys bema beman bemas bemba ben bending benet
benga benito benji bens bensen bento benton bentos beral berate berden berea beret berets beria berk berman berna berne berse bert berta bertha beryl
beset besets beside besom bestir bet beta betake betakes betas betcha betel beth bethe bethel beting bets bette bev bevan bevel beware bey beyer beys
bezel bezzi bias bib bid bidden biddy bide biden bider bides bidet biding bier bifid bigha bighas biging bigot biham bihari bike biker bikes bikini
bilayer bilbo biles biltong bim bimbo bimini bin binac binate binder bindi bine bined bines binet bing binge bingen bingle bingo bingos binham bining
binman bins bint binton bio biodata biog biol bion bios biose biota biped birk birman birsay birse birther biryani bisham bishton bison biter bites
biting bitnet bits bitton bix biz bizet bizzes boa boas bob bobed bobing boca boche bochum bod boded bodes bodoni boer boffin bog boga bogie boging
bogon bogus boho bois bokeh bola bolam bolas bold bole bolero boles bollard bolte bolus bom bonar boner bones bonetti bong bongo bongos bonita bonito
bonk bono bonus bonze boo booger booming boon boone boos boost boosting booze bop boping borane borate borden borel borelli borer bores borio boris
bork borko borley borna borne boron boru bosh bosham bosom boson bosun bot botha botham bother bothys botnar botox bots botus bouman bout bow bowel
bowen bower bowes bowie bowing box boyer boyes boyish boyo boyos boys bozo bozon bozos bra brace bracero braces braco bracon brad braddan bradden
bradon brady brae braes brag braga brahe braid brail brain braise brake bram bran branden brando brank brans brant bras brased brash brat brats
bratton bravado brave braves bravest bravo brays braze brean brec brechin bred brede bredin bredon bredy brefi bremer bren brenda brenna brent bret
breton bretton breve breves brevets brewis brian briana briar bribe briber brice bridal bridals bride brie brier briers briet brillo brim brine brines
brink brio bristo brit brito bro brod brode brogan broke broken broker brome bromine bronte broome brora bros brose broses broth brotton brow bruce
bruges brum brume brunel brunets bruno brunt brush brut brute bruter brutus bruv bryne bryngwyn bub buber bubo buchan buchanan buded buding budo bug
buged buj bulge bulla bullard bulli bum buming bun bunche bung bungay bunin buns bunt bunya bunyan buoying bur burca burel buren bures burier burin
buring burk burka burke burkha burman burn burne burr burra burro burs bursar burt burton bus bused bush bushed bushel busing busman busmen busse bust
butane buting buts buxom buy buyer byline bys byte byth byton cabal cabala cabin cabo cabus cad cadder caddo caddy cafard cafe cafes cage cages cagier
cagy caine cal calla callan callas callie callus calne calor camas camel camion camus canad canard candor caned canes canine canis canna canola canon
canto capel capella capes capo capon capone capos carafe carden cardin carer cares cargo carina carla carlin carlo carol carpi carse carta carve cas
casa casaba cased casella cases casino cassia cated cater cathy cato cauda cavan caves cays ceca cecil cedar cede ceder cedes ceil celia celina celine
cellan celler cello cellos ceres cetus chaco chadha chadian chador chaeta chaetae chafe chagas chaining chaise chaitanya chalan chalaza chale chalet
chalton champing chanel change changeling changzhou chanson chanting chaos chap chapatti chaped chapel chaping chapo char charas charman charon
chartham charva chase chaser chases chasing chaska chaste chatham chating chav chavas chawton chayka chazen cheam cheetah chekov chelan chelate chem
chemo cher cheri chesham chesil chetham chevets chew chewing chia chian chias chichi chico chide chides childe chiles chili chilli chime chimer chimes
chimu chinas chine chines ching chining chino chinook chinos chiping chiral chiron chiru chirus chis chisago chisel chit chital chitin chivas chive
chojun choke choker chokes chol choler choose chooses chop chopin choping choral chore chorine chorus chose chosen choses choti chow chowan chowing
chub chukchi chula chum chuming chung chunyun chute chutes cia ciara cid cilia cille cine cinzano cir circa cis cisco cite cites cobol cobra cocas
coco cocoa cocos cod coda codas codded codes coffin cog cogan col colac colan colas coles colfa coli colin collard collie collier collin colo colon
comal comas comer comes como conan condo condos cones cony copes copier copini copys cor coral corden corel corella coren cores coretta corina corine
corona corwen cos costa cosy cosys cote cotes coton covina cowan cowed cowen coys cubes cul cunard cupar curbar curia cyan cyma cymas cyme cymes cymyn
dab dabed dabing dabo dace daces dacha dachas dad dada daddy dade dado dados dadra dag dahlen dahua dairy dais dakin dalai dales dallas dalles dallier
dally dam daman damania damas damask damed dames damian damien daming damion damjan damme damon dampen damson dan danae dander dando dane danes dang
dangle dania daniel danish dank danni dans dante danton daqing dar daren darer dares darien darin daring dario darke darla darn darpa darran darrin
darshan dart darton darwen daryl dash dashamir dasher dashiki dat data dated dater dates datsun datum datura dauber dave davis davit davits dawes day
dayak dayan days daze dazed dazes dean debach debar debase debate debian debit debora debra debus dec decal deco decos dedham dee deed dees defame
defat defer defog defy defys degas deist deja deke dekes del delano delate delay dele deleed deles deli delia delian delink delis della delos delray
delta deltas delve dem demas demean dement deming demit demits demo demos demur denali dened denier denim dening denis dens dense dental denting
denton deny denying denys deon der derek derwen des desai desha desi desis desman desna desoto detach deter deters deum dev devan devi devil devils
devin devonian dew dewan dewans dewar dewars dewy dial dialog diana diane dias dice dices dicier didem dido die diemen dies dieting digest diging
digit dijon dike dikes dilate dildo dildos dilek dillard dilton dimas dimes diming din dinah dinar dinas diner dines ding dingle dingman dingo dining
dinis dino dins dint dinting dinton dinuba dion dione dior diose diping dir dirac dirk dis dished dismal dispur ditto divali divan divas diver dives
diwan dixie dob dobra dobro docomo dod dodos doe dogate doge doged doges dogy dogys doh dojo dojos dolan doles dolina doline dollis dollys dolor dolt
dom domain domer domes domini don dona donas donat donate donati donato doned dong donging doning donna donne donor dons doodah doohan dopa dopas
doper dopes dopier dopy dora dorado doral dores doris dork dorsa dory dos dosed doses dosh dosha doshas dossier dost dotard doter dotes doth dothan
dots dotson douche doula doulas doune douro dove dover doves dow dowers doyen doz doze dozes drab dragon drake drakes dram drama drank drano drat
drats drawer dreg dreiser dreser drew driby drier drip dristan drivel dromos drone drones drool drove drover drub drumbo drunk drupe druse dualing
duane dub dubed dubing dud dude dudes dufay dugald dugan dugong duh duke dukes dulas dulera dullard dulles dumas dumat dumbing dumbo dun dunbar duncan
dunce dunces dundas dundon duned dunes dung dungan dunged duning dunino dunk dunne duns dunsyre dunton duo duomo duran durer durian durie duror durra
durzi duse dutta dyad dyfan dylan dyne dyno dyson dzo dzos ebola echo echoing echos eco econ ecu edam eday eddys eden edina edit edith ednam edom eel
eerie egad egan egham egis ego egos egret eib eid eisen eke ekes ekka elah elam elan elanor elara elate elates elba eld elem elena elev elgar eli
elias elida elide elie elisa ella elle ellel ellen elman elmer elmet elmo elsan elsham eltham elul elven elvens elver elvers elves elvet ember emerge
emes emil emile emilia emir emit emma emmet emmets emo emos emu emus ended endon enema engel engin engine enid enmesh enner ennui enos ensay ensor
enum enzo eol eon epa epas epoch era eras erase eraser erat erato ere erica erich erik erika erin eris erith erk ernan erne ernes ernest eros ervan
esata esh esher esse essie estela ester eta etas ethan ethel ether ethos ethyl etna eton etta etton etude eva eval evan evens eves evian evil evoke
ewan ewen ewens ewer ewes ewing exe exit exon eyam eyes eyot ezra fab fabed faber fabian fabing fabis fable fabyan facer faces facia facias facie
facula fad faddy fades fading fado fados fadus faery fah fain fairy faison fajita faker fakes fakir fallen fallin fallon false falsi fames famish fane
faned fanes fanfold fang faning fans fante fanti far farad farce fares fargo farhad faria farina farne faro farofa farsi fash fashanu faso fatah fatal
fated fates fatiha fating fats fatso fatwa fauna fauve fav fave favela faves favors faxing faye fays faze fazes feat feb feces fechan federer fedewa
fedor feinman feint feis felafel feline fella fellas fellini felon felton fem female femme fen fending fenian fens fer feral fermi fern fest feta
fetal fetas fete fetes fetid fetter fever fevers few fezed fib fibed fiber fibre fibres fibula fica fiche fichu fide fidel fido fidus fie fifa fife
fifes fifo figed filer filers files filet filler filo filon filoni filos filton final findo fined finer fines finet finis fink fino finos fins fiona
fir fired firer fires firmo firs fished fiske fist fited fits fob fobed fobing foci foe fog foged fogy fol folate folie folke folly foment fonda font
foo fop foped foping fora foray forden fores forgo forma formas forte fossa fosse fossil foston fothad fouling fovea frag framer frames fran frans
frant frap fraser frat frater frats fred freda frege fret frets frew frig fringe frink frito fro frodo frome fronde fros frost fubini fud fug fugal
fuged fuji fujimoto fujiyama fulke fum fundi fungi funk fur furan fured furn furor furors furs fused fushun fusil futile futon gab gabed gabing gabion
gabor gaby gad gaddi gaddis gaded gading gaer gaeta gaffin gag gaga gage gaged gages gaging gaijin gail gaiman gaining gair gal gala galago galah
galangal galas galed galen galena gales galing galion galla galle gallia gallo gallon gals galt galvo gamage gamay gamba gambado gambas gamete gamin
gamine gaming gamla gamma gamut gamy ganesa gang ganga ganglia gangling ganja gans ganton gaol gaoling gaped gapes gaping gar garage garbo garcia gard
garda garden gardin gareth garish garnon gars garton garum garvin gary garza gased gash gashing gaskin gasman gaston gateed gates gatima gator gatos
gatton gatun gauge gaur gavel gavin gay gaye gayish gays gaza gazania gaze gazebos gazer gazes gazza geber ged gee geekish gees geffen geishas gel
gelati gelatos geld geled gelid geling geller gels gem geming geminga gemini gen genaro gene genera genes genet genie genii gening genital genoas gent
gentile genu genus geo geog geom ger gerber gers gesher gesso geting gets geum gev gever ghat ghazal ghazi gib gibe gibes gibing gid giddy gif gig
giged gigha giglio gigo gigot gil gila gild gilda giles gilets gilma gilt gimbal gimme gimping gin gina gining gino gins ginsu giora girder giro giros
girt girton gish gist git gitana gitano gite gites github gitmo gits givens glace gladden glade gladed gladys glair glan glaser glean glebe glen
glenis gleys glidden glioma globe gloria glory glowy glycan goa goad gob gobed gobel gobi gobing gobion goby godard godel godets goer gofer gofers gog
gogol golan golda golgi golly gomes gomez gonad gonadal goner gong gonk gonna gonne gonzo goo goode goon goose gooses gop goral gorals goran gorda
gordo goren gores gorey gorge gorse gory gosh gosse gotcha gotha gouda goudas goudie gov govan gowan goy goya goyim goys grabed grad grade grader gram
gramme gran grande grandin grange grans grantor grasse grate grater gratin grav grave graven gravid gravis grebe greg grenade grene grep greta grew
grid grig grille grim grime grimed grin grins grip gripe gris grist grit grited grits groby grok groks grope groper grosse grot grote grots grove
grovels grover grower grub grude grume grunge grunt grus guile guinan guiting guizhen gulati gulet guming guned gunge guning gunk gunman gunmetal guns
gunton gunyah guofeng gurk gurkha gurkhali gurn guru gurus gus gush gusher gust gusto guted guting gutman guts gutta guv guy guyot gwen gyan gybe
gyfin gyre gyri haas haber habib habit hadar hadid hadith haem hafiz hag hagar hagen hager hagon hagushi haida haikou hail haili hailing haitian haj
hake hakes hakkas hal halal halam halama hald halen haler hales halites halle hallo halloo halon halos hals halse halsham halt halve hamal haman hamas
hamate hamed haming hamish hamlin hamon hamper handan hangar hanging hangman hangul hanif hank hanna hannun hans hanse hanuka hap hapara hapua hara
harel harem hares hark harlan harman harmon harte harton hash hasher hashish hasid hassan hast hasta haste hasting hater hates hatha hating hatlen
hats hatton hattori haul haumea haute haver haves haw hawed hawera hawes hay hayek hayes haze hazel hazer hazes heb hebe heber hebes hedge hedon heed
hegan hegira heh heidi heiko heil heine hejaz hejira helal helena helga hello helots helve hem heme hemel hemet heming hendon henge henke henna hens
henze hep her herbal herero herne hernon herod heron hers hesse hetero hethe hevea hew hewan hewed hewer hexing heya hider hiding hie hies higham
hijab hikaru hiker hikes hilda hilt hilton himel hinder hindon hindu hines hinge hinter hippo hippos hiram hirata hirer hires hising hits hiv hive
hiya hob hobed hoberg hobing hobo hobson hod hodge hoe hoer hog hogan hoged hoke hokes hokku hokum holes holme holne hols holt homai homero homes
homet hon honda hondo honer hones hongwang honk hons hoo hop hoper hopes hopis hora horam horas horde horeb horne hors hos hoses hosni hosokawa hosta
hostas hotel hoting hoton hots houma houri hov hove howay howe howel huanan huapai huawei hub huber hubert huby huchen hud hugo huh hula hulas hullo
hulme hum human humana hume humeri humid humor humping humus hung hungate hunk hunting hunton hunua huron hus hush hushed huting huts hutto hutu huzza
hyena hying ian ibid ibis ibiza ibizan ibos ices ichor icy ida iden ides idina idol idose iec ied ike ikea ilam ilea ilene ilex ilia ilich illus ilona
imac imagen images imago imam imap imide imine imola imus inane inanga indent indira indole ines inez info inge ingest ingol inked inking inman inner
inners inonu inri insert inset intel invar ion ionia ios iota iowan ipa iping ipo ipod irade irani iras irate ire ireful irene ires irian iris iritis
irk irked iroko irs irwin isa isaf ise isel ish isham ishim islay isley isos ital itanagar ivana iver ives ivor iwade iwamura iwo ixia iyar izaak ize
izod izumi jab jaban jabed jabiru jaded jaden jades jafar jag jaged jah jaina jake jakes jakob jamal jamar jamel james jamie jamil jammu jamnia jane
janes janie janis janna janos jared jars jason jat jataka jato jatos jats java javan javas jaw jawed jean jed jedi jedis jehad jello jemal jen jenna
jens jerez jerk jervas jesse jest jeted jeter jeting jets jewel jiafu jianghan jiangyin jib jibe jibes jibing jiged jihad jilt jim jimi jingo jink
jinni jit jited jiting jits jitsu jiushao jive job jobed jochen jodi jodie joe johan joker jokes jolla jolt jon jonah jonas jones jordi jorge joris
jose josefa josh joshed joshi josie joted jotham jots jotter jove jovian juab juana jubal judas jude judo jul julia julian jumbo junagarh junes junk
junko junta juntas junto jural jurat juris jussi jut jute jutes juts kaaba kaber kachori kafka kahan kaihu kaine kaiti kakapo kales kalian kalong
kamau kame kamen kames kamil kamini kamino kampong kamran kanak kanaka kanakas kanchi kandil kane kanji kanoa kans kansai kansan kant kantian kantor
kanuka kanye kaon kapiti kapok kaposi kappa kappas kaput karaka karakul karat karen karet karin karina karla karmas karol karori kart kasai kasdan
kasey katana katarn katas kate kathie katie katina katrin katrina katsura katz kauri kawartha kawata kayak kaye kayla kayo kayos keane keas kebab keel
keele keen keg kegan kegel keging keira keisha kelli kelso kelt kelton kempo ken kenai kendra kened kening kenji kenna kennan keno kenosha kens kensal
kent kenwa kenyan kenyon kepi kepis kerama keratin kerim kern kerne kesh kesha keshet keston ketel keto ketone ketos ketton kev keven kevin kevlar kew
khaki khakis khalid khalifa khamsin khan khanate khanates khayat khazi khorana kia kib kibe kibosh kided kidman kiel kier kif kilby kilda kilmeny
kilos kilpin kilsyth kilt kilted kilter kilve kim kimono kinase kinda kine kines kingan kinging kinin kink kinmel kino kins kip kiped kiping kiris
kirk kirov kiryas kishen kist kitamura kited kites kiting kits kiwi kiwis kiyoko kline kober koch kochab kofi kogan kohei koine kojak kokoda kolache
kolas kolata kombu konini konishi kook kopek koran koresh korma kormas korn koror kors kosher kossa kotlin koto kotos kotte kotz kourou kowal kraken
kramer krefeld kris krista kristi kristin kristina kriya kroger krona krone kronor kronos krum kruno kruse kuchen kudu kudus kuiti kukan kukuk kulak
kumar kumara kumari kumeu kundakunda kunis kunte kurdi kuroda kurt kurta kurtas kurtis kushi kwanza kwazulu laban label labella labia labor lacan
lacer laces lach laded laden lades ladin ladino ladle ladoo laged lagena lager laguna lain laing lais lajes lajos lakes lakisha lalita lam lamar lamas
lamaze lambing lamella lament lamer lames lamina laming lamish lanbadog landau lander lando landon lanes langar langbar lange langton langur lanier
lank lanka lankan lanolin lans lantana lanza laped lapel lapin lapis laptop lard lardon largo larine lark larne lars larsen larva las lase laser lases
lash lasham lashed lassa lasso lat latah laten later lateran latex lath latham lathe lathia lathing latina latish latisha latoya latria lats latte
lattes latton latuda lauda laura laurel lauri laurie lauro lav lavabo laval lavas lave laver lavern laves lavin lavish law lax layla lazar laze lazes
lazuli lea leah leak leas lech leched lee lees leese legate leged legion legit lego leh leila leire leis lelia leman lemke lemma lemme lemon lemur
lemuria len lenah lenard lending leno lenos lenovo lenox lens lent lento lenton lenzie leo leone leoni leper leray les lessee lest letha letham lethe
leting lets letter letton lev levan levant levar leven lever levers levi levier levin levis levor lew lewes lewin lewis lex leyen lez liana liane liar
lias lib libel liber libera libero libing libor libra libre libres lice lichen lided liden lidia liding lido lidos lie liege lien lies lif lifer lifo
ligase liger ligers ligule lijian liken liker likes lilac lili lilia lille lilo lilos lilt lilted limbo limen limes limo limos linage linda lindal
linde lindon lined linen liner linga lingam lingas lingen lingo lingua lining lino linsang linting linton linux lion lipid liping lippi liq lira lire
lisa lisle listed listens liston litchi lite lithe lithia litre litton litz liven liver lives livia livid lix liz liza llama llamas llanasa llangain
llangan llangar llangybi llanina llano llanos llany llanyre lleyn llyswen loam lob lobar lobed lobes lobing loch lochan lochawe lochee loci loco locos
locus loders lodes loeb logan loge logia login logion logo logon logos lohan loin lois lol lolita lollard lolo lomax lombe lomita lon lonan loner
longa longan longden longe longman lonnie loo looker loon loons loos loosen loot lop lope lopen lopes lopez lorde loren lorena lores loreto loretta
lori lorie loris lorn lorna lorne los loser loses loth loti lotion lots lotsa lotta lotto lottos lounge loupe louse louses lovato lover loves lowe lox
loyal loyang loyola luang lube lubes lubin luby lucan lucas lucia lucila ludham luding ludo ludos lug lugar luge luger luges luis luisa luke lulus
lumbar lumber lumen lumina lumpur lunan lunar lunas lune lunga lunge lunges lunine lunt lupin lupine lupus lures lurgan luria lurid lurie lurk lush
lust lutes lutine luting luton lutz lux luxe luxon luz luzon lydden mabel mabuni mabyn mace maces mach machado machan machar machen machiko macho
machos machu macos macula madam madame madan madden maddin maddy maded madera madge mading madman madre madura maenan maer maeroa mafia mage mages
magi magian magog magoo magor magus mah mahal mahan mahia mahora maid maiden maik mailing maim maiman maimed maine maisie maitai maitra maize maj
majno major majuro makahu makara maker makes makos makoto malabo malachi malaga malar malate malaya malayan malbis males maley malian malibu malik
malkin mallard malone malpas malt malte malton maltoni malva mam mamane mamas mamba mambas mambo mambos mamet mametz mamie mamma manages manakin
manana manasa manaus mandala mandan mandate mandela mandingo manea maned manege manes manet manga mange manges mangle mangos mangy mania manias
manikin manilla maning manish mank mankato manly manna mannas manor mans manse mansel manson manta mantas mantel mantes mantis manton mantua manuka
manya manziel maped maping maple mapua mar maraca marana maras marat maratha marcan marcia marco marden mardi mared marek mares marga marge margo
marham marian marie mariel marin marina marine marino mario marion maris marisa markab marker marla marlin marne marr marrano mars marsha marshal mart
marta martha marua marva mas masada masala mased maser mash masham mashed masher mashing mashup masing masker maskin mason massa massao masse mast
matamata matane matangi matapu mated mateo mater mates matese matey mather mathias mathis mathon matico mating matos matra matron mats matson matsui
matsumoto matsuri matte matteo mattes mattie maty matzo matzos maude maul mauna maunu maur maura maurine mauro maven mavis maw mawed mawes mawing
mawson max maxi maxim maximal maxing maxis may mayas maybes mayday mayen mayer mayes maying mayo mayor mays mazama mazel mazes mazza mbini meara meas
mebane mech mecha mechas mechen med medal meddan medea median medias medich medina meg mega megabat megan megapolis meghan megos megrim megyn meh
mehigan mein meinie meir mejia mekong mel melan melba melcher meld melee melin meline melisa mellis melly melon melos meltham melva melvin meme memes
memos menace menage menai menard menasha mending mengele menkar mensa mentor menus menzo mep mepal merak mercia mere meres merge merinos merion merit
merle merlo merman mers mersham mershon meryl mes mesa mesas mesed mesh meshaw meshing mesing mesne meson messi messina met meta metage metal metayer
meter metes meth methil methyl methyr metier metis metol metre metres metro metros metta metton meuse mev mew mewan mewed mewing mex mexican meyer
mezza miami mib mica micas mich michel mid midas midden middys midi midis midmar mielie mien miers mieza mig migos mihara mikado mikal mikes mil milad
milam mild miler miles milian millay mille milliard milne milo mils milson milt mimas mimeo mimes mimi mimosa minaj minden minelli miner mines mingle
mingo minho mining minion minis mink minke minna minor minos minot mins minter minting minto minton minus minyan miocene miosis mir mirada mirai
miramar mires miry misdate misdo mise miser mises mishima mishin missus mist mistle misuse mit mite miter mites mitis mitova mitre mitzi mix mixen
miyako mizar mizen mizens moan mobil mobing moby mocha mochas mod modal modals modan moded model modes modi moding modular modulate module moduli
modus modwen moe moel moet mog mogul mohan mohur moi moine moira moita mokau moke mokena mokes mokos moksha molal molar molash mold moles molina
molnar moloch molt molto molton momma momus monacan monad monash monday monea monel monet monger monica monika mono monos mons mont montana monte
monthan montoya monza moo moola moomba mooning moor moos moose moot mooting moper mopes mopier moping morad moraga moral morale moran morano moray
morays morden morel mores morgan morgen morid morin morio morita mormon morn moron moroni morose morro morse mort mortal mos mosed moser mosey mosh
moshe moshing mosing moston mot mote motel motes motet motets moth motion motor mots motto moule moulin moura mouse mouton mov mover moves mow mowing
mox moxie moyer moyes mozer mozes mucus mufon mugabe muire muker mules mulish mum mumbo muming mun munda mundane mundi mundon mung munge mungo munier
munoz munro muon mural murali murasaki murat murcia murdo muriate muriel murk mus muser muses mush mushed musing mutate muter mutes muthu muzak mylor
myna mys mysia myth naan naas nab nabed naber nabet nabing nacho nadab nadal nadella nader nadia nadir naenae naevi nafion nafta nag nagae nagar nagas
naging nah nahum nailing naira naive nakamoto nakamura nakano nakayama naker nalgo nam namaka namath namaz namer namers names namib namier nampa namur
nan nana nanak nandi nandina nanga nangle nanna nano nans nanshan nant naoki naoko naomi napes napier naping nappa nard naresh nark narnia nary nas
nasa nasal nasar nash nashe nasion nasir nasrin nassau nasty nat natal natasha nate nathan nathel nation natl nato naval navar nave navel navels nawab
nay nayika nays naysay neal neb nebel nebula neches ned neddy neddys nee nefyn negev negus neh neihu neil neith nek neks nelda nelder nelle nellie
nelsen nemaha neo neon nepali nerine nerk nerka neruda neshoba nest neston nestor neted nether nethy neting nets netter netto nev nevay nevern nevi
nevis new newel newer nez ngapara ngataki nib nibing niche niches nichol nichole nico nicol nicola nidi nidus nigel nigella nih nikai nike nikita
nikki niklas nikola nikon nil niles niling nils nimbi nimmo nines ninja ninon niobe nip nipas niping nisan nisei nit niter nitid niton nitre nitro
nitros nits nivea nix nixing noak noam nob nobel nodal noddy noded nodes noding nodum noel noemi noise nok nokia nolan nolte nolton nomad nomen nomens
non nonage nonaka nonda nondas nones nonet nonets nonie nonya nook nooks noon noonan noose nooses nopal nope nor nora norad norah norco norden norina
norma norn norte norton noser noses nosey nosh noshed nosher noshing nosing nosy nota notal notes noth notion notre nots notum noumea noun noura nous
nov nova novae novak novas novato novaya novel novella novena novers novichok now nowata noway nowise nowton noyes nub nubile nuchal nugent nuke nukes
nun nunda nunes nunez nunki nuns nutate nuting nuts nuzzi nyala nyanja nyanza nyasa oaken oar oarage oarer oas oasal oat oaten oates oban obeli obes
obey obi obion obis obit obol ocelli och ocher ochil ode oden oder odes odian odis odom odor oed oem oga ogata ogre oher oho ohoka ohura oik oil oiled
oiran oise okamoto okapis okato okla okra okras okura olav olden ole oled olen oleo oles oligo olin ollie olog olum omaha omani omasa omata omen omens
omid omit omni omri one onekawa ones ongar onia onich onion onset onsets ont onus ooh ooze opal opawa ope opel opens operas opes oppo opus orang orate
orates orca orders ore orem oren ores organa orig orion oriya orle orlin orono osage osama osawa oses oshawa oshii osho osier oskar ossie ostia osyth
otago otaki otara oteha otero otham otis otoh otomi otten otter otters otto oud our ousel out outage outages outed outran outta ouzel ouzos ova oval
ovals oven overs ovolo ovular ovum owaka owe owen owens owes oxen paar paca pacas pacer paces pacha pachas pacheco pacy padang padded paddys paded
pading padma padua paedo paella paerata paeroa pager pages paget pagoda pagri pah paige paihia pail paine paining paired pajama pak pakora pal palace
palagi palate palea paled paler pales palikir palin paling palisa palish pallas palma palmar palme palmed palos palpi palpus pals pam pamela pamir
pampa pampas pamper pampero panache panaches panada panamas panda pandan paned panel panels panes panga panguru paning panis panko panne panola panos
pans pant pantie pantile panting panto panton pantos panza paola paoli paolo pap papal papas paper papier papin pappi papula papus par parade parana
parang parapod paras parau pardon pared parer pares pareto parian paring parka parkas parke parkham parkin parlay parlor parma paroa parol parr pars
parse parses parson part partan parua parva parvenu pas pasco pased pash pasha pashas pasing pasini paskin paso passe passu pasta pastas paste pastes
pastis pastor pate patea pated patel patella paten patens patera pates pathan pathia pathias pathos patina pating patio patoka paton patras patron
pats pattaya patten patti patton paul paula pauli paulo paved pavel paver pavers paves paw pawed pawing pawning paxes paxil payer pays paz pea peach
peas peat pecan pedal pedalo pedro peen pees peg peging peiping pekan pekar peke pekes pekin pelade pella pelman pelt pelta penal pence pended pender
pendine pending pened pengam penile pening penllyn penmaen penman penmen penna penne penrhyn penrith pens pent pentad pentane pentewan pentir penton
pentyl peon pep peper pepin peping pepo pepos pepys per percha perea peres perez perga peri peria peril peris perk peron perot perren pert pervo
pesach pesher peso pesos pessoa pest pester pesto pestos petain petal petard petasus pete peters petham peting petit petone petra petri petro petrous
pets pettis petton pew pewit phaedo phaethon phaeton phase phat phi phon phone phonon photo photon piano pianos pib pica picas pico pid pie pieman
piemen pier piero pies pietro piging pigot pigou piker pikes pilate pilates pilau piles piling pillar pilot pils pilton pilular pimento pinal pinard
pinas pinata pindar pines pinging pinier pining pinion pinko pinna pinole pinon pinot pins pint pinto piny pinyon pion pip piper pipes piping piran
pirate pires pirie pirk pirou pirton pisa pish pishing piste pistil piston pitas pith piting piton pits pitta pittas pity piven pix plage plane plano
plata plate platini plaza plazas plea pleas plebe plosion pocus poer poges pogo pogos poi poilu poker pokes pol polar poled poler polers poles poling
polio polios polka pollan pollard pollen pollini pollinia polos pols poly pom pomade pomar pomona pone pones pong pongo pons pont ponte pontin ponton
pony ponzi poo pooja pooka poole poon poona poos poped popes poping popish poppa poral pores porgy porin pork poroti porte portia portion pos poser
poses posh posing posit posse postal postil poston posy potash potent poting potion pots potto pouch poulton pout pouting pow powan powans pox prada
prado pradon pram prana pranas prat prata prate presets presto preston prestos pride prima prime prion prise prison pristina priston prize prizes proa
proas probate prod prodi prole promo promos prone propolis propria pros prose proton prov prove proved provo prusak prut pub pubes pubing puce puces
pud pugin puhoi puja pujas puke pukes pukka pulao pule pules pullum pulsar pumas pumper puning punish puns punta pupa pupae pupal pupil puping purana
purer purina puris purlin purr purua purus pus pushtu puted putin puting puts puttee putter putti putto putz puy puzo pyder pygal pylori pyran pyre
pyro qadir qatari qijun qom qubit quran rab rabi rabid rabin rabun racer races rachel racy rad radar radek radha radian radio radon radula radyr raes
raf raga ragas raged rages ragusa rah rahim rahul raid raiding rail railing raine raining raisin raison raith raj raja rajah rajas rajesh rajon rakes
rakish rale rama ramada ramapo ramati rambo ramed ramesh raming ramiro ramon ramona ramos ramping ramtha ramus ranchi randal randan randi randy rang
rangel ranger rans rant ranton ranui rapid rapier rapine rapini rare rares rase rasen rases rash rasher rashida rasse rasta ratas rated ratel ratels
rater rates rath rathen ratho rating ration raton rats rattan ratter ravel raven ravens raves rawene rawiri rawish ray rayon rays razak raze razes
razor razzed rear rebar rebase rebates rebel reber rebid rec redan redden rede redis redisham redo rees regal regan regina regio regis regor rehang
rehi rehung reid reiki reikis rein reining reit reith rel relate relay reline relit relive relume relys rem reman remini remit remus renal renard
renata renate renato rene renee reno renting renton renya renzo repo repos resale resat resave resay resays reseda resin resit reskin reston ret
retake retie reties retina reting retro retros rets rev revere revet revlon rewash reyes rheme rhigos rhinal rhino rho rhod rhoda rhode rhone rhos
rhoten rhyl rhys rial ribald ribas rican ricer rices ricin rico ridden rider ridges rif rig riged rigel rigid rigor riker rile riles rilke rille rime
rimes ringo rink rinse rios ripen riper ripon risen rises rishel riston rita ritalin ritek rites riv rival rivas rive rivel riven river rivera rivers
rives rivets riwaka riyal rizal rizza roam roane robed robes robin robots robust robyn rocha roche rodden roded rodin roe rogan rogen rogus roi rois
rojas rojo rolla rollin rollio rollo rom romanes romano romei romeo romeos romer romero romes romesh romina ron ronan ronda rondo rondos roneos rook
roos roper ropes ropy rorke rosa rosalie rosella rosen roses rosh roshan roshi roshis rosin rosina roslin rospa rossi roston rosy rota rotas rotate
roted roth rotor rots rotter rouge rouhani rous route rove rover roves row rowan rowed rower royal rubati rube rubed ruben rubes rubik rubin rubing
ruby ruche ruden rue ruin ruining rules ruling rum rumania rumba rumen rumina rumor rune rung runged runing runner runs runt runton runway rupee rupes
rural rusa rusas ruses rushed rushen russo rust rut rutan ruted ruting ruts ryan rydal saar sabah sabana sabar sabash saber sabha sabian sabik sabin
sabina sable sabra sabre sabres sacha sachem sachet sachets sachi sadako sadat sadden sades sadhana sadhu sadowa saes safer safes sagan sagar sagas
sages saging sago sagos saham sahib sailing sailor saipan saith saithe saiva sakai sakes sakha sakis saks sakti saktis sal salad salado salah salako
salami salamis salas salem salen sales salian salina saling salish saliva salla salle sallie salman salmon salon salop salton saluki salve salvia
salvo sam samah samar samara sambas sambo sambos sames samey samian sampan samson sananda sanches sancho sandal sandi sanding sandon sandor sangam
sangamon sanjay sank sanka sanofi sans sanson sant santa santan santana santer santo santon santos sanyasi sap saped sapid sapin saping sara sarah
saran sarge sarin saris sark sarkar sarma sarong saros sars sarsen sarto sarum sas sash sasha sashay sashed satay sate sates satin satis satori
satoshi satsuma satya saudi sauk saul sauna saute sautes savanna saver saves savor saw sawed sawing sax say says sea seal sean sear seas seato seb
sebum sec secy sedan sedate seder sedona sees segal segar sego segos segre seidel seil seise seisin selah selena selim seller selma semer semi semis
semite senary senate senile senna senor sensa sense sent sep sepal sepia sepias seppo sera serac serang sere serena serene seres serge sergio serine
serlio serra servo sesame seta setae seton sets sevens severn sevier sew sewage sewing shad shade shaded shades shadi shading shaged shaging shah
shahar shake shaken shaker shakes shaking shakira shako shakos shakti shakur shale shaler shalom sham shaman shame shames shaming shamir shana
shanahan shane shania shape shapes sharaf sharam sharath share sharer shares shari sharia sharif sharma sharman sharon shasta shat shatner shauna
shave shaven shaver shaw shawano shawna shay she sheba shebang shebeli shed sheding sheed sheen sheena sheene sheesh sheila sheilah sheiling shekel
shelia shelta shelton shem shemale sheran shere sheri shes shevat shew shewan shewing shiah shibuya shigo shiite shikari shiloh shim shiming shimla
shinano shine shiner shines shining shinji shinto shinzo shiped shiping shire shires shisha shishas shiv shivas shiver shod shofar shoji shonas shone
shoo shook shoos shoping shor shore shostak shouting shove shovel shoves shula shuna shuned shuning shunting shusaku shush shushed shute shuting siar
sib sibia sibias sibyl sice sid sides sienna sieve sifaka sig sigil sigla sikora silage silane silas silian silica silken silo silos silt silva silvia
silvio sim simak simbel simenon simian simla simon simone simula sines sinew sing singe singes singing sining sins sinus sipe siped sipes siphon
siping sir sire siren sires sirs sis sisal siskin siston sitar sitars sites sith siting sitka sits situ sivan sixtus sizar sizer sizes sizing ska
skanda skank skara skarn skate skater skates skene skep skerne skew skewer ski skid skier skim skimed skink skins skint skip skirt skis skit skits
skive skol skunk sober sobers socha socon soda sodas sodden sodom sodor sofas soham soho soi soke sokes sol solace solan solana solano solapur solar
soles solidus solis sollas solos sols solus solva soman somata somme sonar sonata sonatas sonde sones sonia sonja sonoma sons sonsy sonya sool soon
soonish sop soper soping sora soras soraya sorbets sorel sorels sores sorta sos sosa soses sot soter sothos sots sou souk soulie souping sous sousa
sow sowens sowing soya spa spade spae spaes span spare spares sparta spas spate spathe speke spezia spike spile spin spine spire spires spiro spite
spode spoke spore spores sta stab stadia stag staged stain stake stakes stale stales stamen stamina stan stane stanion stank stanzas stape staple
stara stare stared starer stares stark starke stars start stash stasis stat stated stater statin stator stators stats stave staves ste stein stela
stella stem sten steno stenos stent stern sterne stert stet stets steve steven stevin stew stile stilt stilton stine stink stint stipe stipes stir
stired stirs stis stobo stoer stogie stoke stoker stol stole stolen stolon stoma stonar stone stoner stonor stooge stoped storer stores stork stove
stow stowe stub stum stumed stun stunk stuns stunt stupor sub subah subak subing sudra sudras sue suet sufi sugar suissas suite suiting sulfa sulla
sultan sulu sumac sumbawa sumo sumos sunda sundari sundas sundew sundon suned sung suning sunk sunken sunna sunni suns suntan sunup sup suping supra
surah suramin suras surer surra susan susana sushi susie sutra suv svelte sven syd syed syn tabano tabatha taber tabing taboo tabor tabun taced tad
tadman taegu taf taged tagine taging tagus tahana tahina tahini taiga taiki tailing tainan taine taino tainos taipan tairua tait tajine takagi takaka
takapu takaro takei taken taker takes takeshi taking takoma tal taleb talent tales talke tallier tallis tallon talon talus talut tam tamaki tamara
tamashas tamed tameka tamer tamera tames tamika tammi tampa tampon tamra tanaka tanakh tanar taned tangelo tangle tango tania taning tanisha tanist
tanja tankini tannin tans tanur tanya tao tapas taped taper tapes tapeta taping tapir tapora tapu taranaki taras tarawa tare tared taree tares tarim
tarmac tarn taros tarot tars tarsals tarsi tart tartan tarvin taryn tarzan taser tash tasha tashi tasked taste tastes tasto tastos tat tatami tate
tated tater tatham tating tats tatum tau tauhoa taus taw tawing tawse tawses tawton tax taxa taxal taxil taxing taxis tazza tazzas tbas tea teak teal
teas teat tebay tec tech ted teddy teddys teder tee teen tees tehama teifi teijin tel telesto telex telfer teller telmo temin tempe tempi tempo temuka
tendon tenet tenex tenon tenons tenor tenpin tens tense terek teresa terga tern terra terse tesla tesol tessa teste tester testis teston tet tether
tethys teton tetra tetrad tetsu tew tewin tex texaco texan texes thad thain thais thali thalia thalis thame thanatos thane thanes thar tharakan thebe
theme thenar therion theron thesis thespis theta thetas thine tho thole tholin tholos thom thomas thong thoron those thou thous thud thur thus tia
tiago tiaras tib tibia tibias tidal tides tidier tidys tie tied tiepin tier ties tif tiffin tigard tiger tike tikes tiki tikis tikka tikkas til tilde
tiler tiles tiling tillard tilt tim timaru timer timex timid timing timon timor tina tinder tine tined tines tinge tinged tinges tinging tingling
tining tinker tins tinsel tint tinted tinting tinton tioga tiped tiping tirabad tirades tirana tirane tirau tired tiree tires tiro tirol tirole tiros
tisane tisha tishri tisri tit titahi titan titbit tithe tither titles tito titre titus titze tobago tobias tobin tobit toby tod today toe tofu tofus
tog toga togas toging toil tojo tokay toke token tokens tokes tokita tolaga tole tollard tolle tolman tom tomas tombola tome tomer tomes tomoko tonal
tonelli toner tones tonge tonging tonia tonk tonkin tonna tonne tons tonto tonya too took toome toon toons toope toot tooting toots toowong tope toped
topers topes topi toping topoi topos tor torah tores torn torpor tors torso tort torte torus tory tosca tosh tostada tot total totara toted totem
totes totham totnes toto tots totton tov tow towai towel tower towie towing townish towton towy towyn tox toxin toy toys trace tracer traces traci
tracy trad trader trades tragi tragus tram tramiel tranent trank trap trash travis treas tref trefonen trek treks trellis tremor trenail trent trepan
trevor trial tribe trice trices tricia trier trig trike trim trimed trina trine trines trio triode trios triose tripe tripos trish trisha trite triter
triton tritone trivets trivia trod trogon tron trons tropan trope tropes troston trot troted trots trove truce truces trude trudi trug trunk tsar
tsetse tsuga tsushima tuam tubal tubas tubed tuber tubes tudor tuging tuhua tukey tulane tulle tulles tulsa tum tumor tunas tuner tunes tuning tuns
tupelo tupis tur turangi turco tush tut tuted tuting tutor tutors tuts tutsan tutsi tutti tuttis tux tyga tynan tywyn tzu udham udod ufa ufo ufos
uhura ukase ukases ulna umami umang umber umbo umbos unani unasked unban undo uni unita unitas unite unlay unman unmesh unrobe unset upton ural urban
urchin urea urge urine uris urn urr urus usa usaf usage use uses usher usu utahan utan uteri utero utes utile uttar utter utters uvula uygur uzi uzis
vacua vadas vader vadia vaduz vagal vagi vagus vain val valeri vales valets valle valli valor valve vanda vanes vange vanish vans vanzetti vape vapes
vapor vapour var varaha varda varga varian varma varna vars vases vats vedas vedast veg vegan vegans vegas veged veges vein veins vela velar veld
vella velma velum venal venom vent vera verde verge vern verna verne versa verse vert verve vest vesta veto vets vetter vetus via vial viana vibe vid
vidal vidor vie viejo vies vig vigil vigor vii vilas villa villas villi villus vilma vim vimana vinay vines vino vinos vip virago viral virpi virus
vis visa visage visalia visas vise vises visor vista vita vitim vito vitro vitus viva vivas vivo viz vlad voa voas vocal vogel voila vokes vol vole
vols volt volta volte volvo vomit von vonda vostok voter voters votes vow vowels vug vulva wabash wabasha waco wad wadena wader waders wades wadi
wading wadis wafer wager wages waging wagon waikawa wail wailing waima wain waipa wairau wairoa waite waithe waitoa wakai wakame wakari wakas wakatu
waken wakening wakens waker wakes wakimoto wakulla walaka wald waldo waldos wale waler walers wales walker walla wallis walt waltham wanaka wanda
waner wanes wangle waning wanjek wannabe wanting wanton wap waqar wared wares waring wark warn warne warr wars wart was wasabi washer washing wasing
wast waste wasting watcha water wath wats watson wav waver wawen wawne waxen waxing wazoo wazoos wean webing wedale wegel weld welt wem wendi wending
wenham wep werner wert wesak wesham weting wets wichita widens wides widow wiener wiens wifi wifie wigan wiging wii wiis wiki wikis wil wilda wile
wilen wiles willa wilma wilne wilt windu wined wines wing wining wink wino winona winrar wins winson winton wip wipes wires wis wises wishaw wished
wishing wiska wist withal witham withes witing wits witte wive wix wixom wiz wizen wode woe wok woken woking woks wold woman women won wonk wonsan
wont wonting woo woos woosh wooshing wop wore worle worn worse wort wot wotan wove woven wow wowing wujing xenix xindi xix xul yah yajna yajur yak
yakima yakov yakuza yale yales yalta yamada yamakawa yamuna yap yaping yaren yarra yasmin yatala yataro yates yavapai yawed yawing yay yazor yea yeas
yened yening yeoman yep yeshua yeti yetis yeung yib yichun yid yikes yip yipe yiping yob yoda yogi yokel yoker yokes yoko yolanda yolo yom yon yoni
yonis yore you youse yuan yuga yugas yugo yuk yule yum yumas yup yutaka zadie zalta zamani zamia zane zaped zara zavala zazen zebra zebu zebus zed
zein zeke zelma zemina zen zenana zener zenker zeno zeros zeta zetas zetia zezong zhaoguo zhengli zhenhong zhuge zib zimri zine zines zit ziti ziv
zohar zomba zonal zosma zukor zulus zuz
"""

## Brands and trade names.
const BRANDS:="""
absolut acura adidas airbnb alfa alibaba amazon apple armani asahi asics atari audi bacardi baidu bentley benz bic bugatti buick bulgari cadillac
canon cartier casio chanel chevy chrysler citroen coke cola corona dacia daewoo danone datsun dior disney dodge dominos doritos ducati ebay epson
evian facebook fanta fendi ferrari fiat fila ford fuji google gucci guinness haribo heineken heinz hermes hitachi honda huawei hyundai ikea infiniti
instagram intel isuzu jaguar jeep kawasaki kfc kia kirin kitkat kitty kodak kraft lacoste lada lamborghini lancia lego lenovo lexus lipton lotus lyft
mario marvel maserati mastercard mazda mclaren mercedes mitsubishi nescafe nestle netflix nike nikon nintendo nissan nokia nutella nvidia olympus
omega opel oppo oracle oreo pacman panasonic paypal pentax pepsi perrier peugeot pixar pocari pokemon polaroid pontiac porsche prada pringles puma
reebok renault ricoh rolex saab samsung sanrio sanyo sapporo scania sega seiko skoda smirnoff snickers sonic sony sprite sriracha starbucks subaru
subway suntory suzuki swatch tabasco tamagotchi tata tencent tesla tiffany tiktok tissot toshiba toyota twitter twix uber versace vespa visa vivo
volvo wendy xbox xiaomi yahoo yakult yamaha zara zelda zippo
"""

## Foods, sports, arts and other words English has borrowed, and words that
## would make a name a joke ("Sushi", "Sumo", "Haha").
const LOANWORDS:="""
abo aikido aloha alpaca anime atlan avatar avocado bagel baklava banana bandana banjo bazaar bongo bonsai boomerang borgia borscht bulgogi bum burrito
cacao cato chai chili chowmein cocoa coconut coffee conga curry dad die dimsum dingo dunce emoji espresso falafel feta fiesta gay geisha gelato
guacamole gumbo guru gyro gyros haha haiku hookah hula hummus injun jaja jambalaya jochi judo jujitsu jungle kahuna kangaroo karaoke karate karma
kazoo kebab kendo kiki kimchi kimono kiwi koala kungfu kuntah kunto lala lasagna latte llama luau macho mahalo mambo mamun mandela manga mango mantra
masala miso mocha mojo naan nacho nachos niga nikon ninja nirvana nun origami ouzo panda papaya paprika pasta pho pierogi pita pizza poncho potato
pretzel pus ramen risotto rumba rumi safari sake salsa samba samosa samurai sanyo sashimi shisha shogun siesta sitar soba sombrero sumo sumogo sushi
tabla taco tacos tahini takasaki tamale tandoori tango tempura temur teriyaki tit tofu tomato tortilla tsunami typhoon udon ukulele vanilla vodka
voodoo walid wasabi wiki wombat wonton yoga zombie
"""

## More real rulers, writers and famous people.
const FIGURES_MORE:="""
abbas aguinaldo akihito alaric allende aquino asantewaa ashoka askia atlan atlantis attila aurangzeb ayyub bach balzac barbarossa batu baybars
beethoven berke bhutto biden bimbisara bismarck bligh boccaccio bolivar bonaparte bonifacio borgia bornu botticelli cabral camus caravaggio castro
cato ceausescu chagatai chandragupta charlemagne chekhov chiang chopin churchill cixi clovis cochise columbus copernicus cortes dante danton darwin
deng dengel descartes diderot dingane donatello dostoevsky drake edison einstein engels evita fatimid franco franklin freud galileo gama gandhi
genghis geronimo goethe gogol gragn guevara guyuk haidar harsha harun hegel hiawatha hidalgo hirohito hongwu hulagu humayun idris ikhshid iturbide
jahangir jefferson jinnah jochi josephine juarez kanem kangxi kanishka kant kepler kimpa krishnadeva kublai lafayette lebna lenin leonardo lincoln
liszt lobengula machiavelli magellan mamluk mamun mandela mansa marat marcos martel marx massasoit medici meiji menelik michelangelo moliere mongke
morelos moshoeshoe mozart mussolini mutapa mutasim mvemba mzilikazi napoleon naruhito nehru nelson newton nietzsche nobunaga nogai nuraddin nzinga
obama odoacer ogedei orda osceola osei osman pascal pepin peron petrarch pinochet pizarro pocahontas powhatan proust puccini pulakeshin pushkin putin
puyi qubilai qutuz racine rajaraja rajendra raleigh ranjit raphael rashid rizal robespierre rousseau rumi sacagawea saladin santana sartre schiller
seljuk sequoyah sforza shahjahan shaka shimin shivaji showa sonni squanto stalin sucre suharto sukarno sundiata taisho taizong takasaki tasman
tecumseh temur tewodros theodoric tilak timur tipu titian tito tokhtamysh tolstoy tolui trotsky trump tughril tulun ulugh umayyad verdi vespucci villa
visconti voltaire wagner walid washington wellington wilhelm yacob yatsen yohannes yongle yuanzhang zapata zengi zetian
"""

## Offensive strings no name may contain anywhere.
const OFFENSIVE:="""
anal anus bastard bitch boob chink clit cock coon cracker cunt dago darkie dick dyke fag fuck fuk gook hitler honky incest jizz kaffir kafir kike kunt
molest murder nazi negro niga nigg nigr paki pedo penis piss poop porn rape retard satan semen sex shit slut spaz spic tits tranny turd twat vagin
wank whore wog
"""

## Offensive strings no name (or word of it) may begin with; inside a
## word they are ordinary syllables ("Minjun" stays).
const OFFENSIVE_START:="""
arse butt cum dead fart gypsy homo hump injun jap kill lesb merd naked nude orgy puta puto queer shag
"""

## Short words no name may be, offensive or silly.
const OFFENSIVE_WORDS:="""
abo ass boob bra bum cum dad die dunce gay goy gyp heil homo injun jap nig niga nun pee piss poo pus sex shemale spaz tit tits wee yid
"""

const BREAK:="\n"
static var _words:Dictionary={}
static var _offensive:PackedStringArray=[]
static var _offensive_start:PackedStringArray=[]

## Every whole word a name may not be, lower case.
static func words()->Dictionary:
	if _words.is_empty():
		for text:String in [PLACES,PROVINCES,PEOPLES,FIGURES,FIGURES_MORE,ENGLISH,COMMON_ENGLISH,FOUND_ENGLISH,BRANDS,LOANWORDS,OFFENSIVE_WORDS]:
			for word in text.replace(BREAK," ").split(" ",false):_words[String(word)]=true
	return _words

## The strings no name may contain.
static func offensive()->PackedStringArray:
	if _offensive.is_empty():_offensive=OFFENSIVE.replace(BREAK," ").split(" ",false)
	return _offensive

## The strings no name or word of a name may begin with.
static func offensive_start()->PackedStringArray:
	if _offensive_start.is_empty():_offensive_start=OFFENSIVE_START.replace(BREAK," ").split(" ",false)
	return _offensive_start

## True when a lower-case word (or any word of it) may not be a name.
static func blocks(word:String)->bool:
	var lower:=word.to_lower()
	var whole:=lower.replace(" ","")
	var listed:=words()
	if listed.has(whole):return true
	var parts:=lower.split(" ",false)
	for part in parts:
		if listed.has(String(part)):return true
	for bad in offensive():
		if whole.contains(bad):return true
	for part in parts:
		for bad in offensive_start():
			if String(part).begins_with(bad):return true
	return false
