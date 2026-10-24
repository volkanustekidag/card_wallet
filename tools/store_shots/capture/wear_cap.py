import json, subprocess, time
W=['/tmp/w']
PKG='com.volkan.wallet_app'
M={'us':[('Starbucks','#006241','#003D28'),('Target','#CC0000','#8A0000'),('Ulta Beauty','#F26822','#B84A12'),('Best Buy','#0046BE','#002C7A')],
 'de':[('REWE','#CC071E','#8C0414'),('dm','#002878','#00174A'),('Payback','#003EAA','#002670'),('Douglas','#2A2A2A','#0B0B0B')],
 'tr':[('Migros','#FF6600','#C24A00'),('Kahve Dünyası','#5A2D0C','#341A06'),('D&R','#E30613','#9E040D'),('LC Waikiki','#0047BA','#002C78')],
 'fr':[('Carrefour','#004E9F','#003066'),('Intermarché','#E2001A','#9C0012'),('Fnac','#E1A925','#A87A10'),('Sephora','#2A2A2A','#0B0B0B')],
 'es':[('El Corte Inglés','#00873D','#005426'),('Carrefour','#004E9F','#003066'),('Dia','#E30613','#9E040D'),('Repsol','#FF8200','#C25E00')],
 'it':[('Esselunga','#1E6CB5','#114273'),('Conad','#E30613','#9E040D'),('Eni','#FFD100','#C9A200'),('Leroy Merlin','#78BE20','#4E8212')],
 'nl':[('Albert Heijn','#00ADE6','#00739A'),('Jumbo','#FFD200','#C9A300'),('HEMA','#E2001A','#9C0012'),('IKEA','#0058A3','#003866')],
 'pl':[('Żabka','#00A651','#006B34'),('Biedronka','#E30613','#9E040D'),('Lidl','#0050AA','#00326B'),('Douglas','#2A2A2A','#0B0B0B')],
 'br':[('Pão de Açúcar','#00843D','#005226'),('Livelo','#E5007E','#9E0057'),('Drogasil','#E30613','#9E040D'),('Smiles','#FF6600','#C24A00')]}
def sh(*a, inp=None): return subprocess.run(W+list(a), input=inp, capture_output=True)
for code,cards in M.items():
    payload={"version":1,"cards":[{"id":f"c{i}","name":n,"brand":n,"barcode":"4006381333931","format":"EAN_13","color1":c1,"color2":c2,"fg":"#FFFFFF"} for i,(n,c1,c2) in enumerate(cards)]}
    js=json.dumps(payload,ensure_ascii=False)
    esc=js.replace('&','&amp;').replace('"','&quot;').replace('<','&lt;')
    xml=f"<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n    <string name=\"payload\">{esc}</string>\n</map>\n"
    open('/tmp/mk9/cards.xml','w').write(xml)
    sh('shell','am','force-stop',PKG)
    sh('push','/tmp/mk9/cards.xml','/data/local/tmp/cards.xml')
    sh('shell',f"run-as {PKG} sh -c 'mkdir -p shared_prefs && cp /data/local/tmp/cards.xml shared_prefs/cards.xml'")
    sh('shell','am','start','-n','com.volkan.wallet_app/.wear.WearActivity')
    time.sleep(9)
    with open(f'/tmp/mk9/wear/{code}_list.png','wb') as f: f.write(sh('exec-out','screencap','-p').stdout)
    sh('shell','input','tap','227','200'); time.sleep(4)
    with open(f'/tmp/mk9/wear/{code}_card.png','wb') as f: f.write(sh('exec-out','screencap','-p').stdout)
    print('wear',code)
