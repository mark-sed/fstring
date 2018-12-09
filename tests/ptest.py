#!/usr/bin/env python3

t1 = "HelloTherethisisthetext123456";
t2 = "Thiswasinsertedatthestartoftheappendedtext";
t3 = "FINDME";

pstr = t1;

pstr = pstr.lower()

for i in range(4000):
	pstr += t1

pstr = pstr.upper()

pstr = pstr[:1] + t2 + pstr[1:]

pstr += t3

index = pstr.find(t3)

print("\nFound at: {} (should be {})".format(index, len(pstr)-len(t3)))