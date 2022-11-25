require 'bitcoin'
require_relative 'lib/bitcoin_wallet'
require 'blockcypher'
require_relative 'config/config'

abort 'too many arguments' if ARGV.count > 1

BitcoinWallet.save_key(ARGV[0]) unless File.exist?('data/private_key.txt')

bitcoin_wallet = BitcoinWallet.from_file

puts "your adress #{bitcoin_wallet.key.addr}"

input = nil
while input != 'exit'
  print 'enter exit/balance/transaction : '
  input = gets.chomp

  puts "balance: #{bitcoin_wallet.balance}" if input == 'balance'
  puts
end

# pp key = Bitcoin::Key.generate
# pp key.priv
# pp key.pub
# pp key.addr
# pp key.to_base58
# # 5aa04682734c4911bed12a3f79407a2f
# block_cypher = BlockCypher::Api.new(api_token: '5aa04682734c4911bed12a3f79407a2f', currency: BlockCypher::BTC,
#                                     network: BlockCypher::TEST_NET_3)
# pp block_cypher.address_final_balance(key.addr)
