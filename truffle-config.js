const HDWalletProvider = require("@truffle/hdwallet-provider");
// just for test
const mnemonic = "noise wage special canoe timber vendor twist kiss ready live cinnamon mix";


module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    networks: {
        development: {
            host: "127.0.0.1", // Localhost (default: none)
            port: 8545, // Standard Ethereum port (default: none)
            network_id: "*", // Any network (default: none)
            websockets: true
        },
        ropsten: {
            provider: function() {
                return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/30f0e94003154748b0741f67557b3914")
              },
              network_id: 3
        }
    },
    compilers: {
        solc: {
           version: "0.5.7", 
           settings: {
               optimizer: {
                   enabled: true,
                   runs: 200
               }
           }
        }
    }
};