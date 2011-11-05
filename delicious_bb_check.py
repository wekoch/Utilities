import urllib2
from xml.dom import minidom, Node
import base64

username = 'YOURUSERNAME'
passwd = 'YOURPASSWORD'
ur = urllib2.Request("https://api.del.icio.us/v1/posts/all")
b64s = base64.encodestring('%s:%s' % (username, passwd)).replace('\n', '')
ur.add_header("Authorization", "Basic %s" % b64s)
r = urllib2.urlopen(ur)

mydom = minidom.parseString(r.read())
pn = mydom.childNodes.item(0)

list_dict = {}
bad_list = {}
for mynode in pn.childNodes:
	list_dict[mynode.getAttribute('description')] = mynode.getAttribute('href')

i = 0
for name, the_url in list_dict.iteritems():
	if i > 3:
		break
	try:
		print "Trying: " + the_url
		urllib2.urlopen(the_url)
	except urllib2.URLError as ue:
		bad_list[the_url] = str(ue) 
		i = i + 1

print bad_list
