# All to have reading references and directions
# git clone git@github.com:lindenb/makefile2graph
# gmake -Bnd -k -f /home/jason/Downloads/jcai849.github.io/docs/life-prereq.mk 2>/dev/null | ./make2graph | dot -Tsvg -o ~/Downloads/test.svg
# TODO: more on blacksmithing, textile manufacture, plumbing, pottery, animal butchery & husbandry, building construction

health: homeostasis hygiene

homeostasis: energy core-temperature
hygiene: bathing toiletry oral-hygiene

energy: nutrition sleep
core-temperature: clothing shelter
bathing: bath-water bath-tub soap wash-cloth shelter hot-bath-water
toiletry: toilet-rinse toilet-wipe toilet shelter hand-washing
oral-hygiene: drinking-water toothbrush floss salt-rinse

nutrition: drinking-water food
sleep: shelter blanket bed bed-sheets pillow
clothing: garments footwear
shelter: flooring walls door roof heating lighting
bath-water: rain-water-capture-system bath-plumbing
bath-tub: bath-tub-creation bath-tub-maintenance
soap: rendered-fat lye pot firepit container
wash-cloth: fabric scissors needle thread
hot-bath-water: back-boiler back-boiler-plumbing 
toilet-rinse: lota
toilet-wipe: fabric
toilet: toilet-creation toilet-maintanance
hand-washing: basin soap
drinking-water: drinking-water-source drinking-cups drinking-water-plumbing water-purification
toothbrush: brush
floss: fibre container bin
salt-rinse: cup drinking-water salt

food: base-and-essence-main side-dishes snacks
lighting: window candle
bath-tub-creation: barrel bath-plumbing
bath-tub-maintenance: toilet-maintenance squeegee
blanket: wool-yarn loom
high-direct-heat: stove firepit
high-indirect-heat: oven
rendered-fat: pot water firepit container
hammer: hammer-handle wedge  hammer-head
woodworking-chisel: woodworking-chisel-head woodworking-chisel-handle sharpening
lye: lye-barrel hardwood-ash straw gravel container
fabric: fabric-creation fabric-maintenance
toilet-creation: ceramic-glaze toilet-plumbing
toilet-maintenance: cleaning-brush soap water bucket mop-cloth

candle: beeswax wick wax-pot double-boiler high-direct-heat knife drying-stick
barrel: wooden-staves gimlets dowel saw iron-hoop rivet bung mallet
hammer-handle woodworking-chisel-handle: wood gouge chisel hammer saw
base-and-essence-main: bread-and-cooked-meat bread-and-cooked-egg pasta-meat-sauce crackers-and-cheese 
stove: masonry-blocks mortar fire sweep pan
firepit: masonry-blocks fire sweep pan
sharpening: grind-wheel sharpening-stones honing-strop 

wooden-staves: coopers-side-axe draw-knife draw-bench jointing-plane

cooked-meat-and-bread: cooked-meat bread salt

salt: seawater-brine briquetage saltern-fire
cooked-meat: grilled-meat baked-meat

grilled-meat: pan stove oil raw-meat
baked-meat: tray oven oil raw-meat
bread: flour water salt yeast oven proving-basket bread-mixing-bowl dutch oven
	@forkish2012fwsy

fire: tinderbox kindling firewood

flour: wheat mill flour-container
yeast: flour water levain-container

roof: timber shingles walls

walls: timber infill foundations

