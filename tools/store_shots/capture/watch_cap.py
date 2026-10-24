import json, subprocess, sys, time
W=open('/tmp/watch_id').read().strip()
BID='com.volkan.walletapp.watchkitapp'
M={'us':('Starbucks','#006241','#003D28'),'de':('REWE','#CC071E','#8C0414'),'tr':('Migros','#FF6600','#C24A00'),
   'fr':('Carrefour','#004E9F','#003066'),'es':('El Corte Inglés','#00873D','#005426'),'it':('Esselunga','#1E6CB5','#114273'),
   'nl':('Albert Heijn','#00ADE6','#00739A'),'pl':('Żabka','#00A651','#006B34'),'br':('Pão de Açúcar','#00843D','#005226')}
for code,(name,c1,c2) in M.items():
    cards=[{"id":"c0","name":name,"brand":name,"barcode":"4006381333931","format":"EAN_13","color1":c1,"color2":c2,"fg":"#FFFFFF","useCount":18,"lastUsedAt":None}]
    hexdata=json.dumps(cards,ensure_ascii=False).encode().hex()
    subprocess.run(['xcrun','simctl','terminate',W,BID],capture_output=True)
    subprocess.run(['xcrun','simctl','spawn',W,'defaults','write',BID,'watch.loyalty.cards.v1','-data',hexdata],check=True)
    subprocess.run(['xcrun','simctl','spawn',W,'defaults','write',BID,'shot.openFirst','-bool','YES'],check=True)
    subprocess.run(['xcrun','simctl','launch',W,BID],capture_output=True)
    time.sleep(6)
    subprocess.run(['xcrun','simctl','io',W,'screenshot','--type=png',f'/tmp/mk9/watch/{code}.png'],capture_output=True)
    print('watch',code)
