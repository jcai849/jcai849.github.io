# more on sanitation
# reorder file with awk | tsort | awk
# how many cords, bushels, litres reqd?

person: homeostasis hygiene

homeostasis: energy core-temperature
hygiene: bathing toiletry oral-hygiene

energy: nutrition sleep
core-temperature: clothing shelter
bathing: bath-tub bath-water hot-bath-water soap wash-cloth towel
toiletry: toilet toilet-rinse hand-washing
oral-hygiene: drinking-water toothbrush floss salt-rinse

nutrition: drinking-water food
sleep: bed bed-sheet duvet blanket pillow
clothing: garment footwear
shelter: flooring wall roof door heating lighting
bath-water: washing-water bath-plumbing
bath-tub: bath-tub-creation bath-tub-maintenance
soap: rendered-fat lye pot firepit container
toilet-rinse: lota towel
toilet: toilet-creation toilet-maintanance
hand-washing: wash-basin soap towel
drinking-water: drinking-water-source drinking-water-plumbing water-purification cup
toothbrush: container brush wash-basin
floss: string container bin
salt-rinse: wash-basin cup salt

food: main-dish side-dish snack dining-set cake
cake: milk eggs honey flour
lighting: window candle
bath-tub-creation: tub bath-plumbing
bath-tub-maintenance: scrubbing squeegee
toilet-maintenance: scrubbing
blanket: wool-yarn loom
rendered-fat: pot drinking-water firepit container
hammer: hammer-handle wedge  hammer-head
chisel: chisel-head chisel-handle sharpening
lye: lye-barrel hardwood-ash straw gravel container
fabric: fabric-creation fabric-maintenance
toilet-creation: ceramic-glaze toilet-plumbing
scrubbing: cleaning-brush soap washing-water bucket mop
mop: mop-nail rag
garment: fabric-pattern hand-threading leather-strip clothes-iron ironing-board tailors-ham fabric-washing
hand-threading: pin needle thread thimble thread-snip seam-ripper
heating: tiled-stove
flooring: broom
wash-cloth bed-sheet blanket towel: hand-threading fabric
duvet pillow: hand-threading fabric down-feathers

bed table chair: woodworking

woodworking: finished-wood-work
finished-wood-work: waxed-wood-work
waxed-wood-work: finishing-wax rag sealed-wood-work
finishing-wax: beeswax turpentine container double-boiler high-direct-heat
rag: fabric
sealed-wood-work: shellac ethanol container brush joined-wood-work
joined-wood-work: trued-wood wood-work-bench saw chisel mallet holdfast
trued-wood: wood-plane sized-wood
sized-wood: timber saw
timber: hewn-lumber

dining-set: table chair cutlery crockery salt
fabric-pattern: pattern-design tailor-shears pin
pattern-design: fabric french-curve ruler pattern-notcher awl
broom: twigs rope broomstick
candle: beeswax wick wax-pot double-boiler high-direct-heat knife drying-stick
cooperage: wooden-stave gimlet dowel saw iron-hoop rivet bung wood-mallet
barrel tub: cooperage
hammer-handle chisel-handle: wood gouge chisel hammer saw
main-dish: main-base main-essence sauce
main-base: bread pasta crepe waffle cracker
main-essence: cooked-meat  cooked-egg cheese
sauce: roux stock milk cream butter pan stove whisk
roux: butter flour pan stove
stove: masonry-blocks mortar fire sweep pan
firepit: masonry-blocks fire sweep pan
sharpening: grind-wheel sharpening-stones honing-strop 
fabric-washing: cauldron firepit lye-water washing-water wash-tub washing-bat table drying-line
wash-tub: tub
hammer-head iron-hoop chisel-head gimlet cauldron rivet lighting-steel thimble thread-snip seam-ripper: blacksmithing
pin needle: bone
pottery: shaped-clay kiln
shaped-clay: pottery-wheel clay washing-water

high-direct-heat: firepit stove
wick: yarn beeswax
wax-pot double-boiler: pottery
beeswax: beehive
crockery: plate bowl
plate bowl: pottery
cup: glass
cutlery: knife fork spoon
knife: blacksmithing sharpening
spoon: pottery
fork: blacksmithing
blacksmithing: forge anvil quench-trough dipper tong hammer steel-ingot
anvil dipper tong: blacksmithing
ceramic-glaze: pottery
steel-ingot: iron-billet charcoal furnace
iron-billet: furnace charcoal iron-bloom
iron-ore: bog-iron iron-sand

forge: masonry bellows
wooden-stave: coopers-side-axe draw-knife draw-bench jointing-plane
butter: cream churn
cream: pancheon milk skim

churn: plunger churn-lid barrel
salt: seawater-brine briquetage saltern-fire
cooked-meat: grilled-meat baked-meat

grilled-meat: pan stove oil butchered-meat
baked-meat: tray oven oil butchered-meat
bread: proofed-bread oven
proofed-bread: final-dough proving-basket
final-dough: levain bread-dough salt
bread-dough: white-flour whole-wheat-flour drinking-water levain dough-trough
levain: white-flour whole-wheat-flour drinking-water levain-trough
oil: clarified-butter
clarified-butter: pot stove butter ladle container

fire: tinderbox kindling firewood

tinderbox: lighting-steel flint scorched-linen
white-flour: whole-wheat-flour sieve flour-container
whole-wheat-flour: hulled-wheat mill flour-container

hulled-wheat: winnowed-wheat
winnowed-wheat: threshed-wheat
threshed-wheat: harvested-wheat
harvested-wheat: wheat-crop sickle

wheat-crop: soil wheat-seed

soil: topsoil subsoil

topsoil: soil-analysis
subsoil: percolation-test

thread: yarn
fabric: loom yarn
yarn: spindle spinning-wheel wool-batt pure-linen
leader-yarn: yarn
wool-batt: cards wool
wool: sheep

pure-linen: brushed-linen
brushed-linen: crimped-linen linen-brush
crimped-linen: stutched-linen crimper
crimper: woodworking
stutched-linen: linen-stook
linen-stook: dried-linen rushes gathering-tool # linen-stook=bundled-linen
dried-linen: retted-linen
retted-linen: stream harvested-linen
harvested-linen: linen-crop
linen-crop: soil linen-seed

spindle: shaft hook whorl distaff

produce-bed: soil soil-amendment rake
bed-row: produce-bed twine stake
sowed-vegetable: seed hoe bed-row
sowed-wheat: produce-bed rake
contacted-seed: plank roller sowed-vegetable sowed-wheat
flowered-wheat: contacted-seed
tillered-wheat: flowered-wheat roller
ripe-wheat: tillered-wheat
reaped-wheat: sickle scythe cradle ripe-wheat
windrow: reaped-wheat
scythe: snath scythe-blade
sheave: windrow chord # spelled sheaf?
stook: sheave cheesecloth
wheat-soil: sandy-loam
soil-amendment: bonemeal kelp

straw: straw-chaff
threshed-wheat straw-chaff: stook flail straw-chaff threshing-floor
flail: handle leather-thong flail-head
winnowed-wheat grain-chaff: winnowing-fan threshed-wheat
dried-wheat: drying-floor winnowed-wheat grain-turner
wheat-berry: granary dried-wheat
flour: sieve milled-grain

milled-grain: wheat-berry mill

access-road: stone-paving

irrigation-water: stream pond
pond: spillway embankment
drinking-water: well springhouse ceramic-filter potability-test
springhouse: spring structure
stream: above-building-site
shelter: leeward-rise access-road
access-road: horse harness fresno-scraper buck-scraper
laid-out-site: cleared-site corner-stake batter-board tape plumb-bob
excavated-site: shovel bracing-board ladder
foundation: excavated-site footing masonry-block perimeter

felled-log: axe saw tree
tree: woodlot
board: pit saw
seasoned-lumber: lumber drying-shed wax
lumber: felled-log horse sledge saw sawpit
debarked-log: felled-log drawknife spud
shake shingle: billet froe lumber maul mallet
billet: seasoned-lumber
hewn-lumber: lumber utility-axe broadaxe adze
beam: hewn-lumber

window: flashing caulk lintel sash jamb shutter curtain
flooring: subfloor finish-floor joist girder sill foundation
subfloor: tongue-groove-plank insulation
roof: wall shingle gutter rafter
rainwater: cistern rainwater-plumbing
rainwater-plumbing: gutter pipe
insulation: wool
front-Door: vestibule
wall: wooden-wall stone-wall insulation wooden-peg
wooden-wall: framing infill plaster siding
framing: post beam
stone-wall: masonry
masonry: stone shim chisel sledge hammer trowel
mortar: lime clay

livestock: barn fence
fence: wattle
barn: bent braces roof
bent: beam
firewood: stacked-firewood
stacked-firewood: shelter split-firewood
split-firewood: axe bucked-wood
bucked-wood: saw felled-log
bellows: leather wood copper-tube casein nail tack
mill: millstone bedstone hopper rotary-source
rotary-source: water-wheel
water-wheel: pit-wheel spindle spur-wheel pinion undershot-wheel
window: broad-sheet-glass clay
broad-sheet-glass: tube blowpipe shears iron-plate glass
glass: sand flux calcium crucible kiln charcoal
flux: potash
calcium: limestone

iron-bloom: iron-ore bloomery charcoal
smelted-iron: bloomery iron-ore charcoal
lye: ash-hopper ash lye-container # http://journeytoforever.org/biodiesel_ashlye.html

drainage: u-bend pipe waste-vent
