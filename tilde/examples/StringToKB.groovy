def flag = false
def actions = new TreeSet()
def map = [:].withDefault { [:].withDefault { new LinkedHashSet() } }
new File("511145.protein.actions.v11.0.txt").splitEachLine("\t") { line ->
    if (flag) {
	def p1 = line[0].replaceAll("511145.","").replaceAll("-","")
	def p2 = line[1].replaceAll("511145.","").replaceAll("-","")
	def action = line[2]
	def isActing = line[3]
	def directional = line[4]
	def score = new Integer(line[6])
	if (score >= 700) {
	    map[p1][action].add(p2)
	    //println "$action ( $p1 , $p2 )"
	}
	actions.add(action)
    } else {
	flag = true
    }
}

def count = 1
map.each { p1, m2 ->
    println "protein($p1)."
    m2.each { action, ps ->
	ps.each { p2 ->
	    println "$action($p1,$p2)."
	}
    }
    count += 1
}
