import sys
p=sys.argv[1]+'/ios/CardWalletWatch/ContentView.swift'
s=open(p).read()
if 'shot.openFirst' not in s:
    s=s.replace("""    @EnvironmentObject private var store: LoyaltyCardStore

    var body: some View {
        NavigationStack {""","""    @EnvironmentObject private var store: LoyaltyCardStore
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {""")
    s=s.replace("""                    Text("Card unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }""","""                    Text("Card unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            // store shots
            if UserDefaults.standard.bool(forKey: "shot.openFirst"), let first = store.cards.first {
                path = [first.id]
            }
        }""")
    open(p,'w').write(s); print('watch patched', s.count('shot.openFirst'))
