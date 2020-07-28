const HDWalletProvider = require("@truffle/hdwallet-provider");
// just for test
const mnemonic = "obscure minute claw dial quit fatigue random false certain essay scheme maid";


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
                return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/v3/515f610165e2471a8373a0b6678e5ab9")
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