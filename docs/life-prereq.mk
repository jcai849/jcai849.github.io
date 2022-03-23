# All to have reading references and directions
# git clone git@github.com:lindenb/makefile2graph
# gmake -Bnd -k -f /home/jason/Downloads/jcai849.github.io/docs/life-prereq.mk 2>/dev/null | ./make2graph | dot -Tsvg -o ~/Downloads/test.svg
# TODO: more on blacksmithing, textile manufacture, plumbing, pottery, animal butchery & husbandry, building construction

health: homeostasis hygiene

homeostasis: energy core-temperature
hygiene: bathing toiletry oral-hygiene

energy: nutrition sleep
core-temperature: clothing shelter
bathing: bath-tub bath-water hot-bath-water soap wash-cloth
toiletry: toilet toilet-rinse hand-washing
oral-hygiene: drinking-water toothbrush floss salt-rinse

nutrition: drinking-water food
sleep: bed bed-sheet duvet blanket pillow
clothing: garment footwear
shelter: flooring walls roof door heating lighting
bath-water: washing-water bath-plumbing
bath-tub: bath-tub-creation bath-tub-maintenance
soap: rendered-fat lye pot firepit container
wash-cloth: fabric scissors needle thread
hot-bath-water: boiler boiler-plumbing 
toilet-rinse: lota towel
toilet: toilet-creation toilet-maintanance
hand-washing: wash-basin soap towel
drinking-water: drinking-water-source drinking-water-plumbing water-purification cup
toothbrush: container brush wash-basin
floss: string container bin
salt-rinse: wash-basin cup salt

food: main-dish side-dish snack
lighting: window candle
bath-tub-creation: tub bath-plumbing
bath-tub-maintenance: toilet-maintenance squeegee
blanket: wool-yarn loom
rendered-fat: pot water firepit container
hammer: hammer-handle wedge  hammer-head
woodworking-chisel: woodworking-chisel-head woodworking-chisel-handle sharpening
lye: lye-barrel hardwood-ash straw gravel container
fabric: fabric-creation fabric-maintenance
toilet-creation: ceramic-glaze toilet-plumbing
toilet-maintenance: cleaning-brush soap water bucket mop-cloth
garment: fabric needle thread mangle-board rolling-pin fabric-washing
heating: tiled-stove
flooring: broom

broom: twigs rope broomstick
candle: beeswax wick wax-pot double-boiler high-direct-heat knife drying-stick
tub: wooden-stave gimlets dowel saw iron-hoop rivet bung mallet
hammer-handle woodworking-chisel-handle: wood gouge chisel hammer saw
main-dish: main-base main-essence sauce
main-base: bread pasta crepe waffle cracker
main-essence: cooked-meat  cooked-egg cheese
sauce: roux stock milk cream butter
stove: masonry-blocks mortar fire sweep pan
firepit: masonry-blocks fire sweep pan
sharpening: grind-wheel sharpening-stones honing-strop 
fabric-washing: cauldron firepit lye-water washing-water wash-tub washing-bat table drying-line

wooden-stave: coopers-side-axe draw-knife draw-bench jointing-plane
butter: cream churn
cream: pancheon milk skim

churn: plunger churn-lid barrel
salt: seawater-brine briquetage saltern-fire
cooked-meat: grilled-meat baked-meat

grilled-meat: pan stove oil butchered-meat
baked-meat: tray oven oil butchered-meat
bread: flour water salt yeast oven proving-basket dough-trough dutch oven

fire: tinderbox kindling firewood

tinderbox: steel flint scorched-linen
flour: wheat mill flour-container
yeast: flour water levain-container

roof: timber shingles walls

walls: timber infill foundations


thread: yarn
fabric: loom yarn
yarn: spindle  wool-batt
leader-yarn: yarn
wool-batt: cards wool
wool: sheep

spindle: shaft hook whorl distaff
