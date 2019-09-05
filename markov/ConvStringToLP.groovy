def flag = false
def actions = new TreeSet()
new File("511145.protein.actions.v11.0.txt").splitEachLine("\t") { line ->
    if (flag) {
	def p1 = line[0].replaceAll("511145.","").replaceAll("-","").capitalize()
	def p2 = line[1].replaceAll("511145.","").replaceAll("-","").capitalize()
	def action = line[2].capitalize()
	def isActing = line[3]
	def directional = line[4]
	def score = new Integer(line[6])
	if (score >= 700) {
	    println "$action ( $p1 , $p2 )"
	}
	actions.add(action)
    } else {
	flag = true
    }
}

//println actions
