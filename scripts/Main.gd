extends Control

const GDN_RES = preload("res://GDNScraper.gdns")
onready var GDNScraper = GDN_RES.new()

var house_names = [
	"Crude Huts",
	"Sturdy Huts",
	"Meager Shanties",
	"Common Shanties",
	"Rough Cottages",
	"Ordinary Cottages",
	"Modest Homesteads",
	"Spacious Homesteads",
	"Modest Apartments",
	"Spacious Apartments",
	"Common Residences",
	"Spacious Residences",
	"Elegant Residences",
	"Fancy Residences",
	"Common Manors",
	"Spacious Manors",
	"Elegant Manors",
	"Stately Manors",
	"Modest Estates",
	"Palatial Estates"
]
func houselevel(level):
	return house_names[level]
func units_to_loads(r, c):
	match r:
		10,24,25,26,28,30,35:
			return c / 100
		_:
			return c
func loads_to_units(r, c):
	match r:
		10,24,25,26,28,30,35:
			return c
		_:
			return c * 100
func get_salary(rank):
	match rank:
		0: return 0
		1: return 2
		2: return 5
		3: return 8
		4: return 12
		5: return 20
		6: return 30
		7: return 40
		8: return 60
		9: return 80
		10: return 100
func percentage(value, total):
	if total == 0 || value == 0:
		return 0
	return int(float(value) / float(total) * 100.0)

# Called when the node enters the scene tree for the first time.
var processID = -1
func _ready():
	processID = GDNScraper.open("Pharaoh.exe")

func cleanup():
	processID = -1
	$Panel.hide()
	$Waiting.show()

var our_city_id = -1
var city_produce_address = -1
func update_city_id():
	var trading_base = 0x37F748
	if our_city_id != -1:
		# check that the address points to OUR city!
		var type = GDNScraper.scrape(trading_base + our_city_id * 0x62, 1)
		var in_use = GDNScraper.scrape(trading_base + our_city_id * 0x62 + 0x1, 1)
		var city_type = GDNScraper.scrape(trading_base + our_city_id * 0x62 + 0x18, 1)
		if type != 1 || in_use != 2 || city_type != 0:
			our_city_id = -1 # oh no!
			city_produce_address = -1
	if our_city_id == -1:
		for c in range(0,61):
			var type = GDNScraper.scrape(trading_base + c * 0x62, 1)
			var in_use = GDNScraper.scrape(trading_base + c * 0x62 + 0x1, 1)
			var city_type = GDNScraper.scrape(trading_base + c * 0x62 + 0x18, 1)
			if type == 1 && in_use == 2 && city_type == 0:
				our_city_id = c # found our city!
				break
	if our_city_id == -1:
		return false
	city_produce_address = trading_base + our_city_id * 0x62 + 0x1e
	return true

# Called every frame. 'delta' is the elapsed time since the previous frame.
var t = 0
func waitfor(step, delta):
	if step == 0:
		return true
	t += delta
	if t > step:
		t -= step
		return true
	return false
func _process(delta):
	# check if process is alive & hook to it
	if processID == -1:
		if waitfor(1.0, delta):
			print("Checking if Pharaoh is open...")
			processID = GDNScraper.open("Pharaoh.exe")
			if processID != -1:
				print("Hooked: PID ",processID)
	if processID == -1:
		return cleanup()
		
	# update timer step
	if !waitfor(0.0, delta):
		return
	
	# test that the process handle is still valid!
	var test = GDNScraper.scrape(0x0000000, 4)
	if GDNScraper.getLastError() != 0:
		return cleanup()
	
	# and now the fun begins!
	$Panel.show()
	$Waiting.hide()
	var savings = GDNScraper.scrape(0xAAA698, 4)
	var salary = get_salary(GDNScraper.scrape(0x384B62, 2))
	$Panel/Required.text = "%d\n%d\n%d\n%d" % [
		GDNScraper.scrape(0x384C24, 4) if GDNScraper.scrape(0x384C3C, 1) == 1 else 0,
		GDNScraper.scrape(0x384C28, 4) if GDNScraper.scrape(0x384C3D, 1) == 1 else 0,
		GDNScraper.scrape(0x384C2C, 4) if GDNScraper.scrape(0x384C3E, 1) == 1 else 0,
		GDNScraper.scrape(0x384C30, 4) if GDNScraper.scrape(0x384C3F, 1) == 1 else 0
	]
	$Panel/Current.text = "%d                        %d (+%d)\n%d\n%d\n%d" % [
		GDNScraper.scrape(0xAAA514, 4), savings, salary,
		GDNScraper.scrape(0xAAA518, 4),
		GDNScraper.scrape(0xAAA51C, 4),
		GDNScraper.scrape(0xAAA520, 4)
	]
	if GDNScraper.scrape(0x384C40, 1) == 1 && GDNScraper.scrape(0x384C34, 4) > 0:
		$Panel/Required.text += "\n%d %s" % [GDNScraper.scrape(0x384C34, 4), houselevel(GDNScraper.scrape(0x384C38, 4))]
	if GDNScraper.scrape(0x384C58, 4) == 1:
		$Panel/Required.text += "\n%d %s" % [GDNScraper.scrape(0x384C5C, 4), " population"]
	
	# employments
	var population = GDNScraper.scrape(0xAA626C, 4)
	var workers_total = GDNScraper.scrape(0xAA8D70, 4)
	var workers_percentage = percentage(workers_total, population)
	var workers_employed = GDNScraper.scrape(0xAA8E3C, 4)
	var workers_lacking = GDNScraper.scrape(0xAA8E4C, 4)
	var workers_unemployed = GDNScraper.scrape(0xAA8E40, 4)
	var unemployment_percentage = percentage(workers_unemployed, workers_total)
	$Panel/Employees.text = "%d of %d people (%d%%)\n%d / %d\n%d (%d%%)" % [
		workers_total, population, workers_percentage,
		workers_lacking, workers_employed,
		workers_unemployed, unemployment_percentage
	]
	$Panel/Speed.text = str(GDNScraper.scrape(0xA38E6C, 1))
		
	# religion
	$Panel/Moods.text = ""
	$Panel/Shrines.text = ""
	$Panel/Temples.text = ""
	$Panel/TemplesComplex.text = ""
	$Panel/Festival.text = ""
	var patron = -1
	for g in range(0,5):
		var status = GDNScraper.scrape(0x3848E2 + 0x2 * g, 2)
		var bolts_and_ankhs_sprites = $Panel/Moods.get_child(g)
		if status == 0:
			$Panel/Moods.text += "-\n"
			bolts_and_ankhs_sprites.set_value(0)
			$Panel/Shrines.text += "\n"
			$Panel/Temples.text += "\n"
			$Panel/TemplesComplex.text += "\n"
			$Panel/Festival.text += "\n"
		else:
			if status == 2:
				patron = g
			var mood = GDNScraper.scrape(0xAAA5E2 + 0x1 * g, 1)
			var target = GDNScraper.scrape(0xAAA5D8 + 0x1 * g, 1)
			var bolts = GDNScraper.scrape(0xAAA5EC + 0x1 * g, 1)
			var ankhs = GDNScraper.scrape(0xAAAA5E + 0x1 * g, 1)
			bolts_and_ankhs_sprites.set_value(ankhs - bolts)
			$Panel/Moods.text += "%d\n" % [mood]
			var shrines = GDNScraper.scrape(0x305D20 + 0x4 * g, 4)
			var temples = GDNScraper.scrape(0x305BE0 + 0x4 * g, 4)
			var templecomplex = GDNScraper.scrape(0x305BF4 + 0x4 * g, 4)
			var festival = GDNScraper.scrape(0xAAA628 + 0x4 * g, 4)
			$Panel/Shrines.text += "%d\n" % [shrines]
			$Panel/Temples.text += "%d\n" % [temples]
			$Panel/TemplesComplex.text += "%d\n" % [templecomplex]
			$Panel/Festival.text += "%d months ago\n" % [festival]
	if patron != -1:
		$Panel/Moods/Patron.position.y = 4 + 18 * patron
		$Panel/Moods/Patron.show()
	else:
		$Panel/Moods/Patron.hide()

	# update city trading id
	if !update_city_id():
		$Panel/Produce.hide()
	else:
		$Panel/Produce.show()
	$Panel/Label8/CityID.text = str(our_city_id," : ",city_produce_address)

	# resources
	for r in range(0,36):
		# city storage
		var res_list_item = $Panel/Storage.get_child(r)
		if GDNScraper.scrape(0xAA8BDD + 0x1*r, 1) == 1:
			res_list_item.show()
			res_list_item.set_count(units_to_loads(r, GDNScraper.scrape(0xAAAB38 + 0x4*r, 4)))
		else:
			res_list_item.hide()
		
		# burial provisions
		var prov_list_item = $Panel/Provisions.get_child(r)
		var required = GDNScraper.scrape(0x384DE8 + 0x4*r, 4)
		var dispatched = GDNScraper.scrape(0x384E78 + 0x4*r, 4)
		if required > 0 && dispatched < required:
			prov_list_item.show()
			prov_list_item.set_count(str("x",loads_to_units(r, required-dispatched)))
		else:
			prov_list_item.hide()
	
		# city produce
		$Panel/Produce.get_child(r).hide()
		
	# city produce
	for r in range(0,14):
		var res_id = GDNScraper.scrape(city_produce_address + r * 0x1, 1)
		if res_id > 0 && res_id < 36:
			var prod_list_item = $Panel/Produce.get_child(res_id)
			prod_list_item.show()
	if GDNScraper.scrape(0x384CE4, 1) == 1:
		$Panel/Produce.get_child(21).show()
